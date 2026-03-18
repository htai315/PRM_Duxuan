import 'package:du_xuan/core/enums/expense_category.dart';
import 'package:du_xuan/core/enums/expense_source.dart';

class Expense {
  final int id;
  final int planId;
  final int? planDayId;
  final int? activityId;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final String? note;
  final DateTime spentAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ExpenseSource source;

  const Expense({
    required this.id,
    required this.planId,
    this.planDayId,
    this.activityId,
    required this.title,
    required this.amount,
    this.category = ExpenseCategory.other,
    this.note,
    required this.spentAt,
    required this.createdAt,
    required this.updatedAt,
    this.source = ExpenseSource.manual,
  });

  Expense copyWith({
    int? id,
    int? planId,
    int? planDayId,
    int? activityId,
    String? title,
    double? amount,
    ExpenseCategory? category,
    String? note,
    DateTime? spentAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    ExpenseSource? source,
  }) {
    return Expense(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      planDayId: planDayId ?? this.planDayId,
      activityId: activityId ?? this.activityId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      spentAt: spentAt ?? this.spentAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
    );
  }
}
