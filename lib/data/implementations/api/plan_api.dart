import 'package:du_xuan/data/dtos/plan/create_plan_request_dto.dart';
import 'package:du_xuan/data/dtos/plan/plan_day_dto.dart';
import 'package:du_xuan/data/dtos/plan/plan_dto.dart';
import 'package:du_xuan/data/dtos/plan/plan_activity_progress_dto.dart';
import 'package:du_xuan/data/dtos/plan/update_plan_request_dto.dart';
import 'package:du_xuan/data/implementations/local/db/app_database.dart';
import 'package:du_xuan/data/interfaces/api/i_plan_api.dart';
import 'package:sqflite/sqflite.dart';

class PlanApi implements IPlanApi {
  final AppDatabase _database;

  PlanApi(this._database);

  @override
  Future<T> runInTransaction<T>(Future<T> Function(IPlanApi api) action) async {
    final db = await _database.db;
    return db.transaction<T>((txn) async {
      return action(_TransactionalPlanApi(txn));
    });
  }

  @override
  Future<List<PlanDto>> getByUserId(int userId) async {
    final db = await _database.db;
    return _PlanSql.getByUserId(db, userId);
  }

  @override
  Future<(List<PlanDto> items, int totalCount)> getByUserIdPaged(
    int userId,
    int page,
    int pageSize,
  ) async {
    final db = await _database.db;
    return _PlanSql.getByUserIdPaged(db, userId, page, pageSize);
  }

  @override
  Future<List<PlanActivityProgressDto>> getActivityProgressByPlanIds(
    List<int> planIds,
  ) async {
    final db = await _database.db;
    return _PlanSql.getActivityProgressByPlanIds(db, planIds);
  }

  @override
  Future<PlanDto?> getById(int id) async {
    final db = await _database.db;
    return _PlanSql.getById(db, id);
  }

  @override
  Future<int> create(CreatePlanRequestDto req) async {
    final db = await _database.db;
    return _PlanSql.create(db, req);
  }

  @override
  Future<void> update(UpdatePlanRequestDto req) async {
    final db = await _database.db;
    await _PlanSql.update(db, req);
  }

  @override
  Future<void> delete(int id) async {
    final db = await _database.db;
    await _PlanSql.delete(db, id);
  }

  @override
  Future<List<PlanDayDto>> getDaysByPlanId(int planId) async {
    final db = await _database.db;
    return _PlanSql.getDaysByPlanId(db, planId);
  }

  @override
  Future<void> createDays(List<PlanDayDto> days) async {
    final db = await _database.db;
    await _PlanSql.createDays(db, days);
  }

  @override
  Future<void> deleteDaysByPlanId(int planId) async {
    final db = await _database.db;
    await _PlanSql.deleteDaysByPlanId(db, planId);
  }

  @override
  Future<void> deleteDay(int dayId) async {
    final db = await _database.db;
    await _PlanSql.deleteDay(db, dayId);
  }

  @override
  Future<void> updateDay(PlanDayDto day) async {
    final db = await _database.db;
    await _PlanSql.updateDay(db, day);
  }
}

class _TransactionalPlanApi implements IPlanApi {
  final DatabaseExecutor _db;

  _TransactionalPlanApi(this._db);

  @override
  Future<T> runInTransaction<T>(Future<T> Function(IPlanApi api) action) {
    return action(this);
  }

  @override
  Future<List<PlanDto>> getByUserId(int userId) {
    return _PlanSql.getByUserId(_db, userId);
  }

  @override
  Future<(List<PlanDto> items, int totalCount)> getByUserIdPaged(
    int userId,
    int page,
    int pageSize,
  ) {
    return _PlanSql.getByUserIdPaged(_db, userId, page, pageSize);
  }

  @override
  Future<List<PlanActivityProgressDto>> getActivityProgressByPlanIds(
    List<int> planIds,
  ) {
    return _PlanSql.getActivityProgressByPlanIds(_db, planIds);
  }

  @override
  Future<PlanDto?> getById(int id) {
    return _PlanSql.getById(_db, id);
  }

  @override
  Future<int> create(CreatePlanRequestDto req) {
    return _PlanSql.create(_db, req);
  }

  @override
  Future<void> update(UpdatePlanRequestDto req) {
    return _PlanSql.update(_db, req);
  }

  @override
  Future<void> delete(int id) {
    return _PlanSql.delete(_db, id);
  }

  @override
  Future<List<PlanDayDto>> getDaysByPlanId(int planId) {
    return _PlanSql.getDaysByPlanId(_db, planId);
  }

  @override
  Future<void> createDays(List<PlanDayDto> days) {
    return _PlanSql.createDays(_db, days);
  }

  @override
  Future<void> deleteDaysByPlanId(int planId) {
    return _PlanSql.deleteDaysByPlanId(_db, planId);
  }

  @override
  Future<void> deleteDay(int dayId) {
    return _PlanSql.deleteDay(_db, dayId);
  }

  @override
  Future<void> updateDay(PlanDayDto day) {
    return _PlanSql.updateDay(_db, day);
  }
}

class _PlanSql {
  static Future<List<PlanDto>> getByUserId(
    DatabaseExecutor db,
    int userId,
  ) async {
    final rows = await db.query(
      'plans',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(PlanDto.fromMap).toList();
  }

  static Future<(List<PlanDto> items, int totalCount)> getByUserIdPaged(
    DatabaseExecutor db,
    int userId,
    int page,
    int pageSize,
  ) async {
    final offset = (page - 1) * pageSize;

    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM plans WHERE user_id = ?',
      [userId],
    );
    final totalCount = countResult.first['count'] as int;

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

  static Future<List<PlanActivityProgressDto>> getActivityProgressByPlanIds(
    DatabaseExecutor db,
    List<int> planIds,
  ) async {
    if (planIds.isEmpty) return const [];

    final placeholders = List.filled(planIds.length, '?').join(', ');
    final rows = await db.rawQuery('''
      SELECT
        pd.plan_id AS plan_id,
        COUNT(a.id) AS total_activities,
        COALESCE(
          SUM(CASE WHEN LOWER(a.status) = 'done' THEN 1 ELSE 0 END),
          0
        ) AS completed_activities
      FROM plan_days pd
      LEFT JOIN activities a ON a.plan_day_id = pd.id
      WHERE pd.plan_id IN ($placeholders)
      GROUP BY pd.plan_id
      ''', planIds);

    return rows.map(PlanActivityProgressDto.fromMap).toList();
  }

  static Future<PlanDto?> getById(DatabaseExecutor db, int id) async {
    final rows = await db.query(
      'plans',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PlanDto.fromMap(rows.first);
  }

  static Future<int> create(
    DatabaseExecutor db,
    CreatePlanRequestDto req,
  ) async {
    return db.insert('plans', req.toMap());
  }

  static Future<void> update(
    DatabaseExecutor db,
    UpdatePlanRequestDto req,
  ) async {
    await db.update('plans', req.toMap(), where: 'id = ?', whereArgs: [req.id]);
  }

  static Future<void> delete(DatabaseExecutor db, int id) async {
    await db.delete('plans', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<PlanDayDto>> getDaysByPlanId(
    DatabaseExecutor db,
    int planId,
  ) async {
    final rows = await db.query(
      'plan_days',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'day_number ASC',
    );
    return rows.map(PlanDayDto.fromMap).toList();
  }

  static Future<void> createDays(
    DatabaseExecutor db,
    List<PlanDayDto> days,
  ) async {
    final batch = db.batch();
    for (final day in days) {
      batch.insert('plan_days', day.toMap());
    }
    await batch.commit(noResult: true);
  }

  static Future<void> deleteDaysByPlanId(
    DatabaseExecutor db,
    int planId,
  ) async {
    await db.delete('plan_days', where: 'plan_id = ?', whereArgs: [planId]);
  }

  static Future<void> deleteDay(DatabaseExecutor db, int dayId) async {
    await db.delete('plan_days', where: 'id = ?', whereArgs: [dayId]);
  }

  static Future<void> updateDay(DatabaseExecutor db, PlanDayDto day) async {
    await db.update(
      'plan_days',
      day.toMap(),
      where: 'id = ?',
      whereArgs: [day.id],
    );
  }
}
