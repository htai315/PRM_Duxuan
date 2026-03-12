import 'package:du_xuan/data/dtos/checklist/checklist_item_dto.dart';
import 'package:du_xuan/data/dtos/checklist/create_checklist_request_dto.dart';
import 'package:du_xuan/data/dtos/checklist/update_checklist_request_dto.dart';
import 'package:du_xuan/data/implementations/local/db/app_database.dart';
import 'package:du_xuan/data/interfaces/api/i_checklist_api.dart';

class ChecklistApi implements IChecklistApi {
  final AppDatabase _database;
  ChecklistApi(this._database);

  @override
  Future<List<ChecklistItemDto>> getByPlanId(int planId) async {
    final db = await _database.db;
    final rows = await db.query(
      'checklist_items',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'category ASC, priority DESC, name ASC',
    );
    return rows.map(ChecklistItemDto.fromMap).toList();
  }

  @override
  Future<ChecklistItemDto?> getById(int id) async {
    final db = await _database.db;
    final rows = await db.query(
      'checklist_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ChecklistItemDto.fromMap(rows.first);
  }

  @override
  Future<int> create(CreateChecklistRequestDto req) async {
    final db = await _database.db;
    return db.insert('checklist_items', req.toMap());
  }

  @override
  Future<void> update(UpdateChecklistRequestDto req) async {
    final db = await _database.db;
    await db.update(
      'checklist_items',
      req.toMap(),
      where: 'id = ?',
      whereArgs: [req.id],
    );
  }

  @override
  Future<void> delete(int id) async {
    final db = await _database.db;
    await db.delete('checklist_items', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> togglePacked(int id) async {
    final db = await _database.db;
    // Flip is_packed: 0→1, 1→0 bằng SQL trực tiếp
    await db.rawUpdate(
      'UPDATE checklist_items SET is_packed = CASE WHEN is_packed = 0 THEN 1 ELSE 0 END WHERE id = ?',
      [id],
    );
  }
}
