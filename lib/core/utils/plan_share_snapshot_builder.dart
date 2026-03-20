import 'package:du_xuan/data/dtos/share/plan_public_share_snapshot_dto.dart';
import 'package:du_xuan/data/interfaces/repositories/i_activity_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_checklist_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_expense_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_repository.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';

/// Tạo snapshot có cấu trúc để upload lên public share service.
class PlanShareSnapshotBuilder {
  PlanShareSnapshotBuilder._();

  static Future<PlanPublicShareSnapshotDto?> build(
    int planId, {
    required IPlanRepository planRepo,
    required IActivityRepository activityRepo,
    required IChecklistRepository checklistRepo,
    required IExpenseRepository expenseRepo,
    DateTime? generatedAt,
  }) async {
    final plan = await planRepo.getById(planId);
    if (plan == null) return null;

    final activitiesFuture = _loadActivitiesByDay(plan, activityRepo);
    final checklistFuture = checklistRepo.getByPlanId(planId);
    final expensesFuture = expenseRepo.getByPlanId(planId);

    final activitiesByDay = await activitiesFuture;
    final checklistItems = await checklistFuture;
    final expenses = await expensesFuture;

    return PlanPublicShareSnapshotDto.fromDomain(
      plan: plan,
      activitiesByDay: activitiesByDay,
      expenses: expenses,
      checklistItems: checklistItems,
      generatedAt: generatedAt,
    );
  }

  static Future<Map<String, dynamic>?> buildJson(
    int planId, {
    required IPlanRepository planRepo,
    required IActivityRepository activityRepo,
    required IChecklistRepository checklistRepo,
    required IExpenseRepository expenseRepo,
    DateTime? generatedAt,
  }) async {
    final snapshot = await build(
      planId,
      planRepo: planRepo,
      activityRepo: activityRepo,
      checklistRepo: checklistRepo,
      expenseRepo: expenseRepo,
      generatedAt: generatedAt,
    );

    return snapshot?.toJson();
  }

  static Future<Map<PlanDay, List<Activity>>> _loadActivitiesByDay(
    Plan plan,
    IActivityRepository activityRepo,
  ) async {
    final entries = await Future.wait(
      plan.days.map((day) async {
        final activities = await activityRepo.getByPlanDayId(day.id);
        return MapEntry(day, activities);
      }),
    );

    return Map<PlanDay, List<Activity>>.fromEntries(entries);
  }
}

