import 'package:du_xuan/core/utils/date_ui.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/domain/entities/checklist_item.dart';
import 'package:du_xuan/domain/entities/expense.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';
import 'package:intl/intl.dart';

class PlanPublicShareSnapshotDto {
  final int version;
  final String generatedAt;
  final PlanPublicSharePlanDto plan;
  final PlanPublicShareOverviewDto overview;
  final List<PlanPublicShareDayDto> days;
  final List<PlanPublicShareExpenseGroupDto> expenseGroups;
  final List<PlanPublicShareChecklistGroupDto> checklistGroups;

  const PlanPublicShareSnapshotDto({
    required this.version,
    required this.generatedAt,
    required this.plan,
    required this.overview,
    required this.days,
    required this.expenseGroups,
    required this.checklistGroups,
  });

  factory PlanPublicShareSnapshotDto.fromDomain({
    required Plan plan,
    required Map<PlanDay, List<Activity>> activitiesByDay,
    required List<Expense> expenses,
    required List<ChecklistItem> checklistItems,
    DateTime? generatedAt,
  }) {
    final resolvedGeneratedAt = generatedAt ?? DateTime.now();
    final sortedDays = activitiesByDay.keys.toList()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    return PlanPublicShareSnapshotDto(
      version: 1,
      generatedAt: resolvedGeneratedAt.toIso8601String(),
      plan: PlanPublicSharePlanDto.fromDomain(plan),
      overview: PlanPublicShareOverviewDto.fromDomain(
        activitiesByDay,
        expenses,
      ),
      days: sortedDays
          .map(
            (day) => PlanPublicShareDayDto.fromDomain(
              day: day,
              activities: _sortActivities(activitiesByDay[day] ?? const []),
            ),
          )
          .toList(growable: false),
      expenseGroups: _buildExpenseGroups(sortedDays, expenses),
      checklistGroups: _buildChecklistGroups(checklistItems),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'generatedAt': generatedAt,
    'plan': plan.toJson(),
    'overview': overview.toJson(),
    'days': days.map((day) => day.toJson()).toList(),
    'expenseGroups': expenseGroups.map((group) => group.toJson()).toList(),
    'checklistGroups': checklistGroups.map((group) => group.toJson()).toList(),
  };

  static List<Activity> _sortActivities(List<Activity> activities) {
    return [...activities]..sort((a, b) {
      final byOrder = a.orderIndex.compareTo(b.orderIndex);
      if (byOrder != 0) return byOrder;
      final aTime = (a.startTime ?? '').trim();
      final bTime = (b.startTime ?? '').trim();
      return aTime.compareTo(bTime);
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

  static List<ChecklistItem> _sortChecklistItems(List<ChecklistItem> items) {
    return [...items]..sort((a, b) {
      final byPriority = b.priority.compareTo(a.priority);
      if (byPriority != 0) return byPriority;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  static List<PlanPublicShareExpenseGroupDto> _buildExpenseGroups(
    List<PlanDay> sortedDays,
    List<Expense> expenses,
  ) {
    if (expenses.isEmpty) return const [];

    final expensesByDay = <int, List<Expense>>{};
    final unassigned = <Expense>[];

    for (final expense in expenses) {
      final planDayId = expense.planDayId;
      if (planDayId == null) {
        unassigned.add(expense);
        continue;
      }

      expensesByDay.putIfAbsent(planDayId, () => []);
      expensesByDay[planDayId]!.add(expense);
    }

    final groups = <PlanPublicShareExpenseGroupDto>[];
    for (final day in sortedDays) {
      final dayExpenses = expensesByDay[day.id];
      if (dayExpenses == null || dayExpenses.isEmpty) continue;

      groups.add(
        PlanPublicShareExpenseGroupDto.fromDay(
          day: day,
          expenses: _sortExpenses(dayExpenses),
        ),
      );
    }

    if (unassigned.isNotEmpty) {
      groups.add(
        PlanPublicShareExpenseGroupDto.unassigned(
          expenses: _sortExpenses(unassigned),
        ),
      );
    }

    return List.unmodifiable(groups);
  }

  static List<PlanPublicShareChecklistGroupDto> _buildChecklistGroups(
    List<ChecklistItem> checklistItems,
  ) {
    if (checklistItems.isEmpty) return const [];

    final byCategory = <String, List<ChecklistItem>>{};
    for (final item in checklistItems) {
      final key = item.category.name;
      byCategory.putIfAbsent(key, () => []);
      byCategory[key]!.add(item);
    }

    final orderedCategories = byCategory.keys.toList()
      ..sort((a, b) {
        final aIndex = ChecklistItemCategoryOrder.indexOf(a);
        final bIndex = ChecklistItemCategoryOrder.indexOf(b);
        return aIndex.compareTo(bIndex);
      });

    return List.unmodifiable(
      orderedCategories.map((categoryKey) {
        final items = _sortChecklistItems(byCategory[categoryKey]!);
        return PlanPublicShareChecklistGroupDto.fromItems(
          categoryKey: categoryKey,
          items: items,
        );
      }),
    );
  }
}

class PlanPublicSharePlanDto {
  final int id;
  final String name;
  final String startDate;
  final String endDate;
  final String displayDate;
  final int totalDays;
  final String displayDayCount;
  final String? participants;
  final String? description;

  const PlanPublicSharePlanDto({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.displayDate,
    required this.totalDays,
    required this.displayDayCount,
    required this.participants,
    required this.description,
  });

  factory PlanPublicSharePlanDto.fromDomain(Plan plan) {
    return PlanPublicSharePlanDto(
      id: plan.id,
      name: plan.name,
      startDate: plan.startDate.toIso8601String(),
      endDate: plan.endDate.toIso8601String(),
      displayDate: _planDateLabel(plan),
      totalDays: plan.totalDays,
      displayDayCount: DateUi.dayCountLabel(plan.totalDays),
      participants: _trimOrNull(plan.participants),
      description: _publicDescriptionOf(plan),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startDate': startDate,
    'endDate': endDate,
    'displayDate': displayDate,
    'totalDays': totalDays,
    'displayDayCount': displayDayCount,
    'participants': participants,
    'description': description,
  };
}

class PlanPublicShareOverviewDto {
  final double estimatedTotal;
  final double actualTotal;
  final double variance;
  final String displayEstimatedTotal;
  final String displayActualTotal;
  final String displayVariance;

  const PlanPublicShareOverviewDto({
    required this.estimatedTotal,
    required this.actualTotal,
    required this.variance,
    required this.displayEstimatedTotal,
    required this.displayActualTotal,
    required this.displayVariance,
  });

  factory PlanPublicShareOverviewDto.fromDomain(
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

    return PlanPublicShareOverviewDto(
      estimatedTotal: estimatedTotal,
      actualTotal: actualTotal,
      variance: variance,
      displayEstimatedTotal: _formatCurrency(estimatedTotal),
      displayActualTotal: _formatCurrency(actualTotal),
      displayVariance: _formatVariance(variance),
    );
  }

  Map<String, dynamic> toJson() => {
    'estimatedTotal': estimatedTotal,
    'actualTotal': actualTotal,
    'variance': variance,
    'displayEstimatedTotal': displayEstimatedTotal,
    'displayActualTotal': displayActualTotal,
    'displayVariance': displayVariance,
  };
}

class PlanPublicShareDayDto {
  final int id;
  final int dayNumber;
  final String date;
  final String displayDate;
  final int activityCount;
  final List<PlanPublicShareActivityDto> activities;

  const PlanPublicShareDayDto({
    required this.id,
    required this.dayNumber,
    required this.date,
    required this.displayDate,
    required this.activityCount,
    required this.activities,
  });

  factory PlanPublicShareDayDto.fromDomain({
    required PlanDay day,
    required List<Activity> activities,
  }) {
    return PlanPublicShareDayDto(
      id: day.id,
      dayNumber: day.dayNumber,
      date: day.date.toIso8601String(),
      displayDate: DateUi.fullDate(day.date),
      activityCount: activities.length,
      activities: activities
          .map(PlanPublicShareActivityDto.fromDomain)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayNumber': dayNumber,
    'date': date,
    'displayDate': displayDate,
    'activityCount': activityCount,
    'activities': activities.map((activity) => activity.toJson()).toList(),
  };
}

class PlanPublicShareActivityDto {
  final int id;
  final String title;
  final String type;
  final String typeLabel;
  final String status;
  final String statusLabel;
  final String? startTime;
  final String? endTime;
  final String? timeLabel;
  final String? locationText;
  final String? note;
  final double? estimatedCost;
  final String? displayEstimatedCost;
  final int orderIndex;

  const PlanPublicShareActivityDto({
    required this.id,
    required this.title,
    required this.type,
    required this.typeLabel,
    required this.status,
    required this.statusLabel,
    required this.startTime,
    required this.endTime,
    required this.timeLabel,
    required this.locationText,
    required this.note,
    required this.estimatedCost,
    required this.displayEstimatedCost,
    required this.orderIndex,
  });

  factory PlanPublicShareActivityDto.fromDomain(Activity activity) {
    final estimatedCost = activity.estimatedCost;
    return PlanPublicShareActivityDto(
      id: activity.id,
      title: activity.title,
      type: activity.activityType.name,
      typeLabel: activity.activityType.label,
      status: activity.status.name,
      statusLabel: activity.status.label,
      startTime: _trimOrNull(activity.startTime),
      endTime: _trimOrNull(activity.endTime),
      timeLabel: _timeLabel(activity),
      locationText: _trimOrNull(activity.locationText),
      note: _trimOrNull(activity.note),
      estimatedCost: estimatedCost,
      displayEstimatedCost: estimatedCost != null && estimatedCost > 0
          ? _formatCurrency(estimatedCost)
          : null,
      orderIndex: activity.orderIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'typeLabel': typeLabel,
    'status': status,
    'statusLabel': statusLabel,
    'startTime': startTime,
    'endTime': endTime,
    'timeLabel': timeLabel,
    'locationText': locationText,
    'note': note,
    'estimatedCost': estimatedCost,
    'displayEstimatedCost': displayEstimatedCost,
    'orderIndex': orderIndex,
  };
}

class PlanPublicShareExpenseGroupDto {
  final String type;
  final String title;
  final int? planDayId;
  final int? dayNumber;
  final int itemCount;
  final double totalAmount;
  final String displayTotalAmount;
  final List<PlanPublicShareExpenseItemDto> items;

  const PlanPublicShareExpenseGroupDto({
    required this.type,
    required this.title,
    required this.planDayId,
    required this.dayNumber,
    required this.itemCount,
    required this.totalAmount,
    required this.displayTotalAmount,
    required this.items,
  });

  factory PlanPublicShareExpenseGroupDto.fromDay({
    required PlanDay day,
    required List<Expense> expenses,
  }) {
    final totalAmount = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    return PlanPublicShareExpenseGroupDto(
      type: 'day',
      title: 'Ngày ${day.dayNumber}',
      planDayId: day.id,
      dayNumber: day.dayNumber,
      itemCount: expenses.length,
      totalAmount: totalAmount,
      displayTotalAmount: _formatCurrency(totalAmount),
      items: expenses
          .map(PlanPublicShareExpenseItemDto.fromDomain)
          .toList(growable: false),
    );
  }

  factory PlanPublicShareExpenseGroupDto.unassigned({
    required List<Expense> expenses,
  }) {
    final totalAmount = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    return PlanPublicShareExpenseGroupDto(
      type: 'unassigned',
      title: 'KHOẢN CHI CHƯA GẮN NGÀY',
      planDayId: null,
      dayNumber: null,
      itemCount: expenses.length,
      totalAmount: totalAmount,
      displayTotalAmount: _formatCurrency(totalAmount),
      items: expenses
          .map(PlanPublicShareExpenseItemDto.fromDomain)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'title': title,
    'planDayId': planDayId,
    'dayNumber': dayNumber,
    'itemCount': itemCount,
    'totalAmount': totalAmount,
    'displayTotalAmount': displayTotalAmount,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

class PlanPublicShareExpenseItemDto {
  final int id;
  final String title;
  final double amount;
  final String displayAmount;
  final String category;
  final String categoryLabel;
  final int? activityId;
  final String spentAt;
  final String displaySpentAt;
  final String? note;

  const PlanPublicShareExpenseItemDto({
    required this.id,
    required this.title,
    required this.amount,
    required this.displayAmount,
    required this.category,
    required this.categoryLabel,
    required this.activityId,
    required this.spentAt,
    required this.displaySpentAt,
    required this.note,
  });

  factory PlanPublicShareExpenseItemDto.fromDomain(Expense expense) {
    return PlanPublicShareExpenseItemDto(
      id: expense.id,
      title: expense.title,
      amount: expense.amount,
      displayAmount: _formatCurrency(expense.amount),
      category: expense.category.name,
      categoryLabel: expense.category.label,
      activityId: expense.activityId,
      spentAt: expense.spentAt.toIso8601String(),
      displaySpentAt: DateUi.fullDate(expense.spentAt),
      note: _trimOrNull(expense.note),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'displayAmount': displayAmount,
    'category': category,
    'categoryLabel': categoryLabel,
    'activityId': activityId,
    'spentAt': spentAt,
    'displaySpentAt': displaySpentAt,
    'note': note,
  };
}

class PlanPublicShareChecklistGroupDto {
  final String category;
  final String categoryLabel;
  final int itemCount;
  final List<PlanPublicShareChecklistItemDto> items;

  const PlanPublicShareChecklistGroupDto({
    required this.category,
    required this.categoryLabel,
    required this.itemCount,
    required this.items,
  });

  factory PlanPublicShareChecklistGroupDto.fromItems({
    required String categoryKey,
    required List<ChecklistItem> items,
  }) {
    final category = items.first.category;
    return PlanPublicShareChecklistGroupDto(
      category: categoryKey,
      categoryLabel: category.label,
      itemCount: items.length,
      items: items
          .map(PlanPublicShareChecklistItemDto.fromDomain)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'categoryLabel': categoryLabel,
    'itemCount': itemCount,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

class PlanPublicShareChecklistItemDto {
  final int id;
  final String name;
  final int quantity;
  final String displayQuantity;
  final String? note;

  const PlanPublicShareChecklistItemDto({
    required this.id,
    required this.name,
    required this.quantity,
    required this.displayQuantity,
    required this.note,
  });

  factory PlanPublicShareChecklistItemDto.fromDomain(ChecklistItem item) {
    return PlanPublicShareChecklistItemDto(
      id: item.id,
      name: item.name,
      quantity: item.quantity,
      displayQuantity: item.quantity > 1 ? 'x${item.quantity}' : 'x1',
      note: _trimOrNull(item.note),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'displayQuantity': displayQuantity,
    'note': note,
  };
}

String? _trimOrNull(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

String? _publicDescriptionOf(Plan plan) {
  final description = _trimOrNull(plan.description);
  if (description != null) return description;
  return _trimOrNull(plan.note);
}

String _planDateLabel(Plan plan) {
  final sameDay =
      plan.startDate.year == plan.endDate.year &&
      plan.startDate.month == plan.endDate.month &&
      plan.startDate.day == plan.endDate.day;

  if (sameDay) {
    return DateUi.weekdayFullDate(plan.startDate);
  }

  return DateUi.fullDateRange(plan.startDate, plan.endDate);
}

String? _timeLabel(Activity activity) {
  final start = _trimOrNull(activity.startTime);
  final end = _trimOrNull(activity.endTime);
  if (start == null && end == null) return null;
  if (start != null && end != null) return '$start - $end';
  return start ?? end;
}

String _formatCurrency(double value) {
  final formatter = NumberFormat('#,###', 'vi');
  return '${formatter.format(value.round())}đ';
}

String _formatVariance(double value) {
  if (value == 0) return '0đ';
  final prefix = value > 0 ? '+' : '-';
  return '$prefix${_formatCurrency(value.abs())}';
}

class ChecklistItemCategoryOrder {
  ChecklistItemCategoryOrder._();

  static const List<String> _orderedKeys = [
    'clothing',
    'toiletry',
    'electronics',
    'document',
    'medicine',
    'food',
    'other',
  ];

  static int indexOf(String key) {
    final index = _orderedKeys.indexOf(key);
    return index >= 0 ? index : _orderedKeys.length;
  }
}
