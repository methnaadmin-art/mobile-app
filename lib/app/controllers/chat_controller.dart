import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/controllers/users_controller.dart';
import 'package:methna_app/app/data/services/socket_service.dart';
import 'package:methna_app/app/data/services/notification_service.dart';
import 'package:methna_app/app/data/services/message_queue_service.dart';
import 'package:methna_app/app/data/models/conversation_model.dart';
import 'package:methna_app/app/data/models/message_model.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/utils/auth_navigation_resolver.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/utils/bad_words_filter.dart';
import 'package:methna_app/core/utils/input_sanitizer.dart';
import 'package:methna_app/core/utils/match_found_presentation_guard.dart';
import 'package:methna_app/screens/main/home/match_found_screen.dart';

/// Message delivery status for optimistic UI
enum MessageStatus { pending, sent, delivered, read, failed }

class ChatController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final AuthService _auth = Get.find<AuthService>();
  final SocketService _socket = Get.find<SocketService>();
  final StorageService _storage = Get.find<StorageService>();

  final RxList<ConversationModel> conversations = <ConversationModel>[].obs;
  final RxList<UserModel> onlineTodayUsers = <UserModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString searchQuery = ''.obs;

  // Active chat state
  final RxList<MessageModel> activeMessages = <MessageModel>[].obs;
  final Rx<ConversationModel?> activeConversation = Rx<ConversationModel?>(
    null,
  );
  final RxBool isTyping = false.obs;
  final RxBool messagesLoading = false.obs;

  // Ice breaker suggestions
  final RxList<String> iceBreakers = <String>[].obs;

  // Read receipts: maps messageId → read status
  final RxMap<String, bool> readReceipts = <String, bool>{}.obs;

  // Online presence: maps userId → online status
  final RxMap<String, bool> onlinePresence = <String, bool>{}.obs;

  // Message status tracking for optimistic UI: clientMsgId → status
  final RxMap<String, MessageStatus> messageStatuses =
      <String, MessageStatus>{}.obs;

  // Sent message IDs to prevent duplicates
  final Set<String> _sentMessageIds = {};

  // Keep unmatched users hidden from the conversation list.
  final Set<String> _hiddenConversationUserIds = <String>{};

  // Client message ID to server message ID mapping
  final Map<String, String> _clientToServerIds = {};

  // Typing debounce to avoid spamming the server
  Timer? _typingDebounce;

  // Debounce for conversation list refresh
  Timer? _fetchConversationsDebounce;
  Timer? _liveTodayRefreshTimer;

  // Message input controller (managed here to avoid leak in build())
  final TextEditingController messageTextController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _loadCachedConversationsInstantly();
    _setupSocketListeners();
    _startLiveTodayAutoRefresh();
    unawaited(_loadInitialDataAfterAuthRestore());
  }

  void _loadCachedConversationsInstantly() {
    try {
      final cached = Get.find<StorageService>().getCachedConversations();
      if (cached != null && cached.isNotEmpty) {
        final convs = cached
            .map(
              (json) =>
                  ConversationModel.fromJson(json, currentUserId: _auth.userId),
            )
            .toList();
        conversations.assignAll(convs);
        debugPrint(
          '[ChatController] Loaded ${convs.length} cached conversations instantly',
        );
      }
    } catch (e) {
      debugPrint('[ChatController] Failed to load cached conversations: $e');
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([fetchConversations(), fetchLiveTodayUsers()]);
  }

  Future<void> _waitForSessionRestoreIfNeeded() async {
    if (!_auth.sessionRestorePending.value) return;

    final completer = Completer<void>();
    late Worker worker;
    worker = ever<bool>(_auth.sessionRestorePending, (pending) {
      if (!pending && !completer.isCompleted) {
        worker.dispose();
        completer.complete();
      }
    });

    try {
      await completer.future.timeout(const Duration(seconds: 10));
    } catch (_) {
      worker.dispose();
    }
  }

  Future<void> _loadInitialDataAfterAuthRestore() async {
    await _waitForSessionRestoreIfNeeded();
    if (Get.currentRoute != AppRoutes.main) return;
    await _loadInitialData();
  }

  @override
  void onClose() {
    _typingDebounce?.cancel();
    _fetchConversationsDebounce?.cancel();
    _liveTodayRefreshTimer?.cancel();
    messageTextController.dispose();
    super.onClose();
  }

  void _startLiveTodayAutoRefresh() {
    _liveTodayRefreshTimer?.cancel();
    _liveTodayRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (Get.currentRoute != AppRoutes.main) return;
      unawaited(fetchLiveTodayUsers());
    });
  }

  String get _currentUserId {
    return _auth.userId ?? _auth.currentUser.value?.id ?? '';
  }

  Set<String> get _blockedUserIds => _storage.getBlockedUserIds();

  List<dynamic> _extractUserList(dynamic source) {
    if (source is List) return source;
    if (source is! Map) return const <dynamic>[];

    const keys = <String>[
      'users',
      'results',
      'items',
      'list',
      'profiles',
      'data',
      'liveToday',
      'live_today',
      'live_today_users',
      'activeUsers',
      'active_users',
      'onlineUsers',
      'online_users',
      'participants',
    ];

    for (final key in keys) {
      final candidate = source[key];
      if (candidate is List) return candidate;
    }

    for (final value in source.values) {
      final nested = _extractUserList(value);
      if (nested.isNotEmpty) return nested;
    }

    return const <dynamic>[];
  }

  List<UserModel> _parseUsers(dynamic payload) {
    final source = _extractUserList(payload);
    if (source.isEmpty) return const <UserModel>[];

    return source
        .whereType<Map>()
        .map(
          (entry) => UserModel.fromApiEntry(Map<String, dynamic>.from(entry)),
        )
        .where((user) => user.id.isNotEmpty && user.id != _currentUserId)
        .toList(growable: false);
  }

  List<UserModel> _normalizeLiveTodayUsers(
    Iterable<UserModel> users, {
    bool requireLiveSignal = true,
  }) {
    final blockedIds = _blockedUserIds;
    final seenIds = <String>{};
    final normalized = users
        .where(
          (u) =>
              u.id.isNotEmpty &&
              u.id != _currentUserId &&
              !blockedIds.contains(u.id.trim()) &&
              (!requireLiveSignal || u.isOnline || u.wasLiveInLast24Hours) &&
              seenIds.add(u.id),
        )
        .toList(growable: false);

    normalized.sort((a, b) {
      if (a.isOnline != b.isOnline) {
        return a.isOnline ? -1 : 1;
      }
      final aSeen = a.lastLoginAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bSeen = b.lastLoginAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bSeen.compareTo(aSeen);
    });

    return normalized;
  }

  List<UserModel> _conversationLiveUsers() {
    return _normalizeLiveTodayUsers(
      conversations.map((c) => c.otherUser).whereType<UserModel>(),
    );
  }

  List<UserModel> _recentConversationUsers() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return _normalizeLiveTodayUsers(
      conversations
          .where(
            (c) => c.lastMessageAt != null && c.lastMessageAt!.isAfter(cutoff),
          )
          .map((c) => c.otherUser)
          .whereType<UserModel>(),
      requireLiveSignal: false,
    );
  }

  int _userRichnessScore(UserModel user) {
    var score = 0;
    if ((user.mainPhotoUrl ?? '').trim().isNotEmpty) score += 5;
    if (user.photos?.isNotEmpty == true) score += 3;
    if (user.fullName.trim().isNotEmpty || user.displayName.trim().isNotEmpty) {
      score += 3;
    }
    if (user.profile != null) score += 2;
    if ((user.profile?.city ?? '').trim().isNotEmpty) score += 1;
    if ((user.profile?.country ?? '').trim().isNotEmpty) score += 1;
    if ((user.profile?.bio ?? '').trim().isNotEmpty) score += 1;
    return score;
  }

  UserModel _preferRicherUser(UserModel primary, UserModel candidate) {
    final primaryScore = _userRichnessScore(primary);
    final candidateScore = _userRichnessScore(candidate);

    if (candidateScore > primaryScore) return candidate;
    if (candidateScore < primaryScore) return primary;

    if (candidate.isOnline && !primary.isOnline) {
      return candidate;
    }

    return primary;
  }

  void _storeKnownUser(Map<String, UserModel> knownById, UserModel? user) {
    if (user == null || user.id.isEmpty) return;
    final existing = knownById[user.id];
    if (existing == null) {
      knownById[user.id] = user;
      return;
    }
    knownById[user.id] = _preferRicherUser(existing, user);
  }

  String _resolveOtherUserId(ConversationModel conversation) {
    final directId = conversation.otherUser?.id ?? '';
    if (directId.isNotEmpty) return directId;

    final me = _currentUserId;
    if (me.isNotEmpty) {
      if (conversation.user1Id.isNotEmpty && conversation.user1Id != me) {
        return conversation.user1Id;
      }
      if (conversation.user2Id.isNotEmpty && conversation.user2Id != me) {
        return conversation.user2Id;
      }
    }

    if (conversation.user1Id.isNotEmpty) return conversation.user1Id;
    return conversation.user2Id;
  }

  List<ConversationModel> _hydrateConversations(
    List<ConversationModel> parsed,
  ) {
    final blockedIds = _blockedUserIds;
    final knownById = <String, UserModel>{};
    final previousById = <String, ConversationModel>{
      for (final conversation in conversations) conversation.id: conversation,
    };

    for (final conversation in conversations) {
      _storeKnownUser(knownById, conversation.otherUser);
    }
    for (final user in onlineTodayUsers) {
      _storeKnownUser(knownById, user);
    }

    if (Get.isRegistered<UsersController>()) {
      final usersController = Get.find<UsersController>();
      for (final user in usersController.allUsers) {
        _storeKnownUser(knownById, user);
      }
      for (final user in usersController.matches) {
        _storeKnownUser(knownById, user);
      }
      for (final user in usersController.nearbyUsers) {
        _storeKnownUser(knownById, user);
      }
      for (final user in usersController.liveTodayUsers) {
        _storeKnownUser(knownById, user);
      }
    }

    for (final conversation in parsed) {
      _storeKnownUser(knownById, conversation.otherUser);
    }

    return parsed
        .map((conversation) {
          UserModel? selected = conversation.otherUser;

          final previous = previousById[conversation.id];
          final previousOtherUser = previous?.otherUser;
          if (previousOtherUser != null) {
            selected = selected == null
                ? previousOtherUser
                : _preferRicherUser(selected, previousOtherUser);
          }

          final otherUserId = _resolveOtherUserId(conversation);
          if (otherUserId.isNotEmpty) {
            final known = knownById[otherUserId];
            if (known != null) {
              selected = selected == null
                  ? known
                  : _preferRicherUser(selected, known);
            }
          } else if (selected != null) {
            final known = knownById[selected.id];
            if (known != null) {
              selected = _preferRicherUser(selected, known);
            }
          }

          if (selected == null && otherUserId.isNotEmpty) {
            selected = UserModel.fromApiEntry({'id': otherUserId});
          }

          return conversation.copyWith(otherUser: selected);
        })
        .where((conversation) {
          final otherUserId = _resolveOtherUserId(conversation).trim();
          if (conversation.isLocked) return false;
          if (otherUserId.isEmpty) return true;
          if (_hiddenConversationUserIds.contains(otherUserId)) return false;
          return !blockedIds.contains(otherUserId);
        })
        .toList(growable: false);
  }

  ConversationModel _mergeConversationWithUser(
    ConversationModel conversation,
    UserModel? user,
  ) {
    if (user == null || user.id.isEmpty) {
      return conversation;
    }

    final selected = conversation.otherUser == null
        ? user
        : _preferRicherUser(conversation.otherUser!, user);
    return conversation.copyWith(otherUser: selected);
  }

  void _upsertConversation(ConversationModel conversation) {
    if (conversation.isLocked) return;
    final otherUserId = _resolveOtherUserId(conversation).trim();
    if (otherUserId.isNotEmpty && _blockedUserIds.contains(otherUserId)) {
      return;
    }
    if (otherUserId.isNotEmpty &&
        _hiddenConversationUserIds.contains(otherUserId)) {
      return;
    }
    final index = conversations.indexWhere(
      (item) => item.id == conversation.id,
    );
    if (index == -1) {
      conversations.insert(0, conversation);
    } else {
      conversations[index] = conversation;
      if (index != 0) {
        final updated = conversations.removeAt(index);
        conversations.insert(0, updated);
      }
    }
    conversations.refresh();
  }

  void evictUsersByIds(Iterable<String> userIds) {
    final blockedIds = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (blockedIds.isEmpty) return;

    _hiddenConversationUserIds.addAll(blockedIds);

    conversations.removeWhere((conversation) {
      final otherUserId = _resolveOtherUserId(conversation).trim();
      return blockedIds.contains(otherUserId);
    });
    onlineTodayUsers.removeWhere((user) => blockedIds.contains(user.id));
    conversations.refresh();
    onlineTodayUsers.refresh();

    final active = activeConversation.value;
    if (active != null &&
        blockedIds.contains(_resolveOtherUserId(active).trim())) {
      leaveActiveChat();
    }
  }

  void restoreConversationVisibilityForUser(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) return;
    _hiddenConversationUserIds.remove(normalized);
  }

  Future<void> deleteConversationForUser(
    String userId, {
    bool remoteDelete = true,
  }) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) return;

    _hiddenConversationUserIds.add(normalized);
    final targetConversation = conversations.firstWhereOrNull(
      (conversation) => _resolveOtherUserId(conversation).trim() == normalized,
    );

    evictUsersByIds({normalized});

    if (!remoteDelete || targetConversation == null) {
      return;
    }

    try {
      await _api.delete(ApiConstants.conversationById(targetConversation.id));
    } catch (error) {
      debugPrint(
        '[ChatController] deleteConversationForUser remote delete failed: $error',
      );
    }
  }

  void _presentMatchFound(UserModel? matchedUser, {String? matchId}) {
    if (matchedUser == null || matchedUser.id.isEmpty) return;
    if (!MatchFoundPresentationGuard.beginPresentation(
      matchId: matchId,
      userId: matchedUser.id,
    )) {
      return;
    }
    debugPrint(
      '[ChatController] Presenting match overlay for ${matchedUser.id} (matchId=${matchId ?? 'unknown'})',
    );
    unawaited(
      MatchFoundScreen.showOverlay(matchedUser).then(
        (displayed) => MatchFoundPresentationGuard.endPresentation(
          markDismissed: displayed,
        ),
      ),
    );
  }

  // ─── Socket listeners ──────────────────────────────────────────
  void _setupSocketListeners() {
    _socket.onNewMessage((data) {
      final msg = MessageModel.fromJson(data);
      final clientMsgId = data['clientMsgId'] as String?;
      final isIncomingForActiveConversation =
          activeConversation.value?.id == msg.conversationId;

      if (isIncomingForActiveConversation) {
        _mergeIncomingActiveMessage(msg, clientMsgId: clientMsgId);
        if (msg.senderId != (_auth.userId ?? '')) {
          _socket.markAsRead(msg.conversationId);
        }
      } else if (clientMsgId != null && _sentMessageIds.contains(clientMsgId)) {
        updateMessageStatus(
          clientMsgId,
          MessageStatus.delivered,
          serverId: msg.id,
        );
      }

      // Debounced refresh to avoid hammering API on rapid messages
      _debouncedFetchConversations();
    });

    _socket.onTyping((data) {
      if (data == null || data is! Map) return;
      final convId = data['conversationId'] as String?;
      if (convId != null && activeConversation.value?.id == convId) {
        isTyping.value = true;
        Future.delayed(
          const Duration(seconds: 3),
          () => isTyping.value = false,
        );
      }
    });

    // Read receipts from remote user (backend emits 'messagesRead')
    _socket.on('messagesRead', (data) {
      if (data is! Map) return;

      final convId = data['conversationId']?.toString();
      final rawIds = data['messageIds'] ?? data['ids'] ?? data['messages'];
      final messageIds = <String>{};

      if (rawIds is List) {
        for (final id in rawIds) {
          final normalized = id?.toString() ?? '';
          if (normalized.isNotEmpty) {
            messageIds.add(normalized);
            readReceipts[normalized] = true;
          }
        }
      }

      _markOutgoingMessagesAsRead(
        conversationId: convId,
        messageIds: messageIds.isEmpty ? null : messageIds,
      );
    });

    // Presence tracking
    _socket.onUserOnline((data) {
      final userId = data['userId'] as String?;
      if (userId != null) onlinePresence[userId] = true;
    });

    _socket.onUserOffline((data) {
      final userId = data['userId'] as String?;
      if (userId != null) onlinePresence[userId] = false;
    });

    // New match — refresh conversations so the new match appears
    _socket.onNewMatch((data) {
      fetchConversations();
      // Navigate to match screen if data contains matched user info
      if (data != null && data['matchedUser'] != null) {
        try {
          final matchedUser = UserModel.fromJson(data['matchedUser']);
          restoreConversationVisibilityForUser(matchedUser.id);
          final matchId = MatchFoundPresentationGuard.extractMatchId(data);
          if (Get.isRegistered<UsersController>()) {
            Get.find<UsersController>().registerIncomingMatch(
              matchedUser,
              matchId: matchId,
              presentPopup: true,
            );
          } else {
            _presentMatchFound(matchedUser, matchId: matchId);
          }
        } catch (_) {}
      }
    });

    // New notification — trigger notification service refresh
    _socket.onNewNotification((data) {
      try {
        Get.find<NotificationService>().fetchNotifications();
      } catch (_) {}
    });
  }

  void _mergeIncomingActiveMessage(
    MessageModel incoming, {
    String? clientMsgId,
  }) {
    if (clientMsgId != null && _sentMessageIds.contains(clientMsgId)) {
      updateMessageStatus(
        clientMsgId,
        MessageStatus.delivered,
        serverId: incoming.id,
      );
      return;
    }

    final existingServerIndex = activeMessages.indexWhere(
      (message) => message.id == incoming.id,
    );
    if (existingServerIndex != -1) {
      activeMessages[existingServerIndex] = incoming;
      activeMessages.refresh();
      return;
    }

    final optimisticIndex = _findMatchingOptimisticMessageIndex(
      incoming,
      clientMsgId: clientMsgId,
    );
    if (optimisticIndex != -1) {
      final optimisticId = activeMessages[optimisticIndex].id;
      _clientToServerIds[optimisticId] = incoming.id;
      activeMessages[optimisticIndex] = incoming;
      messageStatuses[incoming.id] = MessageStatus.delivered;
      _sentMessageIds.remove(optimisticId);
      activeMessages.refresh();
      return;
    }

    final duplicateIndex = activeMessages.indexWhere(
      (message) => _messagesLookEquivalent(message, incoming),
    );
    if (duplicateIndex != -1) {
      activeMessages[duplicateIndex] = incoming;
      activeMessages.refresh();
      return;
    }

    activeMessages.insert(0, incoming);
  }

  int _findMatchingOptimisticMessageIndex(
    MessageModel incoming, {
    String? clientMsgId,
  }) {
    if (clientMsgId != null) {
      return activeMessages.indexWhere((message) => message.id == clientMsgId);
    }

    final currentUserId = _auth.userId ?? '';
    if (incoming.senderId != currentUserId) {
      return -1;
    }

    return activeMessages.indexWhere((message) {
      final status = messageStatuses[message.id];
      final isOptimistic =
          status == MessageStatus.pending || status == MessageStatus.sent;
      if (!isOptimistic) {
        return false;
      }

      return _messagesLookEquivalent(message, incoming);
    });
  }

  bool _messagesLookEquivalent(MessageModel a, MessageModel b) {
    if (a.id == b.id) {
      return true;
    }

    if (a.conversationId != b.conversationId || a.senderId != b.senderId) {
      return false;
    }

    if (a.content.trim() != b.content.trim()) {
      return false;
    }

    return a.createdAt.difference(b.createdAt).inSeconds.abs() <= 15;
  }

  // ─── Conversations ─────────────────────────────────────────────
  Future<void> fetchConversations() async {
    if (isLoading.value) return; // Prevent duplicate calls
    isLoading.value = true;
    hasError.value = false;
    try {
      debugPrint(
        '[ChatController] fetchConversations: calling ${ApiConstants.conversations}',
      );
      final response = await _api.get(ApiConstants.conversations);
      final data = response.data;
      debugPrint(
        '[ChatController] fetchConversations: response type=${data.runtimeType} data: $data',
      );

      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map) {
        list =
            data['conversations'] ??
            (data['data'] != null && data['data'] is Map
                ? data['data']['conversations']
                : null) ??
            [];
      } else {
        list = [];
      }

      final userId = _auth.userId;
      final rawConversations = list
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
      final parsedConversations = rawConversations
          .map(
            (entry) => ConversationModel.fromJson(entry, currentUserId: userId),
          )
          .toList(growable: false);
      conversations.assignAll(_hydrateConversations(parsedConversations));

      // Save cache offline
      Get.find<StorageService>()
          .cacheConversations(rawConversations)
          .catchError((_) {});

      debugPrint(
        '[ChatController] fetchConversations: Parsed ${conversations.length} conversations',
      );

      final fallbackLive = _conversationLiveUsers();
      if (onlineTodayUsers.isEmpty) {
        final recentFallback = _recentConversationUsers();
        final seeded = _normalizeLiveTodayUsers([
          ...fallbackLive,
          ...recentFallback,
        ], requireLiveSignal: false);
        onlineTodayUsers.assignAll(seeded.take(15).toList());
      } else if (fallbackLive.isNotEmpty) {
        final recentFallback = _recentConversationUsers();
        final merged = _normalizeLiveTodayUsers([
          ...fallbackLive,
          ...recentFallback,
          ...onlineTodayUsers,
        ], requireLiveSignal: false);
        if (merged.isNotEmpty) {
          onlineTodayUsers.assignAll(merged.take(15).toList());
        }
      }
    } catch (e, stackTrace) {
      hasError.value = true;
      debugPrint('[ChatController] fetchConversations CRITICAL ERROR: $e');
      debugPrint('[ChatController] stackTrace: $stackTrace');
      if (kDebugMode) {
        Get.snackbar('Chat Load Error', e.toString());
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchLiveTodayUsers() async {
    try {
      final response = await _api.get(
        ApiConstants.chatLiveToday,
        queryParameters: const {'limit': 15, 'hours': 24},
      );
      final parsedEndpointUsers = _parseUsers(response.data);
      final strictUsers = _normalizeLiveTodayUsers(parsedEndpointUsers);
      if (strictUsers.isNotEmpty) {
        onlineTodayUsers.assignAll(strictUsers.take(15).toList());
        return;
      }

      // Some backend payloads for /chat/live-today omit explicit last-seen flags.
      if (parsedEndpointUsers.isNotEmpty) {
        final permissiveUsers = _normalizeLiveTodayUsers(
          parsedEndpointUsers,
          requireLiveSignal: false,
        );
        if (permissiveUsers.isNotEmpty) {
          onlineTodayUsers.assignAll(permissiveUsers.take(15).toList());
          return;
        }
      }

      final conversationFallback = _conversationLiveUsers();
      if (conversationFallback.isNotEmpty) {
        final recentFallback = _recentConversationUsers();
        final mergedFallback = _normalizeLiveTodayUsers([
          ...conversationFallback,
          ...recentFallback,
          ...parsedEndpointUsers,
        ], requireLiveSignal: false);
        onlineTodayUsers.assignAll(mergedFallback.take(15).toList());
        return;
      }

      final recentConversationFallback = _recentConversationUsers();
      if (recentConversationFallback.isNotEmpty) {
        onlineTodayUsers.assignAll(
          recentConversationFallback.take(15).toList(),
        );
        return;
      }

      onlineTodayUsers.clear();
    } catch (e) {
      debugPrint('[ChatController] fetchLiveTodayUsers error: $e');
      final conversationFallback = _conversationLiveUsers();
      final recentFallback = _recentConversationUsers();
      if (onlineTodayUsers.isEmpty) {
        final mergedFallback = _normalizeLiveTodayUsers([
          ...conversationFallback,
          ...recentFallback,
        ], requireLiveSignal: false);
        if (mergedFallback.isNotEmpty) {
          onlineTodayUsers.assignAll(mergedFallback.take(15).toList());
        }
      }
    }
  }

  Future<void> openConversation(ConversationModel conversation) async {
    activeConversation.value = conversation;
    activeMessages.clear();
    iceBreakers.clear();
    _socket.joinConversation(conversation.id);
    Get.toNamed(
      AppRoutes.chatDetail,
      arguments: {'conversation': conversation},
    );
    await fetchMessages(conversation.id);
    // Fetch ice breakers if no messages yet
    if (activeMessages.isEmpty && conversation.otherUser != null) {
      _fetchIceBreakers(conversation.otherUser!.id);
    }
  }

  /// Opens a conversation by ID, fetching it if necessary.
  Future<void> openConversationById(
    String conversationId, {
    bool showLoader = true,
  }) async {
    var conv = conversations.firstWhereOrNull((c) => c.id == conversationId);
    if (conv == null) {
      var loaderShown = false;
      if (showLoader) {
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
        loaderShown = true;
      }

      try {
        await fetchConversations();
        if (loaderShown && (Get.isDialogOpen ?? false)) {
          Get.back();
        }
        conv = conversations.firstWhereOrNull((c) => c.id == conversationId);
      } catch (e) {
        if (loaderShown && (Get.isDialogOpen ?? false)) {
          Get.back();
        }
      }
    }

    if (conv != null) {
      openConversation(conv);
    } else {
      Get.snackbar('error'.tr, 'conversation_not_found'.tr);
    }
  }

  Future<void> openConversationByMatchId(String matchId) async {
    var conv = conversations.firstWhereOrNull((c) => c.matchId == matchId);
    if (conv == null) {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      try {
        await fetchConversations();
      } finally {
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      }
      conv = conversations.firstWhereOrNull((c) => c.matchId == matchId);
    }

    if (conv != null) {
      await openConversation(conv);
    } else {
      Get.snackbar('error'.tr, 'conversation_not_found'.tr);
    }
  }

  /// Finds or creates a conversation with a specific user and navigates to it.
  Future<void> openConversationWithUser(UserModel user) async {
    // 1. Check if we already have a conversation with this user
    final existing = conversations.firstWhereOrNull(
      (c) => c.otherUser?.id == user.id || _resolveOtherUserId(c) == user.id,
    );
    if (existing != null) {
      final hydratedExisting = _mergeConversationWithUser(existing, user);
      _upsertConversation(hydratedExisting);
      return openConversation(hydratedExisting);
    }

    // 2. If not, try to create one (or fetch it if backend creates on match)
    isLoading.value = true;
    try {
      final response = await _api.post(
        ApiConstants.conversations,
        data: {'targetUserId': user.id},
      );
      final rawConversation =
          response.data is Map && response.data['data'] is Map
          ? Map<String, dynamic>.from(response.data['data'] as Map)
          : (response.data is Map
                ? Map<String, dynamic>.from(response.data as Map)
                : <String, dynamic>{});
      final parsedConversation = ConversationModel.fromJson(
        rawConversation,
        currentUserId: _auth.userId,
      );
      if (parsedConversation.id.isEmpty) {
        await fetchConversations();
        final resolved = conversations.firstWhereOrNull(
          (c) =>
              c.otherUser?.id == user.id || _resolveOtherUserId(c) == user.id,
        );
        if (resolved != null) {
          final hydratedResolved = _mergeConversationWithUser(resolved, user);
          _upsertConversation(hydratedResolved);
          return openConversation(hydratedResolved);
        }
        throw StateError('Conversation created without a valid id');
      }
      final conv = _mergeConversationWithUser(parsedConversation, user);

      // Update local list
      _upsertConversation(conv);
      unawaited(fetchConversations());

      return openConversation(conv);
    } catch (e) {
      debugPrint('[ChatController] openConversationWithUser error: $e');
      if (_redirectToAccountStatusIfRestricted(e)) {
        return;
      }
      // Fallback: If creation fails, we might not be allowed to chat yet (not a match)
      Get.snackbar(
        'Cannot chat',
        'You can only message people you have matched with.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  bool _redirectToAccountStatusIfRestricted(dynamic error) {
    if (error is! DioException) {
      return false;
    }

    final raw = error.response?.data;
    final restrictedStatus = extractRestrictedAccountStatus(raw);
    if (restrictedStatus == null) {
      return false;
    }

    if (restrictedStatus == 'suspended') {
      return false;
    }

    final args = buildRestrictedAccountArguments(
      _auth.currentUser.value,
      fallbackStatus: restrictedStatus,
      fallbackReason: extractRestrictedAccountReason(raw),
      fallbackSupportMessage: extractRestrictedAccountSupportMessage(raw),
      fallbackActionRequired: extractRestrictedAccountActionRequired(raw),
      fallbackStaffMessage: extractRestrictedAccountStaffMessage(raw),
      fallbackExpiresAt: extractRestrictedAccountExpiresAt(raw),
    );

    if (args == null) {
      return false;
    }

    final targetRoute = restrictedStatus == 'banned'
        ? AppRoutes.contactSupport
        : AppRoutes.accountStatus;

    if (Get.currentRoute != targetRoute) {
      Get.offAllNamed(targetRoute, arguments: args);
    }
    return true;
  }

  Future<void> _fetchIceBreakers(String targetUserId) async {
    try {
      final response = await _api.get(ApiConstants.iceBreakers(targetUserId));
      if (response.data is List) {
        iceBreakers.assignAll(List<String>.from(response.data));
      }
    } catch (_) {}
  }

  void sendIceBreaker(String text) {
    sendMessage(text);
    iceBreakers.clear();
  }

  Future<void> fetchMessages(String conversationId, {int page = 1}) async {
    messagesLoading.value = true;
    try {
      debugPrint(
        '[ChatController] fetchMessages: calling ${ApiConstants.conversationMessages(conversationId)} page=$page',
      );
      final response = await _api.get(
        ApiConstants.conversationMessages(conversationId),
        queryParameters: {'page': page, 'limit': 50},
      );
      final data = response.data;
      debugPrint(
        '[ChatController] fetchMessages: response type=${data.runtimeType} data: $data',
      );

      final list = data is List ? data : data['messages'] ?? [];
      final msgs = (list as List).map((m) => MessageModel.fromJson(m)).toList();
      debugPrint(
        '[ChatController] fetchMessages: Parsed ${msgs.length} messages for conversation $conversationId',
      );

      // Sort newest first for reversed ListView (index 0 is at the bottom)
      msgs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (page == 1) {
        activeMessages.assignAll(msgs);
      } else {
        activeMessages.addAll(msgs);
        activeMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      _socket.markAsRead(conversationId);
    } catch (e) {
      debugPrint('[ChatController] fetchMessages error: $e');
    } finally {
      messagesLoading.value = false;
    }
  }

  // ─── UUID Generator ─────────────────────────────────────────────
  String _generateUUID() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // Version 4
    values[8] = (values[8] & 0x3f) | 0x80; // Variant
    final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  // ─── Send text message with sanitization & bad-words filter ────
  void sendMessage(String content) {
    if (content.trim().isEmpty || activeConversation.value == null) return;

    final currentUser = _auth.currentUser.value;
    if (currentUser != null &&
        currentUser.isSuspended &&
        !currentUser.isModerationExpired) {
      final reason = currentUser.moderationMessage.trim();
      Get.snackbar(
        'Messaging unavailable',
        reason.isNotEmpty
            ? reason
            : 'Your account is suspended and cannot send messages right now.',
      );
      return;
    }

    if (currentUser != null && currentUser.isBanned) {
      final args = buildRestrictedAccountArguments(currentUser);
      Get.offAllNamed(AppRoutes.contactSupport, arguments: args);
      return;
    }

    // Sanitize and censor the message before sending
    String sanitized = InputSanitizer.sanitize(content);
    sanitized = BadWordsFilter.censor(sanitized);

    // Generate unique client message ID (UUID) to prevent duplicates
    final clientMsgId = _generateUUID();

    // Check for duplicate (same content sent within 5 seconds)
    if (_isDuplicateMessage(activeConversation.value!.id, sanitized)) {
      debugPrint('[Chat] Duplicate message blocked');
      return;
    }

    // Track this message — start as 'sent' so the message appears directly
    // without the pending clock indicator animation
    _sentMessageIds.add(clientMsgId);
    messageStatuses[clientMsgId] = MessageStatus.sent;

    // Optimistic local insert so user sees their message immediately
    final optimisticMsg = MessageModel(
      id: clientMsgId,
      conversationId: activeConversation.value!.id,
      senderId: _auth.userId ?? '',
      content: sanitized,
      createdAt: DateTime.now(),
      isRead: false,
    );
    activeMessages.insert(0, optimisticMsg);
    _updateLocalConversationPreview(
      conversationId: optimisticMsg.conversationId,
      content: sanitized,
      sentAt: optimisticMsg.createdAt,
    );

    // Check if socket is connected
    final socket = Get.find<SocketService>();
    final queue = Get.find<MessageQueueService>();

    if (socket.isConnected.value) {
      // Online: send directly with client ID for tracking
      _socket.sendMessageWithId(
        activeConversation.value!.id,
        sanitized,
        clientMsgId,
      );
      messageStatuses[clientMsgId] = MessageStatus.sent;
      _schedulePendingMessageFallback(
        clientMsgId: clientMsgId,
        conversationId: activeConversation.value!.id,
        content: sanitized,
      );
    } else {
      // Offline: enqueue for later sending
      queue.enqueue(
        activeConversation.value!.id,
        sanitized,
        clientMsgId: clientMsgId,
      );
      messageStatuses[clientMsgId] = MessageStatus.pending;
      debugPrint('[Chat] Socket offline - message queued for later');
    }

    _debouncedFetchConversations();
  }

  // ─── Duplicate Detection ───────────────────────────────────────
  bool _isDuplicateMessage(String conversationId, String content) {
    // Check if same message was sent in last 5 seconds
    final recentMessages = activeMessages.where(
      (m) =>
          m.conversationId == conversationId &&
          m.content == content &&
          m.senderId == _auth.userId &&
          DateTime.now().difference(m.createdAt).inSeconds < 5,
    );
    return recentMessages.isNotEmpty;
  }

  void _updateLocalConversationPreview({
    required String conversationId,
    required String content,
    required DateTime sentAt,
  }) {
    final currentUserId = _currentUserId;
    final existing = conversations.firstWhereOrNull(
      (conversation) => conversation.id == conversationId,
    );
    if (existing == null) return;

    final updated = existing.copyWith(
      lastMessage: content,
      lastMessageAt: sentAt,
      lastMessageSenderId: currentUserId,
      unreadCount: 0,
      currentUserId: currentUserId,
    );
    _upsertConversation(updated);

    if (activeConversation.value?.id == conversationId) {
      activeConversation.value = updated;
    }
  }

  void _schedulePendingMessageFallback({
    required String clientMsgId,
    required String conversationId,
    required String content,
  }) {
    Future<void>.delayed(const Duration(milliseconds: 1200), () async {
      final status = messageStatuses[clientMsgId];
      if (status == null ||
          status == MessageStatus.delivered ||
          status == MessageStatus.read ||
          status == MessageStatus.failed) {
        return;
      }

      await _sendMessageViaRestFallback(
        clientMsgId: clientMsgId,
        conversationId: conversationId,
        content: content,
      );
    });
  }

  Future<void> _sendMessageViaRestFallback({
    required String clientMsgId,
    required String conversationId,
    required String content,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.conversationMessages(conversationId),
        data: {'content': content, 'clientMsgId': clientMsgId},
      );

      Map<String, dynamic>? payload;
      final data = response.data;
      if (data is Map) {
        if (data['message'] is Map) {
          payload = Map<String, dynamic>.from(data['message']);
        } else if (data['data'] is Map) {
          payload = Map<String, dynamic>.from(data['data']);
        } else {
          payload = Map<String, dynamic>.from(data);
        }
      }

      final serverId = (payload?['id'] ?? payload?['_id'])?.toString().trim();
      if (serverId != null && serverId.isNotEmpty) {
        updateMessageStatus(
          clientMsgId,
          MessageStatus.delivered,
          serverId: serverId,
        );
      } else {
        messageStatuses[clientMsgId] = MessageStatus.delivered;
      }

      _updateLocalConversationPreview(
        conversationId: conversationId,
        content: content,
        sentAt: DateTime.now(),
      );
      _debouncedFetchConversations();
    } catch (error) {
      if (_handleRestrictedMessagingError(error)) {
        return;
      }
      debugPrint('[ChatController] REST send fallback failed: $error');
    }
  }

  bool _handleRestrictedMessagingError(dynamic error) {
    if (error is! DioException) return false;

    final raw = error.response?.data;
    final restrictedStatus = extractRestrictedAccountStatus(raw);
    if (restrictedStatus == null) {
      return false;
    }

    if (restrictedStatus == 'suspended') {
      final reason =
          extractRestrictedAccountReason(raw) ??
          extractRestrictedAccountSupportMessage(raw) ??
          'Your account is suspended and cannot send messages right now.';
      Get.snackbar('Messaging unavailable', reason);
      return true;
    }

    final args = buildRestrictedAccountArguments(
      _auth.currentUser.value,
      fallbackStatus: restrictedStatus,
      fallbackReason: extractRestrictedAccountReason(raw),
      fallbackSupportMessage: extractRestrictedAccountSupportMessage(raw),
      fallbackActionRequired: extractRestrictedAccountActionRequired(raw),
      fallbackStaffMessage: extractRestrictedAccountStaffMessage(raw),
      fallbackExpiresAt: extractRestrictedAccountExpiresAt(raw),
    );

    if (args == null) return false;

    final targetRoute = restrictedStatus == 'banned'
        ? AppRoutes.contactSupport
        : AppRoutes.accountStatus;
    if (Get.currentRoute != targetRoute) {
      Get.offAllNamed(targetRoute, arguments: args);
    }
    return true;
  }

  // ─── Update Message Status (called when server confirms) ───────
  void updateMessageStatus(
    String clientMsgId,
    MessageStatus status, {
    String? serverId,
  }) {
    messageStatuses[clientMsgId] = status;

    if (serverId != null) {
      _clientToServerIds[clientMsgId] = serverId;
      // Replace optimistic message with server-confirmed one
      final index = activeMessages.indexWhere((m) => m.id == clientMsgId);
      if (index != -1) {
        final msg = activeMessages[index];
        activeMessages[index] = MessageModel(
          id: serverId,
          conversationId: msg.conversationId,
          senderId: msg.senderId,
          content: msg.content,
          createdAt: msg.createdAt,
          isRead: msg.isRead,
        );
      }
    }

    if (serverId != null || status == MessageStatus.failed) {
      _sentMessageIds.remove(clientMsgId);
    }
    activeMessages.refresh();
  }

  // ─── Retry Failed Message ──────────────────────────────────────
  void retryMessage(String clientMsgId) {
    final msg = activeMessages.firstWhereOrNull((m) => m.id == clientMsgId);
    if (msg == null) return;

    messageStatuses[clientMsgId] = MessageStatus.pending;

    final socket = Get.find<SocketService>();
    if (socket.isConnected.value) {
      _socket.sendMessageWithId(msg.conversationId, msg.content, clientMsgId);
      messageStatuses[clientMsgId] = MessageStatus.sent;
    } else {
      final queue = Get.find<MessageQueueService>();
      queue.enqueue(msg.conversationId, msg.content, clientMsgId: clientMsgId);
    }
    activeMessages.refresh();
  }

  void _markOutgoingMessagesAsRead({
    String? conversationId,
    Set<String>? messageIds,
  }) {
    final active = activeConversation.value;
    if (active == null) return;
    if (conversationId != null && conversationId != active.id) return;

    var changed = false;
    final normalizedIds = messageIds ?? const <String>{};

    final updated = activeMessages
        .map((message) {
          final isMine = message.senderId == (_auth.userId ?? '');
          if (!isMine) return message;

          final shouldMark =
              normalizedIds.isEmpty || normalizedIds.contains(message.id);
          if (!shouldMark || message.isRead) return message;

          changed = true;
          readReceipts[message.id] = true;
          messageStatuses[message.id] = MessageStatus.read;
          return MessageModel(
            id: message.id,
            conversationId: message.conversationId,
            senderId: message.senderId,
            content: message.content,
            type: message.type,
            isRead: true,
            createdAt: message.createdAt,
          );
        })
        .toList(growable: false);

    if (changed) {
      activeMessages.assignAll(updated);
    }
  }

  // ─── Get Message Status ────────────────────────────────────────
  MessageStatus getMessageStatus(String messageId) {
    return messageStatuses[messageId] ?? MessageStatus.delivered;
  }

  // ─── Typing indicator with debounce ────────────────────────────
  void sendTypingIndicator() {
    if (activeConversation.value == null) return;

    // Only emit once per 2 seconds to avoid spamming
    if (_typingDebounce?.isActive ?? false) return;
    _socket.sendTyping(activeConversation.value!.id);
    _typingDebounce = Timer(const Duration(seconds: 2), () {});
  }

  // ─── Leave active chat ─────────────────────────────────────────
  void leaveActiveChat() {
    if (activeConversation.value != null) {
      _socket.leaveConversation(activeConversation.value!.id);
      activeConversation.value = null;
      activeMessages.clear();
    }
  }

  // ─── Debounced conversation refresh ─────────────────────────────
  void _debouncedFetchConversations() {
    _fetchConversationsDebounce?.cancel();
    _fetchConversationsDebounce = Timer(const Duration(milliseconds: 450), () {
      fetchConversations();
    });
  }

  // ─── Helpers ───────────────────────────────────────────────────
  int get totalUnread => conversations.fold(
    0,
    (sum, c) => sum + c.unreadCount(_auth.userId ?? ''),
  );

  /// Check if a user is currently online via presence map.
  bool isUserOnline(String userId) => onlinePresence[userId] ?? false;

  /// Check if a message has been read by the recipient.
  bool isMessageRead(String messageId) => readReceipts[messageId] ?? false;

  void resetForLogout() {
    leaveActiveChat();
    conversations.clear();
    onlineTodayUsers.clear();
    iceBreakers.clear();
    searchQuery.value = '';
    isLoading.value = false;
    hasError.value = false;
    isTyping.value = false;
    messagesLoading.value = false;
    readReceipts.clear();
    onlinePresence.clear();
    messageStatuses.clear();
    _sentMessageIds.clear();
    _clientToServerIds.clear();
    _hiddenConversationUserIds.clear();
    _fetchConversationsDebounce?.cancel();
    _typingDebounce?.cancel();
    _liveTodayRefreshTimer?.cancel();
  }

  void searchConversations(String query) {
    searchQuery.value = query;
  }

  List<ConversationModel> get filteredConversations {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return conversations;
    return conversations.where((c) {
      final name = c.otherUser?.publicDisplayName.toLowerCase() ?? '';
      return name.contains(q);
    }).toList();
  }
}
