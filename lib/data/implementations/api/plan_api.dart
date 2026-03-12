import 'package:du_xuan/data/dtos/plan/plan_dto.dart';
import 'package:du_xuan/data/dtos/plan/plan_day_dto.dart';
import 'package:du_xuan/data/dtos/plan/create_plan_request_dto.dart';
import 'package:du_xuan/data/dtos/plan/update_plan_request_dto.dart';
import 'package:du_xuan/data/implementations/local/db/app_database.dart';
import 'package:du_xuan/data/interfaces/api/i_plan_api.dart';

class PlanApi implements IPlanApi {
  final AppDatabase _database;
  PlanApi(this._database);

  @override
  Future<List<PlanDto>> getByUserId(int userId) async {
    final db = await _database.db;
    final rows = await db.query(
      'plans',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(PlanDto.fromMap).toList();
  }

  @override
  Future<(List<PlanDto> items, int totalCount)> getByUserIdPaged(
      int userId, int page, int pageSize) async {
    final db = await _database.db;
    final offset = (page - 1) * pageSize;

    // Get total count
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM plans WHERE user_id = ?',
      [userId],
    );
    final totalCount = countResult.first['count'] as int;

    // Get paginated items
    final rows = await db.query(
      'plans',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
      limit: pageSize,
      offset: offset,
    );

    return (rows.map(PlanDto.fromMap).toList(), totalCount);
  }

  @override
  Future<PlanDto?> getById(int id) async {
    final db = await _database.db;
    final rows = await db.query(
      'plans',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PlanDto.fromMap(rows.first);
  }

  @override
  Future<int> create(CreatePlanRequestDto req) async {
    final db = await _database.db;
    return db.insert('plans', req.toMap());
  }

  @override
  Future<void> update(UpdatePlanRequestDto req) async {
    final db = await _database.db;
    await db.update(
      'plans',
      req.toMap(),
      where: 'id = ?',
      whereArgs: [req.id],
    );
  }

  @override
  Future<void> delete(int id) async {
    final db = await _database.db;
    await db.delete('plans', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<PlanDayDto>> getDaysByPlanId(int planId) async {
    final db = await _database.db;
    final rows = await db.query(
      'plan_days',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'day_number ASC',
    );
    return rows.map(PlanDayDto.fromMap).toList();
  }

  @override
  Future<void> createDays(List<PlanDayDto> days) async {
    final db = await _database.db;
    final batch = db.batch();
    for (final day in days) {
      batch.insert('plan_days', day.toMap());
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> deleteDaysByPlanId(int planId) async {
    final db = await _database.db;
    await db.delete('plan_days', where: 'plan_id = ?', whereArgs: [planId]);
  }

  @override
  Future<void> deleteDay(int dayId) async {
    final db = await _database.db;
    await db.delete('plan_days', where: 'id = ?', whereArgs: [dayId]);
  }

  @override
  Future<void> updateDay(PlanDayDto day) async {
    final db = await _database.db;
    await db.update(
      'plan_days',
      day.toMap(),
      where: 'id = ?',
      whereArgs: [day.id],
    );
  }
}
