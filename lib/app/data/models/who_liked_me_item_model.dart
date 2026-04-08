import 'package:methna_app/app/data/models/user_model.dart';

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

class WhoLikedMeItem {
  final UserModel user;
  final String type;
  final String? complimentMessage;
  final DateTime? createdAt;

  const WhoLikedMeItem({
    required this.user,
    required this.type,
    this.complimentMessage,
    this.createdAt,
  });

  factory WhoLikedMeItem.fromJson(Map<String, dynamic> json) {
    final userPayload = Map<String, dynamic>.from(json);
    final userId = (json['userId'] ?? json['id'] ?? json['_id'])?.toString();

    if (userId != null && userId.isNotEmpty) {
      userPayload['id'] = userId;
      userPayload['_id'] = userId;
      userPayload['userId'] = userId;
    }

    final rawCompliment = json['complimentMessage']?.toString().trim();

    return WhoLikedMeItem(
      user: UserModel.fromApiEntry(userPayload),
      type: (json['type'] ?? 'like').toString(),
      complimentMessage: (rawCompliment == null || rawCompliment.isEmpty)
          ? null
          : rawCompliment,
      createdAt: _parseDate(json['createdAt']),
    );
  }
}
