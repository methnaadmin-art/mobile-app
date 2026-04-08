import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/data/services/notification_service.dart';
import 'package:methna_app/app/data/services/message_queue_service.dart';
import 'package:methna_app/app/data/models/notification_model.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SocketService extends GetxService with WidgetsBindingObserver {
  io.Socket? _chatSocket;
  io.Socket? _notifSocket;
  final StorageService _storage = Get.find<StorageService>();
  final RxBool isConnected = false.obs;
  final RxBool isReconnecting = false.obs;
  bool _initialized = false;
  bool _isConnecting = false;
  bool _isNotifConnecting = false;
  bool _allowAutoReconnect = true;
  bool _isDisposingSocket = false;

  // Exponential backoff state
  Timer? _reconnectTimer;
  Timer? _resumeReconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const int _baseDelayMs = 1000;
  static const int _maxDelayMs = 32000;

  io.OptionBuilder _socketOptions(String token) {
    return io.OptionBuilder()
        .setPath('/socket.io')
        .setTransports(['websocket', 'polling'])
        .setAuth({'token': token})
        .setTimeout(20000)
        .disableAutoConnect()
        .disableReconnection()
        .enableForceNew();
  }

  Future<SocketService> init() async {
    if (_initialized) return this;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    return this;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    _resumeReconnectTimer?.cancel();
    disconnect();
    super.onClose();
  }

  // ─── App Lifecycle ─────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (isConnected.value || _isConnecting) return;
      _resumeReconnectTimer?.cancel();
      debugPrint('[Socket] App resumed - scheduling reconnect');
      _resumeReconnectTimer = Timer(const Duration(milliseconds: 350), () {
        if (isConnected.value || _isConnecting) return;
        debugPrint('[Socket] App resumed - attempting reconnect');
        _attemptReconnect();
      });
    } else if (state == AppLifecycleState.paused) {
      _resumeReconnectTimer?.cancel();
    }
  }

  Future<void> connect() async {
    if (_isConnecting || isConnected.value) return;

    final token = await _storage.getToken();
    if (token == null || token.isEmpty) return;

    // Always reconnect with a fresh socket/auth payload to avoid stale-token loops.
    _allowAutoReconnect = true;
    _reconnectTimer?.cancel();
    isReconnecting.value = false;
    _disposeChatSocket();

    _isConnecting = true;

    // ─── Chat Socket (default namespace) ─────────────────
    _chatSocket = io.io(
      ApiConstants.socketUrl,
      _socketOptions(token).build(),
    );

    _chatSocket!.onConnect((_) {
      _isConnecting = false;
      isConnected.value = true;
      isReconnecting.value = false;
      _reconnectAttempts = 0;
      debugPrint('[Socket] Connected successfully');
      _connectNotificationSocket(token);
      _flushMessageQueue();
    });

    _chatSocket!.onDisconnect((_) {
      _isConnecting = false;
      isConnected.value = false;
      _disposeNotificationSocket();

      if (_isDisposingSocket) {
        debugPrint('[Socket] Disconnected (socket reset)');
        return;
      }

      debugPrint('[Socket] Disconnected');
      if (_allowAutoReconnect) {
        _scheduleReconnect();
      }
    });

    _chatSocket!.onConnectError((error) {
      _isConnecting = false;
      isConnected.value = false;

      if (_isDisposingSocket) {
        debugPrint('[Socket] Connection error during socket reset: $error');
        return;
      }

      debugPrint('[Socket] Connection error: $error');
      if (_allowAutoReconnect) {
        _scheduleReconnect();
      }
    });
    _chatSocket!.onError((error) {
      debugPrint('[Socket] Error: $error');
      final asText = '$error'.toLowerCase();
      if (_allowAutoReconnect &&
          !isConnected.value &&
          !_isConnecting &&
          asText.contains('timeout')) {
        _scheduleReconnect();
      }
    });

    // ─── Notification Socket (/notifications namespace) ──
    _chatSocket!.connect();
  }

  void _connectNotificationSocket(String token) {
    if (_notifSocket != null || _isNotifConnecting) return;

    _isNotifConnecting = true;
    _notifSocket = io.io(
      '${ApiConstants.socketUrl}/notifications',
      _socketOptions(token).build(),
    );

    _notifSocket!.onConnect((_) {
      _isNotifConnecting = false;
      debugPrint('[Socket] Notification socket connected');
    });
    _notifSocket!.onDisconnect((_) {
      _isNotifConnecting = false;
    });
    _notifSocket!.onConnectError((error) {
      _isNotifConnecting = false;
      debugPrint('[Socket] Notification connection error: $error');
    });
    _notifSocket!.onError((error) {
      debugPrint('[Socket] Notification error: $error');
    });
    _notifSocket!.on('notification', _handleRealtimeNotification);
    _notifSocket!.on('pendingNotifications', _handlePendingNotifications);
    _notifSocket!.connect();
  }

  void _disposeNotificationSocket() {
    _isNotifConnecting = false;
    try {
      _notifSocket?.disconnect();
    } catch (_) {}
    try {
      _notifSocket?.dispose();
    } catch (_) {}
    _notifSocket = null;
  }

  void _disposeChatSocket() {
    if (_chatSocket == null) return;

    _isDisposingSocket = true;
    _isConnecting = false;
    try {
      _chatSocket?.off('connect');
      _chatSocket?.off('disconnect');
      _chatSocket?.off('connect_error');
      _chatSocket?.off('error');
    } catch (_) {}
    try {
      _chatSocket?.disconnect();
    } catch (_) {}
    try {
      _chatSocket?.dispose();
    } catch (_) {}
    _chatSocket = null;
    _isDisposingSocket = false;
  }

  void disconnect({bool manual = true}) {
    if (manual) {
      _allowAutoReconnect = false;
    }
    _reconnectTimer?.cancel();
    _disposeChatSocket();
    _disposeNotificationSocket();
    isConnected.value = false;
    isReconnecting.value = false;
    _isConnecting = false;
  }

  // ─── Exponential Backoff Reconnect ─────────────────────────

  void _scheduleReconnect() {
    if (!_allowAutoReconnect) {
      isReconnecting.value = false;
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[Socket] Max reconnect attempts reached');
      isReconnecting.value = false;
      return;
    }

    _reconnectTimer?.cancel();
    isReconnecting.value = true;

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 32s (capped)
    final delayMs = (_baseDelayMs * (1 << _reconnectAttempts)).clamp(
      _baseDelayMs,
      _maxDelayMs,
    );
    debugPrint(
      '[Socket] Scheduling reconnect in ${delayMs}ms (attempt ${_reconnectAttempts + 1})',
    );

    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      _reconnectAttempts++;
      _attemptReconnect();
    });
  }

  void _attemptReconnect() async {
    if (!_allowAutoReconnect || isConnected.value || _isConnecting) return;

    final token = await _storage.getToken();
    if (token == null) {
      debugPrint('[Socket] No token - cannot reconnect');
      isReconnecting.value = false;
      return;
    }

    debugPrint('[Socket] Attempting reconnect...');
    connect();
  }

  void _flushMessageQueue() {
    try {
      if (Get.isRegistered<MessageQueueService>()) {
        final queue = Get.find<MessageQueueService>();
        if (queue.pendingCount > 0) {
          debugPrint('[Socket] Flushing ${queue.pendingCount} queued messages');
          queue.flushQueue();
        }
      }
    } catch (e) {
      debugPrint('[Socket] Queue flush error: $e');
    }
  }

  /// Force reconnect (public API)
  void forceReconnect() {
    _reconnectAttempts = 0;
    _allowAutoReconnect = true;
    disconnect(manual: false);
    _attemptReconnect();
  }

  // ─── Real-time Notification Handlers ───────────────────
  void _handleRealtimeNotification(dynamic data) {
    if (data == null) return;
    try {
      final notif = NotificationModel.fromJson(
        data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data),
      );
      // Update service list
      if (Get.isRegistered<NotificationService>()) {
        final service = Get.find<NotificationService>();
        if (notif.id.isNotEmpty &&
            service.notifications.any((existing) => existing.id == notif.id)) {
          return;
        }
        service.notifications.insert(0, notif);
        service.unreadCount.value = service.notifications
            .where((n) => !n.isRead)
            .length;
        service.hasUnreadNotifications.value = service.unreadCount.value > 0;
      }
      // Show in-app toast
      _showNotificationToast(notif);
    } catch (_) {}
  }

  void _handlePendingNotifications(dynamic data) {
    if (data == null || data is! List) return;
    try {
      if (Get.isRegistered<NotificationService>()) {
        final service = Get.find<NotificationService>();
        final pending = data
            .map(
              (n) => NotificationModel.fromJson(
                n is Map<String, dynamic> ? n : Map<String, dynamic>.from(n),
              ),
            )
            .toList();
        // Merge: add any we don't already have
        for (final n in pending) {
          if (!service.notifications.any((e) => e.id == n.id)) {
            service.notifications.add(n);
          }
        }
        service.notifications.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );
        service.unreadCount.value = service.notifications
            .where((n) => !n.isRead)
            .length;
      }
    } catch (_) {}
  }

  void _showNotificationToast(NotificationModel notif) {
    final icon = _notifIcon(notif.type);
    Get.snackbar(
      notif.title,
      notif.body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.surfaceLight,
      colorText: AppColors.textPrimaryLight,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      borderRadius: 16,
      duration: const Duration(seconds: 4),
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      animationDuration: const Duration(milliseconds: 300),
      forwardAnimationCurve: Curves.easeOutCubic,
    );
  }

  IconData _notifIcon(String type) {
    switch (type) {
      case 'match':
        return LucideIcons.heart;
      case 'like':
        return LucideIcons.heartHandshake;
      case 'message':
        return LucideIcons.messageSquare;
      case 'subscription':
        return LucideIcons.crown;
      case 'profile_view':
        return LucideIcons.eye;
      case 'verification':
        return LucideIcons.shieldCheck;
      default:
        return LucideIcons.bell;
    }
  }

  // ─── Chat Emit Events ─────────────────────────────────────
  void emit(String event, [dynamic data]) {
    if (_chatSocket == null || !isConnected.value) {
      debugPrint('[Socket] emit($event) skipped — not connected');
      return;
    }
    _chatSocket!.emit(event, data);
  }

  void sendMessage(String conversationId, String content) {
    emit('sendMessage', {'conversationId': conversationId, 'content': content});
  }

  /// Send message with client-generated ID for duplicate prevention and tracking
  void sendMessageWithId(
    String conversationId,
    String content,
    String clientMsgId,
  ) {
    emit('sendMessage', {
      'conversationId': conversationId,
      'content': content,
      'clientMsgId': clientMsgId,
    });
  }

  void joinConversation(String conversationId) {
    emit('joinConversation', {'conversationId': conversationId});
  }

  void leaveConversation(String conversationId) {
    emit('leaveConversation', {'conversationId': conversationId});
  }

  void sendTyping(String conversationId) {
    emit('typing', {'conversationId': conversationId});
  }

  void markAsRead(String conversationId) {
    emit('markRead', {'conversationId': conversationId});
  }

  // ─── Chat Listen Events ───────────────────────────────────
  void on(String event, Function(dynamic) callback) {
    _chatSocket?.on(event, callback);
  }

  void off(String event) {
    _chatSocket?.off(event);
  }

  void onNewMessage(Function(dynamic) callback) => on('newMessage', callback);
  void onTyping(Function(dynamic) callback) => on('typing', callback);
  void onUserOnline(Function(dynamic) callback) => on('userOnline', callback);
  void onUserOffline(Function(dynamic) callback) => on('userOffline', callback);
  void onNewMatch(Function(dynamic) callback) => on('newMatch', callback);
  void onNewNotification(Function(dynamic) callback) =>
      on('notification', callback);
}
