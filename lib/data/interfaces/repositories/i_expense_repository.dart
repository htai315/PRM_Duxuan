import 'package:du_xuan/domain/entities/expense.dart';

abstract class IExpenseRepository {
  Future<List<Expense>> getByPlanId(int planId);
  Future<List<Expense>> getByPlanDayId(int planDayId);
  Future<List<Expense>> getByActivityId(int activityId);
  Future<Expense> create(Expense expense);
  Future<void> update(Expense expense);
  Future<void> delete(int id);
}
