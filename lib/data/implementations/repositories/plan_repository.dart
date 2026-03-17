import 'package:du_xuan/core/utils/pagination_utils.dart';
import 'package:du_xuan/data/dtos/plan/plan_dto.dart';
import 'package:du_xuan/data/dtos/plan/plan_activity_progress_dto.dart';
import 'package:du_xuan/data/dtos/plan/plan_day_dto.dart';
import 'package:du_xuan/data/dtos/plan/create_plan_request_dto.dart';
import 'package:du_xuan/data/dtos/plan/update_plan_request_dto.dart';
import 'package:du_xuan/data/interfaces/api/i_plan_api.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_repository.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/domain/entities/plan_activity_progress.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';

class PlanRepository implements IPlanRepository {
  final IPlanApi _api;
  final IMapper<PlanDto, Plan> _planMapper;
  final IMapper<PlanDayDto, PlanDay> _dayMapper;

  PlanRepository({
    required IPlanApi api,
    required IMapper<PlanDto, Plan> planMapper,
    required IMapper<PlanDayDto, PlanDay> dayMapper,
  }) : _api = api,
       _planMapper = planMapper,
       _dayMapper = dayMapper;

  @override
  Future<List<Plan>> getMyPlans(int userId) async {
    final dtos = await _api.getByUserId(userId);
    return dtos.map(_planMapper.map).toList();
  }

  @override
  Future<PagedResult<Plan>> getMyPlansPaged(
    int userId,
    int page,
    int pageSize,
  ) async {
    final (dtos, totalCount) = await _api.getByUserIdPaged(
      userId,
      page,
      pageSize,
    );
    final plans = dtos.map(_planMapper.map).toList();
    final totalPages = (totalCount / pageSize).ceil();
    final hasMore = page < totalPages;

    return PagedResult(
      items: plans,
      totalCount: totalCount,
      currentPage: page,
      hasMore: hasMore,
    );
  }

  @override
  Future<Map<int, PlanActivityProgress>> getActivityProgressByPlanIds(
    List<int> planIds,
  ) async {
    final dtos = await _api.getActivityProgressByPlanIds(planIds);
    return {for (final dto in dtos) dto.planId: _mapActivityProgress(dto)};
  }

  @override
  Future<Plan?> getById(int id) async {
    final dto = await _api.getById(id);
    if (dto == null) return null;

    final plan = _planMapper.map(dto);
    final dayDtos = await _api.getDaysByPlanId(id);
    final days = dayDtos.map(_dayMapper.map).toList();

    return plan.copyWith(days: days);
  }

  @override
  Future<Plan> create(Plan plan) async {
    final req = CreatePlanRequestDto(
      userId: plan.userId,
      name: plan.name,
      description: plan.description,
      startDate: _dateToString(plan.startDate),
      endDate: _dateToString(plan.endDate),
      participants: plan.participants,
      coverImage: plan.coverImage,
      note: plan.note,
      status: plan.status.name,
    );

    final planId = await _api.runInTransaction((api) async {
      final createdPlanId = await api.create(req);

      // BR-P03: Auto-gen PlanDays
      await _generateDays(api, createdPlanId, plan.startDate, plan.endDate);
      return createdPlanId;
    });

    // Trả về plan đầy đủ
    final created = await getById(planId);
    return created!;
  }

  @override
  Future<void> update(Plan plan) async {
    final req = UpdatePlanRequestDto(
      id: plan.id,
      userId: plan.userId,
      name: plan.name,
      description: plan.description,
      startDate: _dateToString(plan.startDate),
      endDate: _dateToString(plan.endDate),
      participants: plan.participants,
      coverImage: plan.coverImage,
      note: plan.note,
      status: plan.status.name,
    );

    await _api.runInTransaction((api) async {
      // Lấy date cũ TRƯỚC khi update nhưng vẫn nằm trong cùng transaction
      final existing = await api.getById(plan.id);
      final oldStart = existing?.startDate;
      final oldEnd = existing?.endDate;

      await api.update(req);

      // BR-P04: Smart sync — chỉ thêm/xóa ngày ở rìa, giữ nguyên ngày cũ
      final newStart = _dateToString(plan.startDate);
      final newEnd = _dateToString(plan.endDate);

      if (oldStart != newStart || oldEnd != newEnd) {
        await _syncDays(api, plan.id, plan.startDate, plan.endDate);
      }
    });
  }

  @override
  Future<void> delete(int id) async {
    // BR-P05: CASCADE tự xóa con thông qua FK
    await _api.delete(id);
  }

  // ─── HELPERS ──────────────────────────────────────────

  /// BR-P03: Sinh PlanDays từ startDate đến endDate
  Future<void> _generateDays(
    IPlanApi api,
    int planId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final days = <PlanDayDto>[];
    var current = startDate;
    var dayNumber = 1;

    while (!current.isAfter(endDate)) {
      days.add(
        PlanDayDto(
          planId: planId,
          date: _dateToString(current),
          dayNumber: dayNumber,
        ),
      );
      current = current.add(const Duration(days: 1));
      dayNumber++;
    }

    if (days.isNotEmpty) {
      await api.createDays(days);
    }
  }

  /// BR-P04: Shift activities — giữ activities theo dayNumber
  Future<void> _syncDays(
    IPlanApi api,
    int planId,
    DateTime newStart,
    DateTime newEnd,
  ) async {
    final existingDays = await api.getDaysByPlanId(planId);
    existingDays.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    final newTotalDays = newEnd.difference(newStart).inDays + 1;
    final oldCount = existingDays.length;

    // 1. Update date cho các ngày cũ còn giữ (shift activities)
    final keepCount = newTotalDays < oldCount ? newTotalDays : oldCount;
    for (var i = 0; i < keepCount; i++) {
      final newDate = newStart.add(Duration(days: i));
      final newDateStr = _dateToString(newDate);

      if (existingDays[i].date != newDateStr ||
          existingDays[i].dayNumber != i + 1) {
        await api.updateDay(
          PlanDayDto(
            id: existingDays[i].id,
            planId: planId,
            date: newDateStr,
            dayNumber: i + 1,
          ),
        );
      }
    }

    // 2. Plan dài hơn → thêm ngày mới ở cuối
    if (newTotalDays > oldCount) {
      final toAdd = <PlanDayDto>[];
      for (var i = oldCount; i < newTotalDays; i++) {
        toAdd.add(
          PlanDayDto(
            planId: planId,
            date: _dateToString(newStart.add(Duration(days: i))),
            dayNumber: i + 1,
          ),
        );
      }
      await api.createDays(toAdd);
    }

    // 3. Plan ngắn hơn → xóa ngày thừa cuối (CASCADE xóa activities)
    if (newTotalDays < oldCount) {
      for (var i = newTotalDays; i < oldCount; i++) {
        if (existingDays[i].id != null) {
          await api.deleteDay(existingDays[i].id!);
        }
      }
    }
  }

  /// Format DateTime → yyyy-MM-dd
  String _dateToString(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  PlanActivityProgress _mapActivityProgress(PlanActivityProgressDto dto) {
    return PlanActivityProgress(
      planId: dto.planId,
      totalActivities: dto.totalActivities,
      completedActivities: dto.completedActivities,
    );
  }
}
