import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<bool> initializeFirebaseIfAvailable() async {
  try {
    if (Firebase.apps.isNotEmpty) {
      return true;
    }
  } catch (_) {}

  try {
    await Firebase.initializeApp();
    return true;
  } catch (e) {
    debugPrint('[Firebase] Initialization skipped: $e');
    return false;
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialized = await initializeFirebaseIfAvailable();
  if (!initialized) {
    debugPrint(
      '[Firebase] Background message ignored because Firebase is not configured.',
    );
    return;
  }

  debugPrint(
    '[Firebase] Background message received: ${message.messageId ?? 'unknown'}',
  );

  // If the message has a notification payload, the OS will display it
  // automatically. Only show a local notification for data-only messages.
  if (message.notification != null) return;

  final data = message.data;
  final title = _extractField(data, ['title', 'notificationTitle', 'notification_title']) ??
      'Methna';
  final body = _extractField(data, ['body', 'message', 'notificationBody', 'notification_body']) ??
      '';
  if (title.isEmpty && body.isEmpty) return;

  try {
    final localNotifications = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

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

    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode({
        'type': data['type'] ?? data['notificationType'] ?? 'system',
        'title': title,
        'body': body,
        'data': data,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );
  } catch (e) {
    debugPrint('[Firebase] Failed to show background notification: $e');
  }
}

String? _extractField(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key]?.toString().trim() ?? '';
    if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
  }
  return null;
}
