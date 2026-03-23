import 'package:du_xuan/data/dtos/notification/create_notification_request_dto.dart';
import 'package:du_xuan/data/dtos/notification/notification_dto.dart';

abstract class INotificationApi {
  Future<List<NotificationDto>> getByUserId(int userId);
  Future<int> getUnreadCount(int userId);
  Future<NotificationDto?> getByEventKey(String eventKey);
  Future<NotificationDto?> getById(int id);
  Future<int> create(CreateNotificationRequestDto req);
  Future<void> deleteById(int id);
  Future<void> markAsRead(int id, String readAtIso);
  Future<void> markAllAsRead(int userId, String readAtIso);
  Future<void> deleteAllVisibleByUserId(int userId);
  Future<void> deleteByPlanId(int planId);
  Future<void> deleteByEventKey(String eventKey);
  Future<void> deleteReminderByPlanId(int planId);
}
