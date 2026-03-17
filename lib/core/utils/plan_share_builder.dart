import 'package:du_xuan/core/enums/activity_type.dart';
import 'package:du_xuan/di.dart';
import 'package:du_xuan/data/interfaces/repositories/i_activity_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_checklist_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_repository.dart';
import 'package:du_xuan/core/utils/date_ui.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/domain/entities/checklist_item.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';
import 'package:intl/intl.dart';

/// Tạo text summary đẹp của plan để share
class PlanShareBuilder {
  PlanShareBuilder._();

  /// Load plan + activities + checklist → tạo text
  static Future<String> build(
    int planId, {
    IPlanRepository? planRepo,
    IActivityRepository? activityRepo,
    IChecklistRepository? checklistRepo,
  }) async {
    final resolvedPlanRepo = planRepo ?? buildPlanRepository();
    final resolvedActivityRepo = activityRepo ?? buildActivityRepository();
    final resolvedChecklistRepo = checklistRepo ?? buildChecklistRepository();

    final plan = await resolvedPlanRepo.getById(planId);
    if (plan == null) return 'Không tìm thấy kế hoạch';

    final activitiesFuture = _loadActivitiesByDay(plan, resolvedActivityRepo);
    final checklistFuture = resolvedChecklistRepo.getByPlanId(planId);

    final activitiesByDay = await activitiesFuture;
    final checklistItems = await checklistFuture;

    return _format(plan, activitiesByDay, checklistItems);
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

  static String _format(
    Plan plan,
    Map<PlanDay, List<Activity>> activitiesByDay,
    List<ChecklistItem> checklistItems,
  ) {
    final buf = StringBuffer();

    // Header
    buf.writeln('KẾ HOẠCH CHI TIẾT');
    buf.writeln(plan.name.toUpperCase());
    buf.writeln(
      'Thời gian: ${DateUi.fullDateRange(plan.startDate, plan.endDate)} '
      '(${DateUi.dayCountLabel(plan.totalDays)})',
    );
    if (plan.participants != null && plan.participants!.isNotEmpty) {
      buf.writeln('Thành viên: ${plan.participants}');
    }
    if (plan.description != null && plan.description!.isNotEmpty) {
      buf.writeln('Mô tả: ${plan.description}');
    }
    if (plan.note != null && plan.note!.isNotEmpty) {
      buf.writeln('Ghi chú kế hoạch: ${plan.note}');
    }

    // Activities by day
    buf.writeln();
    buf.writeln('LỊCH TRÌNH THEO NGÀY');
    final sortedDays = activitiesByDay.keys.toList()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    for (final day in sortedDays) {
      final activities = _sortActivities(activitiesByDay[day]!);

      buf.writeln();
      buf.writeln('Ngày ${day.dayNumber} - ${DateUi.fullDate(day.date)}');

      if (activities.isEmpty) {
        buf.writeln('- Chưa có hoạt động');
      } else {
        for (final a in activities) {
          final icon = _typeIcon(a.activityType);
          buf.writeln('- $icon ${a.title}');

          final timeLabel = _timeLabel(a);
          if (timeLabel.isNotEmpty) {
            buf.writeln('  • Thời gian: $timeLabel');
          }

          buf.writeln('  • Loại: ${a.activityType.label}');

          if (a.locationText != null && a.locationText!.isNotEmpty) {
            buf.writeln('  • Địa điểm: ${a.locationText}');
          }

          if (a.estimatedCost != null && a.estimatedCost! > 0) {
            buf.writeln(
              '  • Chi phí dự kiến: ${_formatCurrency(a.estimatedCost!)}',
            );
          }

          if (a.note != null && a.note!.isNotEmpty) {
            buf.writeln('  • Ghi chú: ${a.note}');
          }

          buf.writeln();
        }
      }
    }

    // Packing list details
    buf.writeln('ĐỒ CẦN MANG');
    if (checklistItems.isEmpty) {
      buf.writeln('- Chưa có danh sách đồ cần mang');
      return buf.toString();
    }

    final byCategory = <String, List<ChecklistItem>>{};
    for (final item in checklistItems) {
      final key = item.category.label;
      byCategory.putIfAbsent(key, () => []);
      byCategory[key]!.add(item);
    }

    final sortedCategoryNames = byCategory.keys.toList()..sort();
    for (final category in sortedCategoryNames) {
      final items = _sortChecklistItems(byCategory[category]!);

      buf.writeln('- $category:');
      for (final item in items) {
        final qty = item.quantity > 1 ? ' x${item.quantity}' : '';
        final note = (item.note != null && item.note!.isNotEmpty)
            ? ' (${item.note})'
            : '';
        buf.writeln('  • ${item.name}$qty$note');
      }
      buf.writeln();
    }

    return buf.toString();
  }

  static List<Activity> _sortActivities(List<Activity> activities) {
    return [...activities]..sort((a, b) {
      final byOrder = a.orderIndex.compareTo(b.orderIndex);
      if (byOrder != 0) return byOrder;
      final aTime = a.startTime ?? '';
      final bTime = b.startTime ?? '';
      return aTime.compareTo(bTime);
    });
  }

  static List<ChecklistItem> _sortChecklistItems(List<ChecklistItem> items) {
    return [...items]..sort((a, b) {
      final byPriority = b.priority.compareTo(a.priority);
      if (byPriority != 0) return byPriority;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  static String _typeIcon(ActivityType type) {
    switch (type) {
      case ActivityType.travel:
        return '🚗';
      case ActivityType.dining:
        return '🍜';
      case ActivityType.sightseeing:
        return '⛩';
      case ActivityType.shopping:
        return '🛍️';
      case ActivityType.worship:
        return '🛕';
      case ActivityType.rest:
        return '🏨';
      case ActivityType.other:
        return '📌';
    }
  }

  static String _timeLabel(Activity a) {
    final start = (a.startTime ?? '').trim();
    final end = (a.endTime ?? '').trim();
    if (start.isEmpty && end.isEmpty) return '';
    if (start.isNotEmpty && end.isNotEmpty) return '$start - $end';
    return start.isNotEmpty ? start : end;
  }

  static String _formatCurrency(double value) {
    final formatter = NumberFormat('#,###', 'vi');
    return '${formatter.format(value.round())}đ';
  }
}
