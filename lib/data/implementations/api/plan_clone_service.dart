import 'package:sqflite/sqflite.dart';

/// Chứa toàn bộ logic clone plan sang user mới.
/// Được tách ra từ PlanCopyApi để giữ single-responsibility.
class PlanCloneService {
  const PlanCloneService._();

  /// Clone toàn bộ plan (days, activities, checklist, expenses, source record)
  /// sang user mới trong cùng một transaction.
  static Future<int> clonePlanToUser({
    required DatabaseExecutor txn,
    required int sourcePlanId,
    required int sourceUserId,
    required int targetUserId,
    required String createdAtIso,
    required DateTime newStartDate,
  }) async {
    final sourcePlan = await _getPlan(txn, sourcePlanId);
    if (sourcePlan == null) {
      throw Exception('Không tìm thấy kế hoạch cần sao chép.');
    }

    final ownerId = sourcePlan['user_id'] as int?;
    if (ownerId != sourceUserId) {
      throw Exception('Bạn không có quyền chia sẻ kế hoạch này.');
    }

    final sender = await _getUser(txn, sourceUserId);
    final recipient = await _getUser(txn, targetUserId);
    if (sender == null || recipient == null) {
      throw Exception('Không tìm thấy tài khoản nhận kế hoạch.');
    }

    final templateDayCount = await _resolveTemplateDayCount(txn, sourcePlan);
    final normalizedStartDate = _dateOnly(newStartDate);
    final normalizedEndDate = normalizedStartDate.add(
      Duration(days: templateDayCount - 1),
    );

    final newPlanId = await txn.insert('plans', {
      'user_id': targetUserId,
      'name': (sourcePlan['name'] ?? '').toString(),
      'description': _nullableString(sourcePlan['description']),
      'start_date': _dateToIso(normalizedStartDate),
      'end_date': _dateToIso(normalizedEndDate),
      'participants': _nullableString(sourcePlan['participants']),
      'cover_image': _nullableString(sourcePlan['cover_image']),
      'note': _nullableString(sourcePlan['note']),
      'status': 'DRAFT',
      'created_at': createdAtIso,
      'updated_at': createdAtIso,
    });

    final dayIdMap = await _copyPlanDays(
      txn,
      sourcePlanId,
      newPlanId,
      normalizedStartDate,
    );
    final activityIdMap = await _copyActivities(txn, sourcePlanId, dayIdMap);
    await _copyChecklistItems(txn, sourcePlanId, newPlanId, activityIdMap);
    await _createCopySourceRecord(
      txn: txn,
      sourcePlanId: sourcePlanId,
      sourceUserId: sourceUserId,
      targetPlanId: newPlanId,
      targetUserId: targetUserId,
      createdAtIso: createdAtIso,
    );

    return newPlanId;
  }

  // ─── Copy helpers ────────────────────────────────────

  static Future<Map<int, int>> _copyPlanDays(
    DatabaseExecutor db,
    int sourcePlanId,
    int newPlanId,
    DateTime newStartDate,
  ) async {
    final rows = await db.query(
      'plan_days',
      where: 'plan_id = ?',
      whereArgs: [sourcePlanId],
      orderBy: 'day_number ASC',
    );

    final dayIdMap = <int, int>{};
    for (final row in rows) {
      final oldDayId = row['id'] as int?;
      if (oldDayId == null) continue;
      final dayNumber = row['day_number'] as int? ?? 0;
      final normalizedDayNumber = dayNumber <= 0
          ? dayIdMap.length + 1
          : dayNumber;
      final newDayId = await db.insert('plan_days', {
        'plan_id': newPlanId,
        'date': _dateToIso(
          newStartDate.add(Duration(days: normalizedDayNumber - 1)),
        ),
        'day_number': normalizedDayNumber,
      });
      dayIdMap[oldDayId] = newDayId;
    }
    return dayIdMap;
  }

  static Future<Map<int, int>> _copyActivities(
    DatabaseExecutor db,
    int sourcePlanId,
    Map<int, int> dayIdMap,
  ) async {
    final rows = await db.rawQuery(
      '''
      SELECT a.*
      FROM activities a
      INNER JOIN plan_days pd ON pd.id = a.plan_day_id
      WHERE pd.plan_id = ?
      ORDER BY pd.day_number ASC, a.order_index ASC, COALESCE(a.start_time, '') ASC, a.id ASC
      ''',
      [sourcePlanId],
    );

    final activityIdMap = <int, int>{};
    for (final row in rows) {
      final oldActivityId = row['id'] as int?;
      final oldPlanDayId = row['plan_day_id'] as int?;
      if (oldActivityId == null || oldPlanDayId == null) continue;

      final newPlanDayId = dayIdMap[oldPlanDayId];
      if (newPlanDayId == null) {
        throw Exception('Không thể sao chép lịch trình do thiếu mapping ngày.');
      }

      final newActivityId = await db.insert('activities', {
        'plan_day_id': newPlanDayId,
        'title': (row['title'] ?? '').toString(),
        'activity_type': (row['activity_type'] ?? 'OTHER').toString(),
        'start_time': _nullableString(row['start_time']),
        'end_time': _nullableString(row['end_time']),
        'destination_id': null,
        'location_text': _nullableString(row['location_text']),
        'note': _nullableString(row['note']),
        'estimated_cost': _nullableDouble(row['estimated_cost']),
        'priority': row['priority'] as int? ?? 0,
        'order_index': row['order_index'] as int? ?? 0,
        'status': 'TODO',
      });
      activityIdMap[oldActivityId] = newActivityId;
    }
    return activityIdMap;
  }

  static Future<void> _copyChecklistItems(
    DatabaseExecutor db,
    int sourcePlanId,
    int newPlanId,
    Map<int, int> activityIdMap,
  ) async {
    final rows = await db.query(
      'checklist_items',
      where: 'plan_id = ?',
      whereArgs: [sourcePlanId],
      orderBy: 'priority DESC, id ASC',
    );

    for (final row in rows) {
      final oldLinkedActivityId = row['linked_activity_id'] as int?;
      await db.insert('checklist_items', {
        'plan_id': newPlanId,
        'name': (row['name'] ?? '').toString(),
        'quantity': row['quantity'] as int? ?? 1,
        'category': (row['category'] ?? 'OTHER').toString(),
        'note': _nullableString(row['note']),
        'priority': row['priority'] as int? ?? 0,
        'is_packed': 0,
        'source': (row['source'] ?? 'MANUAL').toString(),
        'linked_activity_id': oldLinkedActivityId == null
            ? null
            : activityIdMap[oldLinkedActivityId],
        'suggested_level': _nullableString(row['suggested_level']),
      });
    }
  }

  static Future<void> _createCopySourceRecord({
    required DatabaseExecutor txn,
    required int sourcePlanId,
    required int sourceUserId,
    required int targetPlanId,
    required int targetUserId,
    required String createdAtIso,
  }) async {
    await txn.insert('plan_copy_sources', {
      'source_plan_id': sourcePlanId,
      'source_user_id': sourceUserId,
      'target_plan_id': targetPlanId,
      'target_user_id': targetUserId,
      'created_at': createdAtIso,
    });
  }

  // ─── Shared utils ────────────────────────────────────

  static Future<Map<String, dynamic>?> _getPlan(
    DatabaseExecutor db,
    int planId,
  ) async {
    final rows = await db.query(
      'plans',
      where: 'id = ?',
      whereArgs: [planId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  static Future<Map<String, dynamic>?> _getUser(
    DatabaseExecutor db,
    int userId,
  ) async {
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  static Future<int> _resolveTemplateDayCount(
    DatabaseExecutor db,
    Map<String, dynamic> sourcePlan,
  ) async {
    final parsedCount = _tryParseDayCount(
      sourcePlan['start_date']?.toString(),
      sourcePlan['end_date']?.toString(),
    );
    if (parsedCount != null && parsedCount > 0) {
      return parsedCount;
    }

    final sourcePlanId = sourcePlan['id'] as int?;
    if (sourcePlanId != null) {
      final countRows = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM plan_days WHERE plan_id = ?',
        [sourcePlanId],
      );
      final count = countRows.first['count'] as int? ?? 0;
      if (count > 0) return count;
    }

    return 1;
  }

  static int? _tryParseDayCount(String? startIso, String? endIso) {
    if (startIso == null || endIso == null) return null;
    final start = DateTime.tryParse(startIso);
    final end = DateTime.tryParse(endIso);
    if (start == null || end == null) return null;
    final normalizedStart = _dateOnly(start);
    final normalizedEnd = _dateOnly(end);
    final diff = normalizedEnd.difference(normalizedStart).inDays + 1;
    return diff > 0 ? diff : null;
  }

  static DateTime _dateOnly(DateTime input) {
    return DateTime(input.year, input.month, input.day);
  }

  static String _dateToIso(DateTime value) {
    return _dateOnly(value).toIso8601String();
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static double? _nullableDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
