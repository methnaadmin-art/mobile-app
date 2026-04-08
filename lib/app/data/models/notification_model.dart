class NotificationModel {
  final String id;
  final String userId;
  final String type; // match, like, super_like, message, system, subscription
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final rawCreatedAt =
        json['createdAt'] ?? json['timestamp'] ?? json['sentAt'];
    final data = rawData is Map ? Map<String, dynamic>.from(rawData) : null;
    final rawType = (json['type'] ?? 'system').toString();
    final derivedType = (data?['notificationType'] ?? data?['type'] ?? rawType)
        .toString();

    return NotificationModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      userId: (json['userId'] ?? json['recipientId'] ?? '').toString(),
      type: derivedType.trim().isEmpty ? rawType : derivedType,
      title: (json['title'] ?? json['heading'] ?? '').toString(),
      body: (json['body'] ?? json['message'] ?? '').toString(),
      data: data,
      isRead:
          json['isRead'] == true ||
          json['read'] == true ||
          json['readAt'] != null,
      createdAt:
          DateTime.tryParse(rawCreatedAt?.toString() ?? '') ?? DateTime.now(),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
