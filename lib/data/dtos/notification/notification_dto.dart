class NotificationDto {
  final int? id;
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

  const NotificationDto({
    this.id,
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

  factory NotificationDto.fromMap(Map<String, dynamic> map) {
    return NotificationDto(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      planId: map['plan_id'] as int?,
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      isRead: (map['is_read'] as int?) ?? 0,
      type: (map['type'] ?? 'SYSTEM').toString(),
      eventKey: map['event_key']?.toString(),
      scheduledAt: map['scheduled_at']?.toString(),
      createdAt: (map['created_at'] ?? '').toString(),
      readAt: map['read_at']?.toString(),
      payload: map['payload']?.toString(),
    );
  }
}
