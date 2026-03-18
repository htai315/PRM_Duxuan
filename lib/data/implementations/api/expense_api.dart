import 'package:du_xuan/data/dtos/expense/create_expense_request_dto.dart';
import 'package:du_xuan/data/dtos/expense/expense_dto.dart';
import 'package:du_xuan/data/dtos/expense/update_expense_request_dto.dart';
import 'package:du_xuan/data/implementations/local/db/app_database.dart';
import 'package:du_xuan/data/interfaces/api/i_expense_api.dart';

class ExpenseApi implements IExpenseApi {
  final AppDatabase _database;

  ExpenseApi(this._database);

  @override
  Future<List<ExpenseDto>> getByPlanId(int planId) async {
    final db = await _database.db;
    final rows = await db.query(
      'expenses',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'spent_at ASC, created_at ASC',
    );
    return rows.map(ExpenseDto.fromMap).toList();
  }

  @override
  Future<List<ExpenseDto>> getByPlanDayId(int planDayId) async {
    final db = await _database.db;
    final rows = await db.query(
      'expenses',
      where: 'plan_day_id = ?',
      whereArgs: [planDayId],
      orderBy: 'spent_at ASC, created_at ASC',
    );
    return rows.map(ExpenseDto.fromMap).toList();
  }

  @override
  Future<List<ExpenseDto>> getByActivityId(int activityId) async {
    final db = await _database.db;
    final rows = await db.query(
      'expenses',
      where: 'activity_id = ?',
      whereArgs: [activityId],
      orderBy: 'spent_at ASC, created_at ASC',
    );
    return rows.map(ExpenseDto.fromMap).toList();
  }

  @override
  Future<ExpenseDto?> getById(int id) async {
    final db = await _database.db;
    final rows = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ExpenseDto.fromMap(rows.first);
  }

  @override
  Future<int> create(CreateExpenseRequestDto req) async {
    final db = await _database.db;
    return db.insert('expenses', req.toMap());
  }

  @override
  Future<void> update(UpdateExpenseRequestDto req) async {
    final db = await _database.db;
    await db.update(
      'expenses',
      req.toMap(),
      where: 'id = ?',
      whereArgs: [req.id],
    );
  }

  @override
  Future<void> delete(int id) async {
    final db = await _database.db;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
