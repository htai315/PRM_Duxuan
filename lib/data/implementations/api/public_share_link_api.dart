import 'package:du_xuan/data/dtos/share/create_public_share_link_request_dto.dart';
import 'package:du_xuan/data/dtos/share/public_share_link_dto.dart';
import 'package:du_xuan/data/dtos/share/update_public_share_link_request_dto.dart';
import 'package:du_xuan/data/implementations/local/db/app_database.dart';
import 'package:du_xuan/data/interfaces/api/i_public_share_link_api.dart';

class PublicShareLinkApi implements IPublicShareLinkApi {
  final AppDatabase _database;

  PublicShareLinkApi(this._database);

  @override
  Future<PublicShareLinkDto?> getById(int id) async {
    final db = await _database.db;
    final rows = await db.query(
      'public_share_links',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PublicShareLinkDto.fromMap(rows.first);
  }

  @override
  Future<PublicShareLinkDto?> getByPlanId(int planId) async {
    final db = await _database.db;
    final rows = await db.query(
      'public_share_links',
      where: 'plan_id = ?',
      whereArgs: [planId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PublicShareLinkDto.fromMap(rows.first);
  }

  @override
  Future<PublicShareLinkDto?> getByShareId(String shareId) async {
    final db = await _database.db;
    final rows = await db.query(
      'public_share_links',
      where: 'share_id = ?',
      whereArgs: [shareId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PublicShareLinkDto.fromMap(rows.first);
  }

  @override
  Future<int> create(CreatePublicShareLinkRequestDto req) async {
    final db = await _database.db;
    return db.insert('public_share_links', req.toMap());
  }

  @override
  Future<void> update(UpdatePublicShareLinkRequestDto req) async {
    final db = await _database.db;
    await db.update(
      'public_share_links',
      req.toMap(),
      where: 'id = ?',
      whereArgs: [req.id],
    );
  }

  @override
  Future<void> deleteByPlanId(int planId) async {
    final db = await _database.db;
    await db.delete(
      'public_share_links',
      where: 'plan_id = ?',
      whereArgs: [planId],
    );
  }
}
