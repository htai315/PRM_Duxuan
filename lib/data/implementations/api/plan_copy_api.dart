import 'dart:convert';

import 'package:du_xuan/data/dtos/share/plan_copy_request_dto.dart';
import 'package:du_xuan/data/implementations/api/plan_clone_service.dart';
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
    required DateTime newStartDate,
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
      final newPlanId = await PlanCloneService.clonePlanToUser(
        txn: txn,
        sourcePlanId: sourcePlanId,
        sourceUserId: sourceUserId,
        targetUserId: targetUserId,
        createdAtIso: nowIso,
        newStartDate: newStartDate,
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

  // ─── Private helpers ─────────────────────────────────

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
      'title': 'Bạn có một lời mời nhận mẫu kế hoạch',
      'body':
          '$senderName muốn chia sẻ cho bạn mẫu kế hoạch "${planName.isEmpty ? 'Không tên' : planName}".',
      'is_read': 0,
      'type': 'SYSTEM',
      'event_key': null,
      'scheduled_at': null,
      'created_at': createdAtIso,
      'read_at': null,
      'payload': payload,
    });
  }

  String _displayName(Map<String, dynamic> userRow) {
    final fullName = (userRow['full_name'] ?? '').toString().trim();
    if (fullName.isNotEmpty) return fullName;
    final userName = (userRow['user_name'] ?? '').toString().trim();
    return userName.isNotEmpty ? userName : 'Một người dùng';
  }
}
