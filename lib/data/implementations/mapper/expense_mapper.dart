import 'package:du_xuan/core/enums/expense_category.dart';
import 'package:du_xuan/core/enums/expense_source.dart';
import 'package:du_xuan/data/dtos/expense/expense_dto.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/domain/entities/expense.dart';

class ExpenseMapper implements IMapper<ExpenseDto, Expense> {
  @override
  Expense map(ExpenseDto input) {
    return Expense(
      id: input.id ?? 0,
      planId: input.planId,
      planDayId: input.planDayId,
      activityId: input.activityId,
      title: input.title,
      amount: input.amount,
      category: ExpenseCategory.fromString(input.category),
      note: input.note,
      spentAt: DateTime.parse(input.spentAt),
      createdAt: DateTime.parse(input.createdAt),
      updatedAt: DateTime.parse(input.updatedAt),
      source: ExpenseSource.fromString(input.source),
    );
  }
}
