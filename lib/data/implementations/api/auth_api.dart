import 'package:du_xuan/data/dtos/login/login_request_dto.dart';
import 'package:du_xuan/data/dtos/login/login_response_dto.dart';
import 'package:du_xuan/data/dtos/login/register_request_dto.dart';
import 'package:du_xuan/data/dtos/login/user_dto.dart';
import 'package:du_xuan/data/implementations/local/db/app_database.dart';
import 'package:du_xuan/data/implementations/local/password_hasher.dart';
import 'package:du_xuan/data/interfaces/api/iauth_api.dart';
import 'package:sqflite/sqflite.dart';

class AuthApi implements IAuthApi {
  final AppDatabase _database;

  AuthApi(this._database);

  @override
  Future<LoginResponseDto> login(LoginRequestDto req) async {
    final db = await _database.db;

    // Tìm user theo username
    final rows = await db.query(
      'users',
      where: 'user_name = ?',
      whereArgs: [req.userName],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw Exception('Sai tài khoản hoặc mật khẩu');
    }

    final userRow = rows.first;
    final storedHash = (userRow['password_hash'] ?? '').toString();
    final inputHash = PasswordHasher.sha256Hash(req.password);

    if (storedHash != inputHash) {
      throw Exception('Sai tài khoản hoặc mật khẩu');
    }

    // Tạo session
    return _createSession(db, userRow);
  }

  @override
  Future<LoginResponseDto> register(RegisterRequestDto req) async {
    final db = await _database.db;

    return db.transaction<LoginResponseDto>((txn) async {
      // Kiểm tra username đã tồn tại chưa
      final existing = await txn.query(
        'users',
        where: 'user_name = ?',
        whereArgs: [req.userName],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        throw Exception('Tên đăng nhập đã tồn tại');
      }

      // Tạo user mới
      final now = DateTime.now().toIso8601String();
      final userId = await txn.insert('users', {
        'user_name': req.userName,
        'full_name': req.fullName,
        'password_hash': PasswordHasher.sha256Hash(req.password),
        'created_at': now,
      });

      // Lấy user vừa tạo
      final rows = await txn.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      // Tự động đăng nhập sau đăng ký
      return _createSession(txn, rows.first);
    });
  }

  @override
  Future<LoginResponseDto?> getCurrentSession() async {
    final db = await _database.db;

    final sessions = await db.query('session', where: 'id = 1', limit: 1);
    if (sessions.isEmpty) return null;

    final sessionRow = sessions.first;
    final userId = sessionRow['user_id'] as int;
    final token = (sessionRow['token'] ?? '').toString();

    final users = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (users.isEmpty) return null;

    return LoginResponseDto(
      token: token,
      user: UserDto.fromMap(users.first),
    );
  }

  @override
  Future<void> logout() async {
    final db = await _database.db;
    await db.delete('session', where: 'id = 1');
  }

  // ─── HELPER ───────────────────────────────────────────

  /// Tạo session token và lưu vào DB, trả về LoginResponseDto
  Future<LoginResponseDto> _createSession(
    DatabaseExecutor db,
    Map<String, dynamic> userRow,
  ) async {
    final userId = userRow['id'] as int;
    final token = 'token_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'session',
      {
        'id': 1,
        'user_id': userId,
        'token': token,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return LoginResponseDto(
      token: token,
      user: UserDto.fromMap(userRow),
    );
  }
  @override
  Future<void> changePassword(
    int userId,
    String oldPassword,
    String newPassword,
  ) async {
    final db = await _database.db;

    // 1. Lấy user hiện tại
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw Exception('Không tìm thấy tài khoản');
    }

    // 2. Verify mật khẩu cũ
    final storedHash = (rows.first['password_hash'] ?? '').toString();
    final oldHash = PasswordHasher.sha256Hash(oldPassword);

    if (storedHash != oldHash) {
      throw Exception('Mật khẩu cũ không chính xác');
    }

    // 3. Update mật khẩu mới
    final newHash = PasswordHasher.sha256Hash(newPassword);
    await db.update(
      'users',
      {'password_hash': newHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
