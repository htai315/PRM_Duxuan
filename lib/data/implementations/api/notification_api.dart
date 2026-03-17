import 'package:du_xuan/data/dtos/notification/create_notification_request_dto.dart';
import 'package:du_xuan/data/dtos/notification/notification_dto.dart';
import 'package:du_xuan/data/implementations/local/db/app_database.dart';
import 'package:du_xuan/data/interfaces/api/i_notification_api.dart';

class NotificationApi implements INotificationApi {
  final AppDatabase _database;

  NotificationApi(this._database);

  @override
  Future<List<NotificationDto>> getByUserId(int userId) async {
    final db = await _database.db;
    final nowIso = DateTime.now().toIso8601String();

    final rows = await db.query(
      'notifications',
      where: 'user_id = ? AND (scheduled_at IS NULL OR scheduled_at <= ?)',
      whereArgs: [userId, nowIso],
      orderBy: 'is_read ASC, COALESCE(scheduled_at, created_at) DESC',
    );
    return rows.map(NotificationDto.fromMap).toList();
  }

  @override
  Future<int> getUnreadCount(int userId) async {
    final db = await _database.db;
    final nowIso = DateTime.now().toIso8601String();

    final rows = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications '
      'WHERE user_id = ? AND is_read = 0 '
      'AND (scheduled_at IS NULL OR scheduled_at <= ?)',
      [userId, nowIso],
    );
    return (rows.first['count'] as int?) ?? 0;
  }

  @override
  Future<NotificationDto?> getByEventKey(String eventKey) async {
    final db = await _database.db;

    final rows = await db.query(
      'notifications',
      where: 'event_key = ?',
      whereArgs: [eventKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return NotificationDto.fromMap(rows.first);
  }

  @override
  Future<NotificationDto?> getById(int id) async {
    final db = await _database.db;

    final rows = await db.query(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return NotificationDto.fromMap(rows.first);
  }

  @override
  Future<int> create(CreateNotificationRequestDto req) async {
    final db = await _database.db;
    return db.insert('notifications', req.toMap());
  }

  @override
  Future<void> markAsRead(int id, String readAtIso) async {
    final db = await _database.db;

    await db.update(
      'notifications',
      {'is_read': 1, 'read_at': readAtIso},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> markAllAsRead(int userId, String readAtIso) async {
    final db = await _database.db;
    final nowIso = DateTime.now().toIso8601String();

    await db.update(
      'notifications',
      {'is_read': 1, 'read_at': readAtIso},
      where:
          'user_id = ? AND is_read = 0 AND (scheduled_at IS NULL OR scheduled_at <= ?)',
      whereArgs: [userId, nowIso],
    );
  }

  @override
  Future<void> deleteByPlanId(int planId) async {
    final db = await _database.db;
    await db.delete('notifications', where: 'plan_id = ?', whereArgs: [planId]);
  }

  @override
  Future<void> deleteByEventKey(String eventKey) async {
    final db = await _database.db;
    await db.delete(
      'notifications',
      where: 'event_key = ?',
      whereArgs: [eventKey],
    );
  }

  @override
  Future<void> deleteReminderByPlanId(int planId) async {
    final db = await _database.db;
    await db.delete(
      'notifications',
      where: 'plan_id = ? AND type = ?',
      whereArgs: [planId, 'REMINDER'],
    );
  }
}
