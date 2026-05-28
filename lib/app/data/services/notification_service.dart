import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/data/models/notification_model.dart';
import 'package:methna_app/app/data/services/firebase_bootstrap.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/controllers/chat_controller.dart';
import 'package:methna_app/app/controllers/navigation_controller.dart';
import 'package:methna_app/app/controllers/users_controller.dart';
import 'package:methna_app/app/utils/auth_navigation_resolver.dart';
import 'package:methna_app/core/utils/notification_route_resolver.dart';

class NotificationService extends GetxService {
  final ApiService _api = Get.find<ApiService>();
  final StorageService _storage = Get.find<StorageService>();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const String _cachedFcmTokenKey = 'cached_fcm_token_v1';
  static const String _syncedFcmTokenKey = 'synced_fcm_token_v1';

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool hasUnreadNotifications = false.obs;

  final RxString selectedCategory = 'all'.obs;
  final List<String> categories = [
    'all',
    'messages',
    'likes',
    'passes',
    'compliments',
    'matches',
    'system',
  ];

  bool _isInitialized = false;
  NotificationRouteTarget? _pendingRouteTarget;
  Timer? _pendingNavigationTimer;
  bool _isRoutingPendingTarget = false;
  int _pendingNavigationRetries = 0;
  static const int _maxPendingNavigationRetries = 25;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  StreamSubscription<RemoteMessage>? _messageOpenedSub;
  StreamSubscription<String>? _tokenRefreshSub;
  final Set<String> _handledRemoteTapKeys = <String>{};

  AuthService? get _authService =>
      Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;

  MonetizationService? get _monetizationService =>
      Get.isRegistered<MonetizationService>()
      ? Get.find<MonetizationService>()
      : null;

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool _isLikeType(String normalizedType) {
    return normalizedType == 'like' || normalizedType == 'who_liked_me';
  }

  bool _canRevealLikeIdentity() {
    final monetization = _monetizationService;
    if (monetization == null) {
      return false;
    }

    return monetization.hasWhoLikedMeAccess;
  }

  NotificationRouteTarget _resolveRouteTargetForNotification(
    NotificationModel notification,
  ) {
    return resolveNotificationRouteTarget(notification);
  }

  NotificationRouteTarget _resolveRouteTargetWithAccess(
    NotificationModel notification,
  ) {
    final target = _resolveRouteTargetForNotification(notification);
    final normalizedType = normalizeNotificationType(notification.type);
    if (_isLikeType(normalizedType) && !_canRevealLikeIdentity()) {
      return const NotificationRouteTarget.whoLikedMe();
    }
    return target;
  }

  String _presentationTitleForNotification(NotificationModel notification) {
    final normalizedType = normalizeNotificationType(notification.type);
    if (_isLikeType(normalizedType) && !_canRevealLikeIdentity()) {
      return 'notification_like_private_title'.tr;
    }

    final title = notification.title.trim();
    return title.isNotEmpty ? title : 'Notification';
  }

  String _presentationBodyForNotification(NotificationModel notification) {
    final normalizedType = normalizeNotificationType(notification.type);
    if (_isLikeType(normalizedType) && !_canRevealLikeIdentity()) {
      return 'notification_like_private_body'.tr;
    }

    return notification.body.trim();
  }

  Future<NotificationService> init() async {
    if (_isInitialized) return this;
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
    await _restoreLaunchNotificationTarget();
    _isInitialized = true;
    return this;
  }

  Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _localNotifications.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      await _createNotificationChannel();
    } catch (e) {
      debugPrint('[Notification] Error initializing local notifications: $e');
    }
  }

  Future<void> _createNotificationChannel() async {
    try {
      const androidChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    } catch (e) {
      debugPrint('[Notification] Failed to create notification channel: $e');
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    final firebaseReady = await initializeFirebaseIfAvailable();
    if (!firebaseReady) {
      debugPrint(
        '[Notification] Firebase Messaging disabled because Firebase is not configured.',
      );
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );

      _foregroundMessageSub?.cancel();
      _foregroundMessageSub = FirebaseMessaging.onMessage.listen(
        _handleForegroundRemoteMessage,
      );

      _messageOpenedSub?.cancel();
      _messageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _handleRemoteMessageTap(message),
      );

      await _syncFirebaseToken(messaging);

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessageTap(initialMessage, replaceExisting: false);
      }
    } catch (e) {
      debugPrint('[Notification] Firebase Messaging initialization failed: $e');
    }
  }

  Future<void> _syncFirebaseToken(FirebaseMessaging messaging) async {
    try {
      final token = await messaging.getToken();
      await _persistAndSyncPushToken(token);

      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onTokenRefresh.listen((nextToken) {
        unawaited(_persistAndSyncPushToken(nextToken));
      });
    } catch (e) {
      debugPrint('[Notification] Failed to retrieve Firebase token: $e');
    }
  }

  Future<void> ensurePushTokenSynced({bool force = false}) async {
    final firebaseReady = await initializeFirebaseIfAvailable();
    if (!firebaseReady) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      await _persistAndSyncPushToken(token, forceSync: force);
    } catch (e) {
      debugPrint('[Notification] ensurePushTokenSynced failed: $e');
    }
  }

  Future<void> _persistAndSyncPushToken(
    String? token, {
    bool forceSync = false,
  }) async {
    final normalized = token?.trim() ?? '';
    if (normalized.isEmpty) return;

    final cached = _storage.getString(_cachedFcmTokenKey)?.trim() ?? '';
    if (cached != normalized) {
      await _storage.saveString(_cachedFcmTokenKey, normalized);
    }

    final synced = _storage.getString(_syncedFcmTokenKey)?.trim() ?? '';
    if (!forceSync && synced == normalized) {
      return;
    }

    final auth = _authService;
    final isAuthenticated = auth?.isLoggedIn.value == true;
    if (!isAuthenticated) {
      debugPrint(
        '[Notification] Push token sync deferred until authenticated session is available.',
      );
      return;
    }

    final payload = <String, dynamic>{
      'token': normalized,
      'fcmToken': normalized,
      'platform': defaultTargetPlatform.name,
    };

    var syncedOnServer = false;

    try {
      await _api.post(ApiConstants.notificationDeviceToken, data: payload);
      debugPrint('[Notification] Push token synced via device-token endpoint.');
      syncedOnServer = true;
    } catch (e) {
      debugPrint('[Notification] device-token sync failed: $e');
    }

    if (!syncedOnServer) {
      try {
        await _api.patch(ApiConstants.usersMe, data: {'fcmToken': normalized});
        debugPrint('[Notification] Push token synced via usersMe fallback.');
        syncedOnServer = true;
      } catch (e) {
        debugPrint('[Notification] Push token fallback sync failed: $e');
      }
    }

    if (syncedOnServer) {
      await _storage.saveString(_syncedFcmTokenKey, normalized);
    }
  }

  Future<void> _handleForegroundRemoteMessage(RemoteMessage message) async {
    final notification = _notificationFromRemoteMessage(message);
    _recordIncomingNotification(notification);

    final title = _presentationTitleForNotification(notification);
    final body = _presentationBodyForNotification(notification);
    if (title.isEmpty && body.isEmpty) {
      return;
    }

    await showNotification(
      title: title,
      body: body,
      type: notification.type,
      data: notification.data,
    );
  }

  void _handleRemoteMessageTap(
    RemoteMessage message, {
    bool replaceExisting = true,
  }) {
    final notification = _notificationFromRemoteMessage(message);
    final tapKey = _remoteTapKey(message, notification);
    if (!_rememberRemoteTapKey(tapKey)) {
      debugPrint('[Notification] Duplicate remote tap ignored: $tapKey');
      return;
    }
    final target = _resolveRouteTargetWithAccess(notification);
    debugPrint(
      '[Notification] Remote message tapped: ${message.messageId ?? 'unknown'}, target=${target.type}, id=${target.id}',
    );
    _recordIncomingNotification(notification);
    markLocallyAsRead(notification);
    if (!notification.isRead && notification.id.trim().isNotEmpty) {
      unawaited(markAsRead(notification.id));
    }
    _queueRouteTarget(target, replaceExisting: replaceExisting);
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[Notification] Notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        final Map<String, dynamic> raw = jsonDecode(response.payload!);
        final notification = _parseNotificationPayload(raw);
        handleNotificationClick(notification);
      } catch (e) {
        debugPrint('[Notification] Error parsing tap payload: $e');
        _queueRouteTarget(const NotificationRouteTarget.notifications());
      }
    }
  }

  void handleNotificationClick(NotificationModel notification) {
    markLocallyAsRead(notification);
    if (!notification.isRead && notification.id.trim().isNotEmpty) {
      unawaited(markAsRead(notification.id));
    }

    final target = _resolveRouteTargetWithAccess(notification);
    debugPrint(
      '[Notification] Handling click for type: ${normalizeNotificationType(notification.type)}, target=${target.type}, id=${target.id}',
    );
    _queueRouteTarget(target);
  }

  void openNotificationFromInbox(NotificationModel notification) {
    markLocallyAsRead(notification);
    if (!notification.isRead && notification.id.trim().isNotEmpty) {
      unawaited(markAsRead(notification.id));
    }

    final target = _resolveRouteTargetWithAccess(notification);
    debugPrint(
      '[Notification] Opening from inbox: ${normalizeNotificationType(notification.type)}, target=${target.type}, id=${target.id}',
    );
    // Navigate directly without destroying nav stack — push on top of
    // the notifications screen so user can press back to return.
    unawaited(_navigateToTargetDirect(target));
  }

  /// Navigates directly to target by pushing the destination screen.
  /// Unlike [_navigateToTarget], this does NOT call [_ensureMainTab]
  /// / Get.offAllNamed, so the navigation stack is preserved.
  Future<bool> _navigateToTargetDirect(NotificationRouteTarget target) async {
    try {
      switch (target.type) {
        case NotificationRouteType.match:
          if (Get.currentRoute != AppRoutes.matchFound) {
            await Get.toNamed(AppRoutes.matchFound, arguments: target.payload);
          }
          return true;

        case NotificationRouteType.profile:
          final userId = target.id?.trim() ?? '';
          if (userId.isEmpty) return true;
          if (Get.isRegistered<UsersController>()) {
            unawaited(
              Get.find<UsersController>().openUserDetailById(
                userId,
                showLoader: true,
              ),
            );
            return true;
          }
          // Fallback: switch to main users tab and open
          return _navigateToTarget(target);

        case NotificationRouteType.chat:
          final conversationId = target.id?.trim() ?? '';
          if (conversationId.isNotEmpty && Get.isRegistered<ChatController>()) {
            unawaited(
              Get.find<ChatController>().openConversationById(
                conversationId,
                showLoader: true,
              ),
            );
            return true;
          }
          // No conversation id — just switch to chat tab
          if (Get.isRegistered<NavigationController>()) {
            Get.find<NavigationController>().changePage(2);
            Get.until((route) => Get.currentRoute == AppRoutes.main);
            return true;
          }
          return _navigateToTarget(target);

        case NotificationRouteType.subscription:
          if (Get.currentRoute != AppRoutes.subscription) {
            await Get.toNamed(AppRoutes.subscription);
          }
          return true;

        case NotificationRouteType.whoLikedMe:
          return _openUsersLikedMeTab();

        case NotificationRouteType.supportTicketDetails:
          await Get.toNamed(
            AppRoutes.contactSupport,
            arguments: {
              'initialTab': 1,
              'ticketId': target.id,
              'ticketPayload': target.payload,
            },
          );
          return true;

        case NotificationRouteType.verificationCenter:
          await Get.toNamed(AppRoutes.verificationCenter);
          return true;

        case NotificationRouteType.notifications:
          // Already on notifications screen — no-op
          return true;
      }
    } catch (e) {
      debugPrint('[Notification] Direct navigation failed: $e');
      // Fall back to the old method that rebuilds main
      return _navigateToTarget(target);
    }
  }

  Future<void> _restoreLaunchNotificationTarget() async {
    try {
      final details = await _localNotifications
          .getNotificationAppLaunchDetails();
      final launchedFromNotification =
          details?.didNotificationLaunchApp ?? false;
      final response = details?.notificationResponse;
      if (!launchedFromNotification || response?.payload == null) {
        return;
      }

      final raw = jsonDecode(response!.payload!);
      if (raw is! Map) return;
      final notification = _parseNotificationPayload(
        Map<String, dynamic>.from(raw),
      );
      _queueRouteTarget(
        _resolveRouteTargetWithAccess(notification),
        replaceExisting: false,
      );
    } catch (e) {
      debugPrint('[Notification] Failed to restore launch payload: $e');
    }
  }

  void processPendingLaunchNavigation() {
    _schedulePendingNavigation(const Duration(milliseconds: 120));
  }

  void _queueRouteTarget(
    NotificationRouteTarget target, {
    bool replaceExisting = true,
  }) {
    if (!replaceExisting && _pendingRouteTarget != null) {
      return;
    }
    _pendingRouteTarget = target;
    _schedulePendingNavigation();
  }

  void _schedulePendingNavigation([
    Duration delay = const Duration(milliseconds: 120),
  ]) {
    _pendingNavigationTimer?.cancel();
    _pendingNavigationTimer = Timer(delay, () {
      unawaited(_attemptPendingNavigation());
    });
  }

  String _remoteTapKey(RemoteMessage message, NotificationModel notification) {
    final messageId = message.messageId?.trim() ?? '';
    if (messageId.isNotEmpty) {
      return 'remote:$messageId';
    }

    final notificationId = notification.id.trim();
    if (notificationId.isNotEmpty) {
      return 'notification:$notificationId';
    }

    return [
      notification.type.trim().toLowerCase(),
      notification.userId.trim(),
      notification.title.trim(),
      notification.body.trim(),
      notification.createdAt.toIso8601String(),
    ].join('|');
  }

  bool _rememberRemoteTapKey(String key) {
    if (key.isEmpty) return true;
    if (_handledRemoteTapKeys.contains(key)) {
      return false;
    }

    _handledRemoteTapKeys.add(key);
    if (_handledRemoteTapKeys.length > 96) {
      _handledRemoteTapKeys.remove(_handledRemoteTapKeys.first);
    }
    return true;
  }

  Future<void> _attemptPendingNavigation() async {
    final target = _pendingRouteTarget;
    if (target == null || _isRoutingPendingTarget) return;
    final redirectedToAccountStatus =
        await _redirectToRestrictedAccountIfNeeded();
    if (redirectedToAccountStatus) {
      if (identical(_pendingRouteTarget, target)) {
        _pendingRouteTarget = null;
      }
      return;
    }
    if (!_canAttemptPendingNavigation()) {
      _pendingNavigationRetries++;
      if (_pendingNavigationRetries > _maxPendingNavigationRetries) {
        debugPrint(
          '[Notification] Max navigation retries reached, dropping pending target',
        );
        _pendingRouteTarget = null;
        _pendingNavigationRetries = 0;
        return;
      }
      _schedulePendingNavigation(const Duration(milliseconds: 160));
      return;
    }
    _pendingNavigationRetries = 0;

    _isRoutingPendingTarget = true;
    try {
      final handled = await _navigateToTarget(target);
      if (handled && identical(_pendingRouteTarget, target)) {
        _pendingRouteTarget = null;
      } else if (!handled) {
        _schedulePendingNavigation(const Duration(milliseconds: 180));
      }
    } catch (e) {
      debugPrint('[Notification] Pending navigation error: $e');
      _schedulePendingNavigation(const Duration(milliseconds: 220));
    } finally {
      _isRoutingPendingTarget = false;
    }
  }

  bool _canAttemptPendingNavigation() {
    final auth = _authService;
    if (Get.context == null) return false;
    if (Get.currentRoute.isEmpty || Get.currentRoute == AppRoutes.splash) {
      return false;
    }
    if (auth == null) return false;
    if (auth.sessionRestorePending.value) return false;
    if (!auth.isLoggedIn.value) {
      if (Get.currentRoute == AppRoutes.login ||
          Get.currentRoute == AppRoutes.onboarding ||
          Get.currentRoute == AppRoutes.accountStatus ||
          Get.currentRoute == AppRoutes.contactSupport) {
        _pendingRouteTarget = null;
      }
      return false;
    }
    return true;
  }

  Future<bool> _redirectToRestrictedAccountIfNeeded() async {
    final auth = _authService;
    if (auth == null) return false;
    final currentUser = auth.currentUser.value;
    final args = buildRestrictedAccountArguments(currentUser);
    if (args == null) return false;

    final status = (args['status']?.toString().trim().toLowerCase() ?? '');
    if (status == 'suspended') {
      return false;
    }

    final targetRoute = status == 'banned'
        ? AppRoutes.contactSupport
        : AppRoutes.accountStatus;

    if (Get.currentRoute != targetRoute) {
      try {
        await Get.offAllNamed(targetRoute, arguments: args);
      } catch (e) {
        debugPrint(
          '[Notification] Failed to open restricted account screen: $e',
        );
      }
    }
    return true;
  }

  Future<bool> _navigateToTarget(NotificationRouteTarget target) async {
    switch (target.type) {
      case NotificationRouteType.match:
        if (Get.currentRoute != AppRoutes.matchFound) {
          await Get.toNamed(AppRoutes.matchFound, arguments: target.payload);
        }
        return true;

      case NotificationRouteType.profile:
        final userId = target.id?.trim() ?? '';
        if (userId.isEmpty) {
          return _navigateToNotificationsInbox();
        }
        try {
          await _ensureMainTab(1);
          await Future.delayed(const Duration(milliseconds: 150));
          if (!Get.isRegistered<UsersController>()) return false;
          unawaited(
            Get.find<UsersController>().openUserDetailById(
              userId,
              showLoader: true,
            ),
          );
          return true;
        } catch (e) {
          debugPrint('[Notification] Failed to open user profile: $e');
          return false;
        }

      case NotificationRouteType.chat:
        final conversationId = target.id?.trim() ?? '';
        try {
          await _ensureMainTab(2);
          await Future.delayed(const Duration(milliseconds: 150));
          if (conversationId.isNotEmpty && Get.isRegistered<ChatController>()) {
            debugPrint(
              '[Notification] Opening conversation from notification: $conversationId',
            );
            unawaited(
              Get.find<ChatController>().openConversationById(
                conversationId,
                showLoader: true,
              ),
            );
          }
          return true;
        } catch (e) {
          debugPrint('[Notification] Failed to open chat: $e');
          return false;
        }

      case NotificationRouteType.subscription:
        if (Get.currentRoute != AppRoutes.subscription) {
          await Get.toNamed(AppRoutes.subscription);
        }
        return true;

      case NotificationRouteType.whoLikedMe:
        return _openUsersLikedMeTab();

      case NotificationRouteType.supportTicketDetails:
        await Get.toNamed(
          AppRoutes.contactSupport,
          arguments: {
            'initialTab': 1,
            'ticketId': target.id,
            'ticketPayload': target.payload,
          },
        );
        return true;

      case NotificationRouteType.verificationCenter:
        await Get.toNamed(AppRoutes.verificationCenter);
        return true;

      case NotificationRouteType.notifications:
        return _navigateToNotificationsInbox();
    }
  }

  Future<bool> _navigateToNotificationsInbox() async {
    try {
      if (Get.currentRoute != AppRoutes.notifications) {
        await Get.toNamed(AppRoutes.notifications);
      }
      return true;
    } catch (e) {
      debugPrint('[Notification] Failed to open notifications inbox: $e');
      return false;
    }
  }

  Future<bool> _openUsersLikedMeTab() async {
    try {
      if (Get.currentRoute == AppRoutes.notifications) {
        Get.until(
          (route) => route.settings.name == AppRoutes.main || route.isFirst,
        );
      }

      await _ensureMainTab(1);
      for (int i = 0; i < 10 && !Get.isRegistered<UsersController>(); i++) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      if (!Get.isRegistered<UsersController>()) {
        return false;
      }

      final usersController = Get.find<UsersController>();
      usersController.requestUsersTab(1, forceRefresh: true);
      return true;
    } catch (e) {
      debugPrint('[Notification] Failed to open Users > Liked Me tab: $e');
      return false;
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
        payload: jsonEncode({
          'id': '',
          'userId': '',
          'type': type ?? 'system',
          'title': title,
          'body': body,
          'data': data ?? <String, dynamic>{},
          'isRead': false,
          'createdAt': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('[Notification] Failed to show notification: $e');
    }
  }

  NotificationModel _parseNotificationPayload(Map<String, dynamic> raw) {
    final hasStructuredFields =
        raw.containsKey('title') ||
        raw.containsKey('body') ||
        raw.containsKey('data') ||
        raw.containsKey('createdAt') ||
        raw.containsKey('id') ||
        raw.containsKey('userId') ||
        raw.containsKey('isRead');

    if (hasStructuredFields) {
      return NotificationModel.fromJson(raw);
    }

    final type = (raw['type'] ?? 'system').toString();
    final data = Map<String, dynamic>.from(raw)..remove('type');

    return NotificationModel(
      id: raw['id']?.toString() ?? '',
      userId: raw['userId']?.toString() ?? '',
      type: type,
      title: raw['title']?.toString() ?? 'Notification',
      body: raw['body']?.toString() ?? '',
      data: data.isEmpty ? null : data,
      isRead: raw['isRead'] == true,
      createdAt:
          DateTime.tryParse(raw['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  NotificationModel _notificationFromRemoteMessage(RemoteMessage message) {
    final normalizedData = _normalizeRemoteDataMap(message.data);
    final type =
        _firstNonEmpty([
          normalizedData['type'],
          normalizedData['notificationType'],
          normalizedData['notification_type'],
          normalizedData['event'],
        ]) ??
        'system';

    final title =
        _firstNonEmpty([
          normalizedData['title'],
          normalizedData['notificationTitle'],
          normalizedData['notification_title'],
          message.notification?.title,
        ]) ??
        'Notification';

    final body =
        _firstNonEmpty([
          normalizedData['body'],
          normalizedData['message'],
          normalizedData['notificationBody'],
          normalizedData['notification_body'],
          message.notification?.body,
        ]) ??
        '';

    return NotificationModel(
      id:
          _firstNonEmpty([
            normalizedData['id'],
            normalizedData['notificationId'],
            normalizedData['notification_id'],
            message.messageId,
          ]) ??
          '',
      userId:
          _firstNonEmpty([
            normalizedData['userId'],
            normalizedData['user_id'],
            normalizedData['targetUserId'],
            normalizedData['target_user_id'],
          ]) ??
          '',
      type: type,
      title: title,
      body: body,
      data: normalizedData.isEmpty ? null : normalizedData,
      isRead: false,
      createdAt:
          DateTime.tryParse(
            _firstNonEmpty([
                  normalizedData['createdAt'],
                  normalizedData['created_at'],
                  normalizedData['timestamp'],
                ]) ??
                '',
          ) ??
          message.sentTime ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> _normalizeRemoteDataMap(Map<String, dynamic> raw) {
    final normalized = <String, dynamic>{};

    raw.forEach((key, value) {
      normalized[key] = _decodeStructuredValue(value);
    });

    final nestedData = normalized['data'];
    if (nestedData is Map) {
      final nestedMap = Map<String, dynamic>.from(nestedData);
      for (final entry in nestedMap.entries) {
        normalized.putIfAbsent(
          entry.key,
          () => _decodeStructuredValue(entry.value),
        );
      }
    }

    return normalized;
  }

  dynamic _decodeStructuredValue(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
        try {
          return jsonDecode(trimmed);
        } catch (_) {
          return value;
        }
      }
    }
    return value;
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final normalized = value?.toString().trim() ?? '';
      if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
        return normalized;
      }
    }
    return null;
  }

  void _recordIncomingNotification(NotificationModel notification) {
    final id = notification.id.trim();
    if (id.isNotEmpty) {
      final existingIndex = notifications.indexWhere((item) => item.id == id);
      if (existingIndex != -1) {
        notifications[existingIndex] = notification;
        notifications.refresh();
        _updateUnreadCount();
        return;
      }
    }

    notifications.insert(0, notification);
    _updateUnreadCount();
  }

  List<Map<String, dynamic>> _extractNotificationMaps(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (data is Map) {
      const candidateKeys = ['notifications', 'data', 'items', 'results'];
      for (final key in candidateKeys) {
        final value = data[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }

      if (data['data'] is Map) {
        return _extractNotificationMaps(data['data']);
      }
    }

    return const <Map<String, dynamic>>[];
  }

  bool _containsNotificationListShape(dynamic data) {
    if (data is List) return true;
    if (data is Map) {
      const candidateKeys = ['notifications', 'data', 'items', 'results'];
      for (final key in candidateKeys) {
        final value = data[key];
        if (value is List) return true;
      }
      if (data['data'] is Map || data['data'] is List) {
        return _containsNotificationListShape(data['data']);
      }
    }
    return false;
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await _api.get(ApiConstants.notifications);
      final rawNotifications = _extractNotificationMaps(response.data);
      final hasListShape = _containsNotificationListShape(response.data);

      if (rawNotifications.isNotEmpty || hasListShape) {
        final fetchedNotifications =
            rawNotifications.map(NotificationModel.fromJson).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifications.assignAll(fetchedNotifications);
        _updateUnreadCount();
      } else if (response.data is Map && response.data['unreadCount'] != null) {
        unreadCount.value = _toInt(response.data['unreadCount']);
        hasUnreadNotifications.value = unreadCount.value > 0;
      }
    } catch (e) {
      debugPrint('[Notification] Failed to fetch notifications: $e');
    }
  }

  Future<void> fetchUnreadCount() async {
    final route = Get.currentRoute;
    if (route.contains('signup') || route == AppRoutes.splash || route == '') {
      return;
    }

    try {
      final response = await _api.get(ApiConstants.notificationsUnreadCount);
      final payload = response.data;
      if (payload is Map &&
          (payload['unreadCount'] != null || payload['count'] != null)) {
        unreadCount.value = _toInt(payload['unreadCount'] ?? payload['count']);
        hasUnreadNotifications.value = unreadCount.value > 0;
      }
    } catch (e) {
      debugPrint('[Notification] Failed to fetch unread count: $e');
      unreadCount.value = 0;
      hasUnreadNotifications.value = false;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final normalizedId = notificationId.trim();
    if (normalizedId.isEmpty) return;

    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !notifications[index].isRead) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      notifications.refresh();
      _updateUnreadCount();
    }

    try {
      await _api.patch('${ApiConstants.notifications}/$notificationId/read');
    } catch (e) {
      debugPrint(
        '[Notification] Failed to mark notification as read on server: $e',
      );
    }
  }

  void markLocallyAsRead(NotificationModel notification) {
    final normalizedId = notification.id.trim();
    final index = notifications.indexWhere((item) {
      if (normalizedId.isNotEmpty) {
        return item.id == normalizedId;
      }

      return item.title == notification.title &&
          item.body == notification.body &&
          item.createdAt == notification.createdAt;
    });

    if (index == -1 || notifications[index].isRead) return;
    notifications[index] = notifications[index].copyWith(isRead: true);
    notifications.refresh();
    _updateUnreadCount();
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.patch(ApiConstants.markAllNotificationsRead);

      notifications.value = notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();
      notifications.refresh();
      unreadCount.value = 0;
      hasUnreadNotifications.value = false;
    } catch (e) {
      debugPrint('[Notification] Failed to mark all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final normalizedId = notificationId.trim();
    if (normalizedId.isEmpty) return;

    try {
      await _api.delete(ApiConstants.deleteNotification(normalizedId));

      notifications.removeWhere((n) => n.id == normalizedId);
      _updateUnreadCount();
    } catch (e) {
      debugPrint('[Notification] Failed to delete notification: $e');
    }
  }

  Future<void> deleteNotificationEntry(NotificationModel notification) async {
    final normalizedId = notification.id.trim();

    if (normalizedId.isEmpty) {
      notifications.removeWhere(
        (item) =>
            item.id.trim().isEmpty &&
            item.title == notification.title &&
            item.body == notification.body &&
            item.createdAt == notification.createdAt,
      );
      _updateUnreadCount();
      return;
    }

    await deleteNotification(normalizedId);
  }

  Future<bool> clearAllNotifications() async {
    final existing = List<NotificationModel>.from(notifications);
    if (existing.isEmpty) {
      return true;
    }

    final ids = existing
        .map((item) => item.id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    if (ids.isEmpty) {
      notifications.clear();
      _updateUnreadCount();
      return true;
    }

    try {
      await _api.delete(ApiConstants.notifications);
      notifications.clear();
      _updateUnreadCount();
      return true;
    } catch (e) {
      debugPrint(
        '[Notification] Bulk clear failed, falling back to one-by-one delete: $e',
      );
    }

    final failedIds = <String>{};
    for (final id in ids) {
      try {
        await _api.delete(ApiConstants.deleteNotification(id));
      } catch (_) {
        failedIds.add(id);
      }
    }

    if (failedIds.isEmpty) {
      notifications.clear();
      _updateUnreadCount();
      return true;
    }

    notifications.removeWhere((item) {
      final id = item.id.trim();
      if (id.isEmpty) return true;
      return !failedIds.contains(id);
    });
    _updateUnreadCount();
    return false;
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
    hasUnreadNotifications.value = unreadCount.value > 0;
  }

  List<NotificationModel> get filteredNotifications {
    final selected = selectedCategory.value.toLowerCase();
    if (selected == 'all') return notifications;

    return notifications.where((n) {
      final type = normalizeNotificationType(n.type);
      switch (selected) {
        case 'matches':
          return type == 'match';
        case 'likes':
          return type == 'like';
        case 'passes':
          return type == 'dislike';
        case 'messages':
          return type == 'message';
        case 'compliments':
          return type == 'compliment';
        case 'system':
          return type == 'system' ||
              type == 'subscription' ||
              type == 'verification';
        default:
          return true;
      }
    }).toList();
  }

  void setCategory(String category) {
    selectedCategory.value = category;
  }

  void openNotifications() {
    unawaited(Get.toNamed(AppRoutes.notifications));
  }

  Future<void> _ensureMainTab(int index) async {
    if (Get.currentRoute != AppRoutes.main) {
      await Get.offAllNamed(AppRoutes.main);
      // Wait for bindings to register after route transition
      for (
        int i = 0;
        i < 10 && !Get.isRegistered<NavigationController>();
        i++
      ) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    if (!Get.isRegistered<NavigationController>()) return;
    Get.find<NavigationController>().changePage(index);
  }

  @override
  void onClose() {
    _pendingNavigationTimer?.cancel();
    _foregroundMessageSub?.cancel();
    _messageOpenedSub?.cancel();
    _tokenRefreshSub?.cancel();
    super.onClose();
  }

  void clearAll() {
    _pendingNavigationTimer?.cancel();
    _pendingRouteTarget = null;
    _pendingNavigationRetries = 0;
    _handledRemoteTapKeys.clear();
    notifications.clear();
    unreadCount.value = 0;
    hasUnreadNotifications.value = false;
  }
}
