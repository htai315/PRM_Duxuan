import 'package:du_xuan/core/utils/pagination_utils.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/domain/entities/plan_activity_progress.dart';

abstract class IPlanRepository {
  /// Lấy tất cả plan của user hiện tại
  Future<List<Plan>> getMyPlans(int userId);

  /// Lấy plan phân trang của user
  Future<PagedResult<Plan>> getMyPlansPaged(int userId, int page, int pageSize);

  /// Lấy summary completion activity cho nhiều plan.
  Future<Map<int, PlanActivityProgress>> getActivityProgressByPlanIds(
    List<int> planIds,
  );

  /// Lấy plan theo id (kèm PlanDays)
  Future<Plan?> getById(int id);

  /// Tạo plan (auto-gen PlanDays từ startDate→endDate)
  Future<Plan> create(Plan plan);

  /// Cập nhật plan (sync PlanDays nếu date thay đổi)
  Future<void> update(Plan plan);

  /// Xóa plan (CASCADE)
  Future<void> delete(int id);
}
