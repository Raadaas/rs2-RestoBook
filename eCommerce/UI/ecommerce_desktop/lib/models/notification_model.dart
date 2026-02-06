class NotificationModel {
  final int id;
  final int userId;
  final String? type;
  final String title;
  final String message;
  final int? relatedReservationId;
  final bool isRead;
  final DateTime sentAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.type,
    required this.title,
    required this.message,
    this.relatedReservationId,
    required this.isRead,
    required this.sentAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      type: json['type'],
      title: (json['title'] ?? '') as String,
      message: (json['message'] ?? '') as String,
      relatedReservationId: json['relatedReservationId'],
      isRead: json['isRead'] ?? false,
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
    );
  }
}
