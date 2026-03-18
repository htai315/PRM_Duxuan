import 'package:du_xuan/di.dart';
import 'package:du_xuan/data/interfaces/repositories/i_activity_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_checklist_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_expense_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_repository.dart';
import 'package:du_xuan/core/utils/date_ui.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/domain/entities/checklist_item.dart';
import 'package:du_xuan/domain/entities/expense.dart';
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
    IExpenseRepository? expenseRepo,
  }) async {
    final resolvedPlanRepo = planRepo ?? buildPlanRepository();
    final resolvedActivityRepo = activityRepo ?? buildActivityRepository();
    final resolvedChecklistRepo = checklistRepo ?? buildChecklistRepository();
    final resolvedExpenseRepo = expenseRepo ?? buildExpenseRepository();

    final plan = await resolvedPlanRepo.getById(planId);
    if (plan == null) return 'Không tìm thấy kế hoạch';

    final activitiesFuture = _loadActivitiesByDay(plan, resolvedActivityRepo);
    final checklistFuture = resolvedChecklistRepo.getByPlanId(planId);
    final expensesFuture = resolvedExpenseRepo.getByPlanId(planId);

    final activitiesByDay = await activitiesFuture;
    final checklistItems = await checklistFuture;
    final expenses = await expensesFuture;

    return _format(plan, activitiesByDay, checklistItems, expenses);
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
    List<Expense> expenses,
  ) {
    final buf = StringBuffer();
    final sortedDays = activitiesByDay.keys.toList()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    _writeHeaderSection(buf, plan);
    _writeDescriptionSection(buf, plan);
    _writeOverviewSection(buf, activitiesByDay, expenses);
    _writeItinerarySection(buf, sortedDays, activitiesByDay);
    _writeExpenseSection(buf, sortedDays, expenses);
    _writeChecklistSection(buf, checklistItems);

    return buf.toString().trimRight();
  }

  static void _writeHeaderSection(StringBuffer buf, Plan plan) {
    buf.writeln('DU XUÂN PLANNER');
    buf.writeln(plan.name);
    buf.writeln();
    buf.writeln('Thời gian: ${_planDateLabel(plan)}');
    buf.writeln('Số ngày: ${DateUi.dayCountLabel(plan.totalDays)}');
    if (plan.participants != null && plan.participants!.trim().isNotEmpty) {
      buf.writeln('Thành viên: ${plan.participants!.trim()}');
    }
  }

  static void _writeDescriptionSection(StringBuffer buf, Plan plan) {
    final description = plan.description?.trim() ?? '';
    final note = plan.note?.trim() ?? '';
    if (description.isEmpty && note.isEmpty) return;

    buf.writeln();
    buf.writeln('MÔ TẢ');
    if (description.isNotEmpty) {
      buf.writeln(description);
    } else if (note.isNotEmpty) {
      buf.writeln('Ghi chú: $note');
    }
  }

  static void _writeOverviewSection(
    StringBuffer buf,
    Map<PlanDay, List<Activity>> activitiesByDay,
    List<Expense> expenses,
  ) {
    final estimatedTotal = activitiesByDay.values
        .expand((activities) => activities)
        .fold<double>(
          0,
          (sum, activity) => sum + (activity.estimatedCost ?? 0),
        );
    final actualTotal = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final variance = actualTotal - estimatedTotal;

    buf.writeln();
    buf.writeln('TỔNG QUAN');
    buf.writeln('- Chi phí dự kiến: ${_formatCurrency(estimatedTotal)}');
    buf.writeln('- Chi phí thực tế đã ghi: ${_formatCurrency(actualTotal)}');
    buf.writeln('- Chênh lệch: ${_formatVariance(variance)}');
  }

  static void _writeItinerarySection(
    StringBuffer buf,
    List<PlanDay> sortedDays,
    Map<PlanDay, List<Activity>> activitiesByDay,
  ) {
    buf.writeln();
    buf.writeln('LỊCH TRÌNH THEO NGÀY');

    for (final day in sortedDays) {
      final activities = _sortActivities(activitiesByDay[day] ?? const []);

      buf.writeln();
      buf.writeln('Ngày ${day.dayNumber} - ${DateUi.fullDate(day.date)}');

      if (activities.isEmpty) {
        buf.writeln('- Chưa có hoạt động');
        continue;
      }

      for (final activity in activities) {
        buf.writeln('- ${activity.title}');

        final timeLabel = _timeLabel(activity);
        if (timeLabel.isNotEmpty) {
          buf.writeln('  • Thời gian: $timeLabel');
        }

        buf.writeln('  • Loại: ${activity.activityType.label}');

        if (activity.locationText != null &&
            activity.locationText!.trim().isNotEmpty) {
          buf.writeln('  • Địa điểm: ${activity.locationText!.trim()}');
        }

        if (activity.estimatedCost != null && activity.estimatedCost! > 0) {
          buf.writeln(
            '  • Chi phí dự kiến: ${_formatCurrency(activity.estimatedCost!)}',
          );
        }

        if (activity.note != null && activity.note!.trim().isNotEmpty) {
          buf.writeln('  • Ghi chú: ${activity.note!.trim()}');
        }

        buf.writeln();
      }
    }
  }

  static void _writeExpenseSection(
    StringBuffer buf,
    List<PlanDay> sortedDays,
    List<Expense> expenses,
  ) {
    buf.writeln('CHI TIÊU ĐÃ GHI NHẬN');

    if (expenses.isEmpty) {
      buf.writeln('- Chưa có khoản chi thực tế nào được ghi nhận');
      buf.writeln();
      return;
    }

    final expensesByDay = <int, List<Expense>>{};
    final unassigned = <Expense>[];

    for (final expense in expenses) {
      if (expense.planDayId == null) {
        unassigned.add(expense);
      } else {
        expensesByDay.putIfAbsent(expense.planDayId!, () => []).add(expense);
      }
    }

    for (final day in sortedDays) {
      final dayExpenses = expensesByDay[day.id];
      if (dayExpenses == null || dayExpenses.isEmpty) {
        continue;
      }

      final sortedExpenses = _sortExpenses(dayExpenses);
      buf.writeln('Ngày ${day.dayNumber}');
      for (final expense in sortedExpenses) {
        buf.writeln('- ${expense.title}: ${_formatCurrency(expense.amount)}');
        if (expense.note != null && expense.note!.trim().isNotEmpty) {
          buf.writeln('  • Ghi chú: ${expense.note!.trim()}');
        }
      }
      buf.writeln();
    }

    if (unassigned.isNotEmpty) {
      buf.writeln('KHOẢN CHI CHƯA GẮN NGÀY');
      for (final expense in _sortExpenses(unassigned)) {
        buf.writeln('- ${expense.title}: ${_formatCurrency(expense.amount)}');
        if (expense.note != null && expense.note!.trim().isNotEmpty) {
          buf.writeln('  • Ghi chú: ${expense.note!.trim()}');
        }
      }
      buf.writeln();
    }
  }

  static void _writeChecklistSection(
    StringBuffer buf,
    List<ChecklistItem> checklistItems,
  ) {
    buf.writeln('ĐỒ CẦN MANG');
    if (checklistItems.isEmpty) {
      buf.writeln('- Chưa có danh sách đồ cần mang');
      return;
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
        final note = (item.note != null && item.note!.trim().isNotEmpty)
            ? ' (${item.note!.trim()})'
            : '';
        buf.writeln('  • ${item.name}$qty$note');
      }
      buf.writeln();
    }
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

  static List<Expense> _sortExpenses(List<Expense> expenses) {
    return [...expenses]..sort((a, b) {
      final bySpentAt = a.spentAt.compareTo(b.spentAt);
      if (bySpentAt != 0) return bySpentAt;
      final byCreatedAt = a.createdAt.compareTo(b.createdAt);
      if (byCreatedAt != 0) return byCreatedAt;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
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

  static String _planDateLabel(Plan plan) {
    final sameDay =
        plan.startDate.year == plan.endDate.year &&
        plan.startDate.month == plan.endDate.month &&
        plan.startDate.day == plan.endDate.day;

    if (sameDay) {
      return DateUi.weekdayFullDate(plan.startDate);
    }

    return DateUi.fullDateRange(plan.startDate, plan.endDate);
  }

  static String _formatVariance(double value) {
    if (value == 0) return '0đ';
    final prefix = value > 0 ? '+' : '-';
    return '$prefix${_formatCurrency(value.abs())}';
  }
}
