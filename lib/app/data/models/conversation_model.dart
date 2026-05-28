import 'user_model.dart';

Map<String, dynamic>? _mapOrNull(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _stringValue(dynamic value) {
  if (value == null) return '';
  if (value is String) return value.trim();
  if (value is num || value is bool) return value.toString();
  return '';
}

String _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    final parsed = _stringValue(value);
    if (parsed.isNotEmpty) return parsed;
  }
  return '';
}

DateTime? _parseDate(dynamic value) {
  final raw = _stringValue(value);
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

List<Map<String, dynamic>> _mapListOrEmpty(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .map((entry) => _mapOrNull(entry))
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

class ConversationModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? matchId;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final int user1UnreadCount;
  final int user2UnreadCount;
  final bool isActive;
  final bool isLocked;
  final String? lockReason;
  final DateTime createdAt;
  final UserModel? otherUser;

  ConversationModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.matchId,
    this.lastMessageContent,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.user1UnreadCount = 0,
    this.user2UnreadCount = 0,
    this.isActive = true,
    this.isLocked = false,
    this.lockReason,
    required this.createdAt,
    this.otherUser,
  });

  factory ConversationModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final raw = Map<String, dynamic>.from(json);
    final user1Map = _mapOrNull(raw['user1']);
    final user2Map = _mapOrNull(raw['user2']);
    final lastMessageMap = _mapOrNull(raw['lastMessage']);

    final participants = <Map<String, dynamic>>[
      ..._mapListOrEmpty(raw['participants']),
      ..._mapListOrEmpty(raw['users']),
      ..._mapListOrEmpty(raw['members']),
      ..._mapListOrEmpty(raw['participantUsers']),
    ];

    final id = _firstNonEmpty([
      raw['id'],
      raw['_id'],
      raw['conversationId'],
      raw['conversation_id'],
    ]);

    final user1Id = _firstNonEmpty([
      raw['user1Id'],
      raw['user1_id'],
      user1Map?['id'],
      user1Map?['_id'],
      user1Map?['userId'],
      user1Map?['user_id'],
      participants.isNotEmpty ? participants.first['id'] : null,
      participants.isNotEmpty ? participants.first['_id'] : null,
    ]);
    final user2Id = _firstNonEmpty([
      raw['user2Id'],
      raw['user2_id'],
      user2Map?['id'],
      user2Map?['_id'],
      user2Map?['userId'],
      user2Map?['user_id'],
      participants.length > 1 ? participants[1]['id'] : null,
      participants.length > 1 ? participants[1]['_id'] : null,
    ]);

    UserModel? parseCandidate(dynamic candidate) {
      final map = _mapOrNull(candidate);
      if (map != null) {
        final user = UserModel.fromApiEntry(map);
        if (user.id.isNotEmpty && user.id != currentUserId) {
          return user;
        }
      }

      final asId = _stringValue(candidate);
      if (asId.isNotEmpty && asId != currentUserId) {
        final user = UserModel.fromApiEntry({'id': asId});
        if (user.id.isNotEmpty) return user;
      }

      return null;
    }

    UserModel? other;

    final candidateKeys = <dynamic>[
      raw['otherUser'],
      raw['other_user'],
      raw['targetUser'],
      raw['target_user'],
      raw['matchedUser'],
      raw['matched_user'],
      raw['participant'],
      raw['participantUser'],
      raw['participant_user'],
      raw['chatUser'],
      raw['chat_user'],
      raw['remoteUser'],
      raw['remote_user'],
      raw['user'],
    ];

    for (final candidate in candidateKeys) {
      other = parseCandidate(candidate);
      if (other != null) break;
    }

    if (other == null && participants.isNotEmpty) {
      final picked = participants
          .map(UserModel.fromApiEntry)
          .firstWhere(
            (user) => user.id.isNotEmpty && user.id != currentUserId,
            orElse: () => UserModel.fromApiEntry(const <String, dynamic>{}),
          );
      if (picked.id.isNotEmpty) {
        other = picked;
      }
    }

    if (other == null && currentUserId != null) {
      final u1 = parseCandidate(user1Map);
      final u2 = parseCandidate(user2Map);
      if (u1 != null && u1.id != currentUserId) {
        other = u1;
      } else if (u2 != null && u2.id != currentUserId) {
        other = u2;
      }
    }

    final inferredOtherUserId = _firstNonEmpty([
      raw['otherUserId'],
      raw['other_user_id'],
      raw['targetUserId'],
      raw['target_user_id'],
      raw['participantId'],
      raw['participant_id'],
      if (currentUserId != null && user1Id == currentUserId) user2Id,
      if (currentUserId != null && user2Id == currentUserId) user1Id,
      if (currentUserId == null) user1Id,
      if (currentUserId == null && user2Id.isNotEmpty) user2Id,
    ]);

    if (other == null && inferredOtherUserId.isNotEmpty) {
      final synthetic = <String, dynamic>{
        'id': inferredOtherUserId,
        'firstName': _firstNonEmpty([
          raw['otherUserFirstName'],
          raw['other_user_first_name'],
          raw['participantFirstName'],
          raw['participant_first_name'],
        ]),
        'lastName': _firstNonEmpty([
          raw['otherUserLastName'],
          raw['other_user_last_name'],
          raw['participantLastName'],
          raw['participant_last_name'],
        ]),
        'username': _firstNonEmpty([
          raw['otherUserName'],
          raw['other_user_name'],
          raw['participantName'],
          raw['participant_name'],
          raw['targetUserName'],
          raw['target_user_name'],
        ]),
        'mainPhotoUrl': _firstNonEmpty([
          raw['otherUserPhotoUrl'],
          raw['other_user_photo_url'],
          raw['otherUserAvatarUrl'],
          raw['other_user_avatar_url'],
          raw['participantPhotoUrl'],
          raw['participant_photo_url'],
          raw['targetUserPhotoUrl'],
          raw['target_user_photo_url'],
          raw['photoUrl'],
          raw['avatarUrl'],
          raw['mainPhotoUrl'],
        ]),
      };

      final fallback = UserModel.fromApiEntry(synthetic);
      if (fallback.id.isNotEmpty) {
        other = fallback;
      }
    }

    // Handle both direct fields and enriched format for unread/lastMessage.
    var unread1 = _parseInt(raw['user1UnreadCount']);
    if (unread1 == 0) unread1 = _parseInt(raw['user1_unread_count']);
    var unread2 = _parseInt(raw['user2UnreadCount']);
    if (unread2 == 0) unread2 = _parseInt(raw['user2_unread_count']);
    var enrichedUnread = _parseInt(raw['unreadCount']);
    if (enrichedUnread == 0) {
      enrichedUnread = _parseInt(raw['unread_count']);
    }
    if (enrichedUnread == 0) {
      enrichedUnread = _parseInt(raw['newMessagesCount']);
    }

    // If backend returns only a single unread count, map it to current user side.
    if (enrichedUnread > 0 && unread1 == 0 && unread2 == 0) {
      if (currentUserId != null && currentUserId == user2Id) {
        unread2 = enrichedUnread;
      } else {
        unread1 = enrichedUnread;
      }
    }

    return ConversationModel(
      id: id,
      user1Id: user1Id,
      user2Id: user2Id,
      matchId: _firstNonEmpty([raw['matchId'], raw['match_id']]),
      lastMessageContent: _firstNonEmpty([
        raw['lastMessageContent'],
        raw['last_message_content'],
        raw['lastMessageText'],
        raw['last_message_text'],
        raw['lastMessage'],
        lastMessageMap?['content'],
        lastMessageMap?['text'],
        lastMessageMap?['body'],
      ]),
      lastMessageAt:
          _parseDate(raw['lastMessageAt']) ??
          _parseDate(raw['last_message_at']) ??
          _parseDate(raw['lastMessageCreatedAt']) ??
          _parseDate(raw['last_message_created_at']) ??
          _parseDate(lastMessageMap?['createdAt']) ??
          _parseDate(lastMessageMap?['created_at']) ??
          _parseDate(raw['updatedAt']) ??
          _parseDate(raw['updated_at']),
      lastMessageSenderId: _firstNonEmpty([
        raw['lastMessageSenderId'],
        raw['last_message_sender_id'],
        lastMessageMap?['senderId'],
        lastMessageMap?['sender_id'],
      ]),
      user1UnreadCount: unread1,
      user2UnreadCount: unread2,
      isActive: raw['isActive'] == null ? true : raw['isActive'] == true,
      isLocked: raw['isLocked'] == true,
      lockReason: _firstNonEmpty([raw['lockReason'], raw['lock_reason']]),
      createdAt:
          _parseDate(raw['createdAt']) ??
          _parseDate(raw['created_at']) ??
          DateTime.now(),
      otherUser: other,
    );
  }

  int unreadCount(String currentUserId) =>
      currentUserId == user1Id ? user1UnreadCount : user2UnreadCount;

  bool get hasUnread => user1UnreadCount > 0 || user2UnreadCount > 0;

  ConversationModel copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    String? matchId,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
    int? unreadCount,
    String? currentUserId,
    int? user1UnreadCount,
    int? user2UnreadCount,
    bool? isActive,
    bool? isLocked,
    String? lockReason,
    DateTime? createdAt,
    UserModel? otherUser,
  }) {
    var nextUser1Unread = user1UnreadCount ?? this.user1UnreadCount;
    var nextUser2Unread = user2UnreadCount ?? this.user2UnreadCount;

    if (unreadCount != null) {
      if (currentUserId != null && currentUserId == user2Id) {
        nextUser2Unread = unreadCount;
      } else {
        nextUser1Unread = unreadCount;
      }
    }

    return ConversationModel(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      matchId: matchId ?? this.matchId,
      lastMessageContent: lastMessage ?? lastMessageContent,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      user1UnreadCount: nextUser1Unread,
      user2UnreadCount: nextUser2Unread,
      isActive: isActive ?? this.isActive,
      isLocked: isLocked ?? this.isLocked,
      lockReason: lockReason ?? this.lockReason,
      createdAt: createdAt ?? this.createdAt,
      otherUser: otherUser ?? this.otherUser,
    );
  }
}
