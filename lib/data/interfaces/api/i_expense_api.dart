import 'package:du_xuan/data/dtos/expense/create_expense_request_dto.dart';
import 'package:du_xuan/data/dtos/expense/expense_dto.dart';
import 'package:du_xuan/data/dtos/expense/update_expense_request_dto.dart';

abstract class IExpenseApi {
  Future<List<ExpenseDto>> getByPlanId(int planId);
  Future<List<ExpenseDto>> getByPlanDayId(int planDayId);
  Future<List<ExpenseDto>> getByActivityId(int activityId);
  Future<ExpenseDto?> getById(int id);
  Future<int> create(CreateExpenseRequestDto req);
  Future<void> update(UpdateExpenseRequestDto req);
  Future<void> delete(int id);
}
