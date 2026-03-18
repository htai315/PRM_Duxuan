import 'package:du_xuan/data/dtos/expense/create_expense_request_dto.dart';
import 'package:du_xuan/data/dtos/expense/expense_dto.dart';
import 'package:du_xuan/data/dtos/expense/update_expense_request_dto.dart';
import 'package:du_xuan/data/interfaces/api/i_expense_api.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/data/interfaces/repositories/i_expense_repository.dart';
import 'package:du_xuan/domain/entities/expense.dart';

class ExpenseRepository implements IExpenseRepository {
  final IExpenseApi _api;
  final IMapper<ExpenseDto, Expense> _mapper;

  ExpenseRepository({
    required IExpenseApi api,
    required IMapper<ExpenseDto, Expense> mapper,
  }) : _api = api,
       _mapper = mapper;

  @override
  Future<List<Expense>> getByPlanId(int planId) async {
    final dtos = await _api.getByPlanId(planId);
    return dtos.map(_mapper.map).toList();
  }

  @override
  Future<List<Expense>> getByPlanDayId(int planDayId) async {
    final dtos = await _api.getByPlanDayId(planDayId);
    return dtos.map(_mapper.map).toList();
  }

  @override
  Future<List<Expense>> getByActivityId(int activityId) async {
    final dtos = await _api.getByActivityId(activityId);
    return dtos.map(_mapper.map).toList();
  }

  @override
  Future<Expense> create(Expense expense) async {
    final req = CreateExpenseRequestDto(
      planId: expense.planId,
      planDayId: expense.planDayId,
      activityId: expense.activityId,
      title: expense.title,
      amount: expense.amount,
      category: expense.category.name.toUpperCase(),
      note: expense.note,
      spentAt: expense.spentAt.toIso8601String(),
      createdAt: expense.createdAt.toIso8601String(),
      updatedAt: expense.updatedAt.toIso8601String(),
      source: expense.source.name.toUpperCase(),
    );

    final id = await _api.create(req);
    final created = await _api.getById(id);
    return _mapper.map(created!);
  }

  @override
  Future<void> update(Expense expense) async {
    final req = UpdateExpenseRequestDto(
      id: expense.id,
      planId: expense.planId,
      planDayId: expense.planDayId,
      activityId: expense.activityId,
      title: expense.title,
      amount: expense.amount,
      category: expense.category.name.toUpperCase(),
      note: expense.note,
      spentAt: expense.spentAt.toIso8601String(),
      updatedAt: expense.updatedAt.toIso8601String(),
      source: expense.source.name.toUpperCase(),
    );
    await _api.update(req);
  }

  @override
  Future<void> delete(int id) async {
    await _api.delete(id);
  }
}
