import 'package:du_xuan/data/dtos/notification/create_notification_request_dto.dart';
import 'package:du_xuan/data/dtos/notification/notification_dto.dart';
import 'package:du_xuan/data/interfaces/api/i_notification_api.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/data/interfaces/repositories/i_notification_repository.dart';
import 'package:du_xuan/domain/entities/app_notification.dart';

class NotificationRepository implements INotificationRepository {
  final INotificationApi _api;
  final IMapper<NotificationDto, AppNotification> _mapper;

  NotificationRepository({
    required INotificationApi api,
    required IMapper<NotificationDto, AppNotification> mapper,
  })  : _api = api,
        _mapper = mapper;

  @override
  Future<List<AppNotification>> getByUserId(int userId) async {
    final dtos = await _api.getByUserId(userId);
    return dtos.map(_mapper.map).toList();
  }

  @override
  Future<int> getUnreadCount(int userId) async {
    return _api.getUnreadCount(userId);
  }

  @override
  Future<AppNotification?> getByEventKey(String eventKey) async {
    final dto = await _api.getByEventKey(eventKey);
    if (dto == null) return null;
    return _mapper.map(dto);
  }

  @override
  Future<AppNotification?> getById(int id) async {
    final dto = await _api.getById(id);
    if (dto == null) return null;
    return _mapper.map(dto);
  }

  @override
  Future<AppNotification> create(AppNotification notification) async {
    final req = CreateNotificationRequestDto(
      userId: notification.userId,
      planId: notification.planId,
      title: notification.title,
      body: notification.body,
      isRead: notification.isRead ? 1 : 0,
      type: notification.type.name.toUpperCase(),
      eventKey: notification.eventKey,
      scheduledAt: notification.scheduledAt?.toIso8601String(),
      createdAt: notification.createdAt.toIso8601String(),
      readAt: notification.readAt?.toIso8601String(),
      payload: notification.payload,
    );

    final id = await _api.create(req);
    final created = await _api.getById(id);
    return _mapper.map(created!);
  }

  @override
  Future<void> markAsRead(int id) async {
    await _api.markAsRead(id, DateTime.now().toIso8601String());
  }

  @override
  Future<void> markAllAsRead(int userId) async {
    await _api.markAllAsRead(userId, DateTime.now().toIso8601String());
  }

  @override
  Future<void> deleteByPlanId(int planId) async {
    await _api.deleteByPlanId(planId);
  }

  @override
  Future<void> deleteByEventKey(String eventKey) async {
    await _api.deleteByEventKey(eventKey);
  }

  @override
  Future<void> deleteReminderByPlanId(int planId) async {
    await _api.deleteReminderByPlanId(planId);
  }
}
