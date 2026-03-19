import 'dart:convert';

import 'package:du_xuan/data/dtos/share/plan_copy_request_dto.dart';
import 'package:du_xuan/data/implementations/local/db/app_database.dart';
import 'package:du_xuan/data/interfaces/api/i_plan_copy_api.dart';
import 'package:sqflite/sqflite.dart';

class PlanCopyApi implements IPlanCopyApi {
  final AppDatabase _database;

  PlanCopyApi(this._database);

  @override
  Future<int> createCopyRequest({
    required int sourcePlanId,
    required int sourceUserId,
    required int targetUserId,
  }) async {
    if (sourceUserId == targetUserId) {
      throw Exception('Không thể gửi kế hoạch cho chính bạn.');
    }

    final db = await _database.db;
    return db.transaction<int>((txn) async {
      final sourcePlan = await _getPlan(txn, sourcePlanId);
      if (sourcePlan == null) {
        throw Exception('Không tìm thấy kế hoạch cần chia sẻ.');
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

      final existingCopy = await _findExistingCopy(
        txn,
        sourcePlanId: sourcePlanId,
        targetUserId: targetUserId,
      );
      if (existingCopy != null) {
        throw Exception('Tài khoản này đã nhận bản sao của kế hoạch này rồi.');
      }

      final pendingRequest = await _findPendingRequest(
        txn,
        sourcePlanId: sourcePlanId,
        targetUserId: targetUserId,
      );
      if (pendingRequest != null) {
        throw Exception(
          'Tài khoản này đang có lời mời nhận kế hoạch chưa xử lý.',
        );
      }

      final nowIso = DateTime.now().toIso8601String();
      final requestId = await txn.insert('plan_copy_requests', {
        'source_plan_id': sourcePlanId,
        'source_user_id': sourceUserId,
        'target_user_id': targetUserId,
        'target_plan_id': null,
        'status': 'PENDING',
        'created_at': nowIso,
        'responded_at': null,
      });

      await _createRequestNotification(
        txn: txn,
        requestId: requestId,
        targetUserId: targetUserId,
        sourcePlanId: sourcePlanId,
        senderName: _displayName(sender),
        planName: (sourcePlan['name'] ?? '').toString().trim(),
        createdAtIso: nowIso,
      );

      return requestId;
    });
  }

  @override
  Future<PlanCopyRequestDto?> getRequestById(int requestId) async {
    final db = await _database.db;
    final row = await _getRequest(db, requestId);
    if (row == null) return null;
    return PlanCopyRequestDto.fromMap(row);
  }

  @override
  Future<List<PlanCopyRequestDto>> getRequestsByIds(
    List<int> requestIds,
  ) async {
    if (requestIds.isEmpty) return const [];

    final db = await _database.db;
    final placeholders = List.filled(requestIds.length, '?').join(', ');
    final rows = await db.rawQuery('''
      SELECT *
      FROM plan_copy_requests
      WHERE id IN ($placeholders)
      ''', requestIds);
    return rows.map(PlanCopyRequestDto.fromMap).toList();
  }

  @override
  Future<int> acceptCopyRequest({
    required int requestId,
    required int targetUserId,
  }) async {
    final db = await _database.db;
    return db.transaction<int>((txn) async {
      final request = await _getRequest(txn, requestId);
      if (request == null) {
        throw Exception('Không tìm thấy lời mời nhận kế hoạch.');
      }

      final requestTargetUserId = request['target_user_id'] as int?;
      if (requestTargetUserId != targetUserId) {
        throw Exception('Bạn không có quyền xử lý lời mời này.');
      }

      final status = (request['status'] ?? 'PENDING').toString().toUpperCase();
      if (status == 'ACCEPTED') {
        throw Exception('Lời mời này đã được chấp nhận trước đó.');
      }
      if (status == 'REJECTED') {
        throw Exception('Lời mời này đã bị từ chối trước đó.');
      }
      if (status != 'PENDING') {
        throw Exception('Lời mời này không còn khả dụng.');
      }

      final sourcePlanId = request['source_plan_id'] as int?;
      final sourceUserId = request['source_user_id'] as int?;
      if (sourcePlanId == null || sourceUserId == null) {
        throw Exception('Lời mời chia sẻ hiện tại không hợp lệ.');
      }

      final existingCopy = await _findExistingCopy(
        txn,
        sourcePlanId: sourcePlanId,
        targetUserId: targetUserId,
      );
      if (existingCopy != null) {
        throw Exception('Bạn đã có bản sao của kế hoạch này rồi.');
      }

      final nowIso = DateTime.now().toIso8601String();
      final newPlanId = await _clonePlanToUser(
        txn: txn,
        sourcePlanId: sourcePlanId,
        sourceUserId: sourceUserId,
        targetUserId: targetUserId,
        createdAtIso: nowIso,
      );

      await txn.update(
        'plan_copy_requests',
        {
          'status': 'ACCEPTED',
          'target_plan_id': newPlanId,
          'responded_at': nowIso,
        },
        where: 'id = ?',
        whereArgs: [requestId],
      );

      return newPlanId;
    });
  }

  @override
  Future<void> rejectCopyRequest({
    required int requestId,
    required int targetUserId,
  }) async {
    final db = await _database.db;
    await db.transaction<void>((txn) async {
      final request = await _getRequest(txn, requestId);
      if (request == null) {
        throw Exception('Không tìm thấy lời mời nhận kế hoạch.');
      }

      final requestTargetUserId = request['target_user_id'] as int?;
      if (requestTargetUserId != targetUserId) {
        throw Exception('Bạn không có quyền xử lý lời mời này.');
      }

      final status = (request['status'] ?? 'PENDING').toString().toUpperCase();
      if (status == 'ACCEPTED') {
        throw Exception('Lời mời này đã được chấp nhận trước đó.');
      }
      if (status == 'REJECTED') {
        throw Exception('Lời mời này đã bị từ chối trước đó.');
      }
      if (status != 'PENDING') {
        throw Exception('Lời mời này không còn khả dụng.');
      }

      await txn.update(
        'plan_copy_requests',
        {
          'status': 'REJECTED',
          'responded_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [requestId],
      );
    });
  }

  Future<int> _clonePlanToUser({
    required DatabaseExecutor txn,
    required int sourcePlanId,
    required int sourceUserId,
    required int targetUserId,
    required String createdAtIso,
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

    final newPlanId = await txn.insert('plans', {
      'user_id': targetUserId,
      'name': (sourcePlan['name'] ?? '').toString(),
      'description': _nullableString(sourcePlan['description']),
      'start_date': (sourcePlan['start_date'] ?? '').toString(),
      'end_date': (sourcePlan['end_date'] ?? '').toString(),
      'participants': _nullableString(sourcePlan['participants']),
      'cover_image': _nullableString(sourcePlan['cover_image']),
      'note': _nullableString(sourcePlan['note']),
      'status': _clonedPlanStatus((sourcePlan['status'] ?? '').toString()),
      'created_at': createdAtIso,
      'updated_at': createdAtIso,
    });

    final dayIdMap = await _copyPlanDays(txn, sourcePlanId, newPlanId);
    final activityIdMap = await _copyActivities(txn, sourcePlanId, dayIdMap);
    await _copyChecklistItems(txn, sourcePlanId, newPlanId, activityIdMap);
    await _copyExpenses(
      txn,
      sourcePlanId,
      newPlanId,
      dayIdMap,
      activityIdMap,
      createdAtIso,
    );
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

  Future<Map<String, dynamic>?> _getPlan(
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

  Future<Map<String, dynamic>?> _getUser(
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

  Future<Map<String, dynamic>?> _getRequest(
    DatabaseExecutor db,
    int requestId,
  ) async {
    final rows = await db.query(
      'plan_copy_requests',
      where: 'id = ?',
      whereArgs: [requestId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<String, dynamic>?> _findPendingRequest(
    DatabaseExecutor db, {
    required int sourcePlanId,
    required int targetUserId,
  }) async {
    final rows = await db.query(
      'plan_copy_requests',
      where: 'source_plan_id = ? AND target_user_id = ? AND status = ?',
      whereArgs: [sourcePlanId, targetUserId, 'PENDING'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<String, dynamic>?> _findExistingCopy(
    DatabaseExecutor db, {
    required int sourcePlanId,
    required int targetUserId,
  }) async {
    final rows = await db.query(
      'plan_copy_sources',
      where: 'source_plan_id = ? AND target_user_id = ?',
      whereArgs: [sourcePlanId, targetUserId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<int, int>> _copyPlanDays(
    DatabaseExecutor db,
    int sourcePlanId,
    int newPlanId,
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
      final newDayId = await db.insert('plan_days', {
        'plan_id': newPlanId,
        'date': (row['date'] ?? '').toString(),
        'day_number': row['day_number'] as int? ?? 0,
      });
      dayIdMap[oldDayId] = newDayId;
    }
    return dayIdMap;
  }

  Future<Map<int, int>> _copyActivities(
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
        'status': (row['status'] ?? 'TODO').toString(),
      });
      activityIdMap[oldActivityId] = newActivityId;
    }
    return activityIdMap;
  }

  Future<void> _copyChecklistItems(
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
        'is_packed': row['is_packed'] as int? ?? 0,
        'source': (row['source'] ?? 'MANUAL').toString(),
        'linked_activity_id': oldLinkedActivityId == null
            ? null
            : activityIdMap[oldLinkedActivityId],
        'suggested_level': _nullableString(row['suggested_level']),
      });
    }
  }

  Future<void> _copyExpenses(
    DatabaseExecutor db,
    int sourcePlanId,
    int newPlanId,
    Map<int, int> dayIdMap,
    Map<int, int> activityIdMap,
    String nowIso,
  ) async {
    final rows = await db.query(
      'expenses',
      where: 'plan_id = ?',
      whereArgs: [sourcePlanId],
      orderBy: 'spent_at ASC, id ASC',
    );

    for (final row in rows) {
      final oldPlanDayId = row['plan_day_id'] as int?;
      final oldActivityId = row['activity_id'] as int?;
      await db.insert('expenses', {
        'plan_id': newPlanId,
        'plan_day_id': oldPlanDayId == null ? null : dayIdMap[oldPlanDayId],
        'activity_id': oldActivityId == null
            ? null
            : activityIdMap[oldActivityId],
        'title': (row['title'] ?? '').toString(),
        'amount': _nullableDouble(row['amount']) ?? 0,
        'category': (row['category'] ?? 'OTHER').toString(),
        'note': _nullableString(row['note']),
        'spent_at': (row['spent_at'] ?? nowIso).toString(),
        'created_at': nowIso,
        'updated_at': nowIso,
        'source': (row['source'] ?? 'MANUAL').toString(),
      });
    }
  }

  Future<void> _createRequestNotification({
    required DatabaseExecutor txn,
    required int requestId,
    required int targetUserId,
    required int sourcePlanId,
    required String senderName,
    required String planName,
    required String createdAtIso,
  }) async {
    final payload = jsonEncode({
      'planCopyRequestId': requestId,
      'sourcePlanId': sourcePlanId,
    });

    await txn.insert('notifications', {
      'user_id': targetUserId,
      'plan_id': null,
      'title': 'Bạn có một lời mời nhận kế hoạch',
      'body':
          '$senderName muốn chia sẻ cho bạn bản sao kế hoạch "${planName.isEmpty ? 'Không tên' : planName}".',
      'is_read': 0,
      'type': 'SYSTEM',
      'event_key': null,
      'scheduled_at': null,
      'created_at': createdAtIso,
      'read_at': null,
      'payload': payload,
    });
  }

  Future<void> _createCopySourceRecord({
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

  String _clonedPlanStatus(String rawStatus) {
    final normalized = rawStatus.trim().toLowerCase();
    if (normalized == 'archived') return 'active';
    return normalized.isEmpty ? 'active' : normalized;
  }

  String _displayName(Map<String, dynamic> userRow) {
    final fullName = (userRow['full_name'] ?? '').toString().trim();
    if (fullName.isNotEmpty) return fullName;
    final userName = (userRow['user_name'] ?? '').toString().trim();
    return userName.isNotEmpty ? userName : 'Một người dùng';
  }

  String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  double? _nullableDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
