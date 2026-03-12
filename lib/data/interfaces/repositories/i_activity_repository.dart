import 'package:du_xuan/domain/entities/activity.dart';

abstract class IActivityRepository {
  Future<List<Activity>> getByPlanDayId(int planDayId);
  Future<Activity> create(Activity activity);
  Future<void> update(Activity activity);
  Future<void> delete(int id);
  Future<void> toggleStatus(int id);
}
