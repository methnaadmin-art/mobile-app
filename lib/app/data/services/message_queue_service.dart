import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:methna_app/app/data/services/socket_service.dart';

/// Message status for the offline queue
enum QueuedMessageStatus { sending, sent, failed }

/// A queued message waiting to be sent
class QueuedMessage {
  final String id;
  final String conversationId;
  final String content;
  final DateTime createdAt;
  QueuedMessageStatus status;
  int retryCount;

  QueuedMessage({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.createdAt,
    this.status = QueuedMessageStatus.sending,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'status': status.index,
        'retryCount': retryCount,
      };

  factory QueuedMessage.fromJson(Map<String, dynamic> json) => QueuedMessage(
        id: json['id'] ?? '',
        conversationId: json['conversationId'] ?? '',
        content: json['content'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        status: QueuedMessageStatus.values[json['status'] ?? 0],
        retryCount: json['retryCount'] ?? 0,
      );
}

/// Offline message queue service.
/// Stores messages locally when socket is disconnected,
/// and automatically retries sending when connection is restored.
class MessageQueueService extends GetxService {
  static const String _storageKey = 'offline_message_queue';
  static const int _maxRetries = 5;
  static const Duration _ackTimeout = Duration(seconds: 8);

  final GetStorage _box = GetStorage();
  final RxList<QueuedMessage> queue = <QueuedMessage>[].obs;
  final RxBool isFlushing = false.obs;
  final Map<String, Timer> _ackTimers = {};
  bool _initialized = false;

  Future<MessageQueueService> init() async {
    if (_initialized) return this;
    _initialized = true;
    _loadQueue();
    _listenForServerAcks();
    // Listen for socket connection changes to auto-flush
    ever(Get.find<SocketService>().isConnected, (bool connected) {
      if (connected && queue.isNotEmpty) {
        flushQueue();
      }
    });
    return this;
  }

  /// Load persisted queue from disk
  void _loadQueue() {
    try {
      final raw = _box.read<String>(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List;
      queue.value = list
          .map((e) => QueuedMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      debugPrint('[MsgQueue] Loaded ${queue.length} queued messages from disk');
    } catch (e) {
      debugPrint('[MsgQueue] Failed to load queue: $e');
    }
  }

  /// Persist queue to disk
  void _saveQueue() {
    try {
      final data = jsonEncode(queue.map((m) => m.toJson()).toList());
      _box.write(_storageKey, data);
    } catch (e) {
      debugPrint('[MsgQueue] Failed to save queue: $e');
    }
  }

  /// Enqueue a message for sending.
  /// Returns the queued message ID for tracking.
  String enqueue(String conversationId, String content, {String? clientMsgId}) {
    if (clientMsgId != null) {
      final existing = queue.firstWhereOrNull((m) => m.id == clientMsgId);
      if (existing != null) {
        existing.status = QueuedMessageStatus.sending;
        queue.refresh();
        _saveQueue();

        final socket = Get.find<SocketService>();
        if (socket.isConnected.value) {
          unawaited(_trySend(existing));
        }
        return existing.id;
      }
    }

    final id = clientMsgId ?? 'q_${DateTime.now().millisecondsSinceEpoch}_${queue.length}';
    final msg = QueuedMessage(
      id: id,
      conversationId: conversationId,
      content: content,
      createdAt: DateTime.now(),
    );
    queue.add(msg);
    _saveQueue();
    debugPrint('[MsgQueue] Enqueued message $id for conversation $conversationId');

    // Try to send immediately if connected
    final socket = Get.find<SocketService>();
    if (socket.isConnected.value) {
      _trySend(msg);
    }
    return id;
  }

  /// Get the status of a queued message
  QueuedMessageStatus? getStatus(String messageId) {
    final msg = queue.firstWhereOrNull((m) => m.id == messageId);
    return msg?.status;
  }

  /// Check if a message is a duplicate (already in queue)
  bool isDuplicate(String conversationId, String content) {
    return queue.any((m) =>
        m.conversationId == conversationId &&
        m.content == content &&
        m.status != QueuedMessageStatus.sent &&
        DateTime.now().difference(m.createdAt).inSeconds < 5);
  }

  /// Mark a message as sent and remove from queue
  void markSent(String messageId) {
    _cancelAckTimer(messageId);
    queue.removeWhere((m) => m.id == messageId);
    _saveQueue();
    debugPrint('[MsgQueue] Message $messageId marked as sent, removed from queue');
  }

  /// Mark a message as failed
  void markFailed(String messageId) {
    _cancelAckTimer(messageId);
    final msg = queue.firstWhereOrNull((m) => m.id == messageId);
    if (msg != null) {
      msg.status = QueuedMessageStatus.failed;
      msg.retryCount++;
      queue.refresh();
      _saveQueue();
      debugPrint('[MsgQueue] Message $messageId marked as failed (retry ${msg.retryCount})');
    }
  }

  /// Retry a specific failed message
  void retry(String messageId) {
    final msg = queue.firstWhereOrNull((m) => m.id == messageId);
    if (msg != null && msg.status == QueuedMessageStatus.failed) {
      msg.status = QueuedMessageStatus.sending;
      queue.refresh();
      _saveQueue();
      _trySend(msg);
    }
  }

  /// Flush the entire queue — retry all pending/failed messages
  Future<void> flushQueue() async {
    if (isFlushing.value) return;
    isFlushing.value = true;
    debugPrint('[MsgQueue] Flushing queue (${queue.length} messages)...');

    final pending = queue
        .where((m) =>
            m.status != QueuedMessageStatus.sent &&
            m.retryCount < _maxRetries)
        .toList();

    for (final msg in pending) {
      await _trySend(msg);
      // Small delay between sends to avoid hammering the server
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Remove messages that exceeded max retries
    queue.removeWhere((m) => m.retryCount >= _maxRetries);
    _saveQueue();
    isFlushing.value = false;
    debugPrint('[MsgQueue] Queue flush complete. Remaining: ${queue.length}');
  }

  /// Try to send a single message via socket
  Future<void> _trySend(QueuedMessage msg) async {
    final socket = Get.find<SocketService>();
    if (!socket.isConnected.value) {
      msg.status = QueuedMessageStatus.failed;
      queue.refresh();
      _saveQueue();
      return;
    }

    try {
      msg.status = QueuedMessageStatus.sending;
      queue.refresh();

      socket.sendMessageWithId(msg.conversationId, msg.content, msg.id);
      _scheduleAckTimeout(msg);
    } catch (e) {
      debugPrint('[MsgQueue] Send failed for ${msg.id}: $e');
      markFailed(msg.id);
    }
  }

  /// Get count of pending messages
  int get pendingCount =>
      queue.where((m) => m.status != QueuedMessageStatus.sent).length;

  /// Get count of failed messages
  int get failedCount =>
      queue.where((m) => m.status == QueuedMessageStatus.failed).length;

  /// Clear entire queue
  void clearQueue() {
    for (final timer in _ackTimers.values) {
      timer.cancel();
    }
    _ackTimers.clear();
    queue.clear();
    _saveQueue();
    debugPrint('[MsgQueue] Queue cleared');
  }

  void _listenForServerAcks() {
    try {
      final socket = Get.find<SocketService>();
      socket.onNewMessage((data) {
        if (data == null || data is! Map) return;
        final clientMsgId = data['clientMsgId'] as String?;
        if (clientMsgId != null) {
          markSent(clientMsgId);
        }
      });
    } catch (e) {
      debugPrint('[MsgQueue] Failed to attach ack listener: $e');
    }
  }

  void _scheduleAckTimeout(QueuedMessage msg) {
    _cancelAckTimer(msg.id);
    _ackTimers[msg.id] = Timer(_ackTimeout, () {
      final pending = queue.firstWhereOrNull((m) => m.id == msg.id);
      if (pending != null && pending.status == QueuedMessageStatus.sending) {
        debugPrint('[MsgQueue] Ack timeout for ${msg.id} - marking failed');
        markFailed(msg.id);
      }
    });
  }

  void _cancelAckTimer(String messageId) {
    _ackTimers.remove(messageId)?.cancel();
  }
}
