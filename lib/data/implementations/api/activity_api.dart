import 'package:du_xuan/data/dtos/activity/activity_dto.dart';
import 'package:du_xuan/data/dtos/activity/create_activity_request_dto.dart';
import 'package:du_xuan/data/dtos/activity/update_activity_request_dto.dart';
import 'package:du_xuan/data/implementations/local/db/app_database.dart';
import 'package:du_xuan/data/interfaces/api/i_activity_api.dart';

class ActivityApi implements IActivityApi {
  final AppDatabase _database;
  ActivityApi(this._database);

  @override
  Future<List<ActivityDto>> getByPlanDayId(int planDayId) async {
    final db = await _database.db;
    final rows = await db.query(
      'activities',
      where: 'plan_day_id = ?',
      whereArgs: [planDayId],
      orderBy: 'order_index ASC, start_time ASC',
    );
    return rows.map(ActivityDto.fromMap).toList();
  }

  @override
  Future<ActivityDto?> getById(int id) async {
    final db = await _database.db;
    final rows = await db.query(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ActivityDto.fromMap(rows.first);
  }

  @override
  Future<int> create(CreateActivityRequestDto req) async {
    final db = await _database.db;
    return db.insert('activities', req.toMap());
  }

  @override
  Future<void> update(UpdateActivityRequestDto req) async {
    final db = await _database.db;
    await db.update(
      'activities',
      req.toMap(),
      where: 'id = ?',
      whereArgs: [req.id],
    );
  }

  @override
  Future<void> delete(int id) async {
    final db = await _database.db;
    await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }
}
