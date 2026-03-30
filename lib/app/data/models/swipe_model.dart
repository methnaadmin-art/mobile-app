class SwipeModel {
  final String id;
  final String likerId;
  final String likedId;
  final String type; // like, compliment, pass
  final bool isLike;
  final String? complimentMessage;
  final DateTime createdAt;

  SwipeModel({
    required this.id,
    required this.likerId,
    required this.likedId,
    required this.type,
    required this.isLike,
    this.complimentMessage,
    required this.createdAt,
  });

  factory SwipeModel.fromJson(Map<String, dynamic> json) {
    return SwipeModel(
      id: json['id'] ?? '',
      likerId: json['likerId'] ?? '',
      likedId: json['likedId'] ?? '',
      type: json['type'] ?? 'like',
      isLike: json['isLike'] ?? true,
      complimentMessage: json['complimentMessage'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'likedId': likedId,
        'type': type,
        'complimentMessage': complimentMessage,
      };
}
