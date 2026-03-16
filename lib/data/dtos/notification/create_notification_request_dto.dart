class CreateNotificationRequestDto {
  final int userId;
  final int? planId;
  final String title;
  final String body;
  final int isRead;
  final String type;
  final String? eventKey;
  final String? scheduledAt;
  final String createdAt;
  final String? readAt;
  final String? payload;

  const CreateNotificationRequestDto({
    required this.userId,
    this.planId,
    required this.title,
    required this.body,
    this.isRead = 0,
    this.type = 'SYSTEM',
    this.eventKey,
    this.scheduledAt,
    required this.createdAt,
    this.readAt,
    this.payload,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'plan_id': planId,
      'title': title,
      'body': body,
      'is_read': isRead,
      'type': type,
      'event_key': eventKey,
      'scheduled_at': scheduledAt,
      'created_at': createdAt,
      'read_at': readAt,
      'payload': payload,
    };
  }
}
