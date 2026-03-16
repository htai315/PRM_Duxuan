import 'package:du_xuan/core/enums/notification_type.dart';

class AppNotification {
  final int id;
  final int userId;
  final int? planId;
  final String title;
  final String body;
  final bool isRead;
  final NotificationType type;
  final String? eventKey;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? payload;

  const AppNotification({
    required this.id,
    required this.userId,
    this.planId,
    required this.title,
    required this.body,
    this.isRead = false,
    this.type = NotificationType.system,
    this.eventKey,
    this.scheduledAt,
    required this.createdAt,
    this.readAt,
    this.payload,
  });

  AppNotification copyWith({
    int? id,
    int? userId,
    int? planId,
    String? title,
    String? body,
    bool? isRead,
    NotificationType? type,
    String? eventKey,
    DateTime? scheduledAt,
    DateTime? createdAt,
    DateTime? readAt,
    String? payload,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      eventKey: eventKey ?? this.eventKey,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      payload: payload ?? this.payload,
    );
  }
}
