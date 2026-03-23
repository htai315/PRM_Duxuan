import 'package:du_xuan/data/dtos/login/user_dto.dart';
import 'package:du_xuan/data/implementations/local/db/app_database.dart';
import 'package:du_xuan/data/interfaces/api/i_user_api.dart';

class UserApi implements IUserApi {
  final AppDatabase _database;

  UserApi(this._database);

  @override
  Future<UserDto?> getById(int id) async {
    final db = await _database.db;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserDto.fromMap(rows.first);
  }

  @override
  Future<List<UserDto>> getAll({int? excludeUserId}) async {
    final db = await _database.db;
    final rows = await db.query(
      'users',
      where: excludeUserId != null ? 'id != ?' : null,
      whereArgs: excludeUserId != null ? [excludeUserId] : null,
      orderBy: 'LOWER(full_name) ASC, LOWER(user_name) ASC',
    );
    return rows.map(UserDto.fromMap).toList();
  }

  @override
  Future<List<UserDto>> search(
    String query, {
    int? excludeUserId,
    int limit = 20,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const [];
    }

    final db = await _database.db;
    final pattern = '%$normalized%';
    final hasExcludeUser = excludeUserId != null;

    final rows = await db.query(
      'users',
      where: hasExcludeUser
          ? 'id != ? AND (LOWER(full_name) LIKE ? OR LOWER(user_name) LIKE ?)'
          : 'LOWER(full_name) LIKE ? OR LOWER(user_name) LIKE ?',
      whereArgs: hasExcludeUser
          ? [excludeUserId, pattern, pattern]
          : [pattern, pattern],
      orderBy: 'LOWER(full_name) ASC, LOWER(user_name) ASC',
      limit: limit,
    );

    return rows.map(UserDto.fromMap).toList();
  }
}
