import 'package:du_xuan/core/enums/notification_type.dart';
import 'package:du_xuan/data/dtos/notification/notification_dto.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/domain/entities/app_notification.dart';

class NotificationMapper
    implements IMapper<NotificationDto, AppNotification> {
  @override
  AppNotification map(NotificationDto input) {
    return AppNotification(
      id: input.id ?? 0,
      userId: input.userId,
      planId: input.planId,
      title: input.title,
      body: input.body,
      isRead: input.isRead == 1,
      type: NotificationType.fromString(input.type),
      eventKey: input.eventKey,
      scheduledAt: _tryParseDate(input.scheduledAt),
      createdAt: DateTime.parse(input.createdAt),
      readAt: _tryParseDate(input.readAt),
      payload: input.payload,
    );
  }

  DateTime? _tryParseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
