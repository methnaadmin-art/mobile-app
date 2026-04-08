import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/models/notification_model.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/controllers/chat_controller.dart';
import 'package:methna_app/app/controllers/navigation_controller.dart';
import 'package:methna_app/app/controllers/users_controller.dart';

class NotificationService extends GetxService {
  final ApiService _api = Get.find<ApiService>();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

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

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<NotificationService> init() async {
    if (_isInitialized) return this;
    await _initializeLocalNotifications();
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

  String _normalizeType(String type) {
    final normalized = type.trim().toLowerCase();
    switch (normalized) {
      case 'new_match':
      case 'matched':
      case 'new match':
        return 'match';
      case 'superlike':
      case 'super_like':
        return 'like';
      case 'pass':
      case 'dislike':
      case 'swipe_left':
        return 'dislike';
      case 'compliment_sent':
      case 'compliment_received':
        return 'compliment';
      case 'msg':
      case 'chat':
        return 'message';
      case 'profile_view':
        return 'visit';
      default:
        return normalized;
    }
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
        Get.toNamed(AppRoutes.notifications);
      }
    }
  }

  void handleNotificationClick(NotificationModel notification) {
    if (!notification.isRead) {
      markAsRead(notification.id);
    }

    final type = _normalizeType(notification.type);
    final data = notification.data;
    debugPrint('[Notification] Handling click for type: $type, data: $data');

    try {
      switch (type) {
        case 'message':
          final convId = (data?['conversationId'] ?? data?['chatId'])
              ?.toString();
          if (convId != null && convId.isNotEmpty) {
            Get.find<ChatController>().openConversationById(convId);
          } else {
            _openMainTab(2);
          }
          break;

        case 'match':
          final conversationId =
              (data?['conversationId'] ?? data?['chatId'])?.toString();
          final matchId = data?['matchId']?.toString();
          if (conversationId != null && conversationId.isNotEmpty) {
            Get.find<ChatController>().openConversationById(conversationId);
          } else if (matchId != null && matchId.isNotEmpty) {
            Get.find<ChatController>().openConversationByMatchId(matchId);
          } else {
            final matchedUserId =
                (data?['userId'] ?? data?['targetUserId'])?.toString();
            if (matchedUserId != null && matchedUserId.isNotEmpty) {
              Get.find<UsersController>().openUserDetailById(matchedUserId);
            } else {
              _openMainTab(2);
            }
          }
          break;

        case 'like':
        case 'compliment':
        case 'dislike':
          final targetUserId =
              (data?['likerId'] ??
                      data?['requesterId'] ??
                      data?['targetUserId'] ??
                      data?['userId'])
                  ?.toString();
          if (targetUserId != null && targetUserId.isNotEmpty) {
            Get.find<UsersController>().openUserDetailById(targetUserId);
          } else {
            Get.toNamed(AppRoutes.notifications);
          }
          break;

        case 'rematch':
          Get.toNamed(AppRoutes.notifications);
          break;

        default:
          if (Get.currentRoute != AppRoutes.notifications) {
            Get.toNamed(AppRoutes.notifications);
          }
          break;
      }
    } catch (e) {
      debugPrint('[Notification] Navigation error: $e');
      Get.toNamed(AppRoutes.notifications);
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
    try {
      await _api.delete('${ApiConstants.notifications}/$notificationId');

      notifications.removeWhere((n) => n.id == notificationId);
      _updateUnreadCount();
    } catch (e) {
      debugPrint('[Notification] Failed to delete notification: $e');
    }
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
    hasUnreadNotifications.value = unreadCount.value > 0;
  }

  List<NotificationModel> get filteredNotifications {
    final selected = selectedCategory.value.toLowerCase();
    if (selected == 'all') return notifications;

    return notifications.where((n) {
      final type = _normalizeType(n.type);
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
    Get.toNamed(AppRoutes.notifications);
  }

  void _openMainTab(int index) {
    if (Get.currentRoute != AppRoutes.main) {
      Get.offAllNamed(AppRoutes.main);
    }

    Future.delayed(const Duration(milliseconds: 150), () {
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().changePage(index);
      }
    });
  }

  void clearAll() {
    notifications.clear();
    unreadCount.value = 0;
    hasUnreadNotifications.value = false;
  }
}
