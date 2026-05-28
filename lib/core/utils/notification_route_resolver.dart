import 'dart:convert';

import 'package:methna_app/app/data/models/notification_model.dart';

enum NotificationRouteType {
  match,
  profile,
  chat,
  notifications,
  whoLikedMe,
  subscription,
  supportTicketDetails,
  verificationCenter,
}

class NotificationRouteTarget {
  const NotificationRouteTarget._({required this.type, this.id, this.payload});

  const NotificationRouteTarget.match({Map<String, dynamic>? payload})
    : this._(type: NotificationRouteType.match, payload: payload);

  const NotificationRouteTarget.profile(String userId)
    : this._(type: NotificationRouteType.profile, id: userId);

  const NotificationRouteTarget.chat([String? conversationId])
    : this._(type: NotificationRouteType.chat, id: conversationId);

  const NotificationRouteTarget.notifications()
    : this._(type: NotificationRouteType.notifications);

  const NotificationRouteTarget.whoLikedMe()
    : this._(type: NotificationRouteType.whoLikedMe);

  const NotificationRouteTarget.subscription()
    : this._(type: NotificationRouteType.subscription);

  const NotificationRouteTarget.supportTicketDetails({
    String? ticketId,
    Map<String, dynamic>? payload,
  }) : this._(
         type: NotificationRouteType.supportTicketDetails,
         id: ticketId,
         payload: payload,
       );

  const NotificationRouteTarget.verificationCenter({
    Map<String, dynamic>? payload,
  }) : this._(type: NotificationRouteType.verificationCenter, payload: payload);

  final NotificationRouteType type;
  final String? id;
  final Map<String, dynamic>? payload;
}

String normalizeNotificationType(String type) {
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
    case 'new_message':
    case 'message_received':
      return 'message';
    case 'new_like':
    case 'like_received':
    case 'liked_you':
      return 'like';
    case 'who_liked_me':
    case 'likes_received':
      return 'who_liked_me';
    case 'premium':
    case 'membership':
    case 'billing':
    case 'payment':
    case 'subscription_update':
      return 'subscription';
    case 'support':
    case 'help':
    case 'ticket':
    case 'support_ticket':
    case 'ticket_update':
    case 'support_reply':
      return 'ticket';
    case 'profile_view':
      return 'visit';
    case 'verification':
    case 'verification_update':
    case 'selfie_verification':
    case 'marital_verification':
    case 'identity_verification':
      return 'verification';
    default:
      return normalized;
  }
}

NotificationRouteTarget resolveNotificationRouteTarget(
  NotificationModel notification,
) {
  final type = normalizeNotificationType(notification.type);
  final data = _asMap(notification.data);

  switch (type) {
    case 'message':
      final conversationId = _firstNonEmpty([
        data?['conversationId'],
        data?['chatId'],
        data?['conversation_id'],
        data?['chat_id'],
        _nestedId(data?['conversation']),
        _nestedId(data?['chat']),
      ]);
      return NotificationRouteTarget.chat(conversationId);

    case 'match':
      return NotificationRouteTarget.match(payload: data);

    case 'who_liked_me':
      return const NotificationRouteTarget.whoLikedMe();

    case 'like':
    case 'compliment':
    case 'dislike':
    case 'visit':
      final targetUserId = _firstNonEmpty([
        data?['likerId'],
        data?['requesterId'],
        data?['targetUserId'],
        data?['matchedUserId'],
        data?['userId'],
        data?['senderId'],
        data?['actorId'],
        _nestedId(data?['user']),
        _nestedId(data?['sender']),
        _nestedId(data?['actor']),
      ]);
      if (targetUserId != null) {
        return NotificationRouteTarget.profile(targetUserId);
      }

      if (type == 'like' || type == 'compliment') {
        return const NotificationRouteTarget.whoLikedMe();
      }

      return const NotificationRouteTarget.notifications();

    case 'subscription':
      return const NotificationRouteTarget.subscription();

    case 'ticket':
      final ticketId = _firstNonEmpty([
        data?['ticketId'],
        data?['ticket_id'],
        data?['id'],
        _nestedId(data?['ticket']),
      ]);
      return NotificationRouteTarget.supportTicketDetails(
        ticketId: ticketId,
        payload: data,
      );

    case 'verification':
      return NotificationRouteTarget.verificationCenter(payload: data);

    default:
      return const NotificationRouteTarget.notifications();
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
  }
  return null;
}

String? _nestedId(dynamic value) {
  final map = _asMap(value);
  if (map == null) return null;
  return _firstNonEmpty([map['id'], map['_id'], map['userId']]);
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
