import 'package:du_xuan/data/dtos/plan/plan_dto.dart';
import 'package:du_xuan/data/dtos/plan/plan_day_dto.dart';
import 'package:du_xuan/data/dtos/plan/create_plan_request_dto.dart';
import 'package:du_xuan/data/dtos/plan/update_plan_request_dto.dart';

abstract class IPlanApi {
  /// Lấy tất cả plan của 1 user
  Future<List<PlanDto>> getByUserId(int userId);

  /// Lấy plan phân trang của 1 user
  Future<(List<PlanDto> items, int totalCount)> getByUserIdPaged(
      int userId, int page, int pageSize);

  /// Lấy plan theo id
  Future<PlanDto?> getById(int id);

  /// Tạo plan mới, trả về id
  Future<int> create(CreatePlanRequestDto req);

  /// Cập nhật plan
  Future<void> update(UpdatePlanRequestDto req);

  /// Xóa plan (CASCADE sẽ xóa con)
  Future<void> delete(int id);

  /// Lấy danh sách ngày của plan
  Future<List<PlanDayDto>> getDaysByPlanId(int planId);

  /// Tạo batch PlanDays
  Future<void> createDays(List<PlanDayDto> days);

  /// Xóa tất cả PlanDays của plan
  Future<void> deleteDaysByPlanId(int planId);

  /// Xóa 1 PlanDay theo id
  Future<void> deleteDay(int dayId);

  /// Cập nhật 1 PlanDay
  Future<void> updateDay(PlanDayDto day);
}
