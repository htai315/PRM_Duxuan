import 'package:du_xuan/domain/entities/app_notification.dart';

abstract class INotificationRepository {
  Future<List<AppNotification>> getByUserId(int userId);
  Future<int> getUnreadCount(int userId);
  Future<AppNotification?> getByEventKey(String eventKey);
  Future<AppNotification?> getById(int id);
  Future<AppNotification> create(AppNotification notification);
  Future<void> deleteById(int id);
  Future<void> markAsRead(int id);
  Future<void> markAllAsRead(int userId);
  Future<void> deleteAllVisibleByUserId(int userId);
  Future<void> deleteByPlanId(int planId);
  Future<void> deleteByEventKey(String eventKey);
  Future<void> deleteReminderByPlanId(int planId);
}
