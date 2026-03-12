import 'package:du_xuan/core/enums/activity_type.dart';
import 'package:du_xuan/di.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/domain/entities/checklist_item.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';
import 'package:intl/intl.dart';

/// Tạo text summary đẹp của plan để share
class PlanShareBuilder {
  PlanShareBuilder._();

  /// Load plan + activities + checklist → tạo text
  static Future<String> build(int planId) async {
    final planRepo = buildPlanRepository();
    final activityRepo = buildActivityRepository();
    final checklistRepo = buildChecklistRepository();

    final plan = await planRepo.getById(planId);
    if (plan == null) return 'Không tìm thấy kế hoạch';

    // Load activities per day
    final activitiesByDay = <PlanDay, List<Activity>>{};
    for (final day in plan.days) {
      activitiesByDay[day] = await activityRepo.getByPlanDayId(day.id);
    }

    // Load checklist details
    final checklistItems = await checklistRepo.getByPlanId(planId);

    return _format(plan, activitiesByDay, checklistItems);
  }

  static String _format(
    Plan plan,
    Map<PlanDay, List<Activity>> activitiesByDay,
    List<ChecklistItem> checklistItems,
  ) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final buf = StringBuffer();

    // Header
    buf.writeln('KẾ HOẠCH CHI TIẾT');
    buf.writeln(plan.name.toUpperCase());
    buf.writeln(
      'Thời gian: ${dateFmt.format(plan.startDate)} - '
      '${dateFmt.format(plan.endDate)} (${plan.totalDays} ngày)',
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
      final activities = [...activitiesByDay[day]!]
        ..sort((a, b) {
          final byOrder = a.orderIndex.compareTo(b.orderIndex);
          if (byOrder != 0) return byOrder;
          final aTime = a.startTime ?? '';
          final bTime = b.startTime ?? '';
          return aTime.compareTo(bTime);
        });

      buf.writeln();
      buf.writeln('Ngày ${day.dayNumber} - ${dateFmt.format(day.date)}');

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
            buf.writeln('  • Chi phí dự kiến: ${_formatCurrency(a.estimatedCost!)}');
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
      final items = byCategory[category]!
        ..sort((a, b) {
          final byPriority = b.priority.compareTo(a.priority);
          if (byPriority != 0) return byPriority;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

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
