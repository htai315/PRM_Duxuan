import 'package:du_xuan/data/implementations/local/password_hasher.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'du_xuan.db');

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        // Bật foreign key enforcement
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        // 1. BẢNG AUTH
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_name TEXT NOT NULL UNIQUE,
            full_name TEXT NOT NULL,
            password_hash TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE session(
            id INTEGER PRIMARY KEY CHECK (id = 1),
            user_id INTEGER NOT NULL,
            token TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        ''');
        // 2. BẢNG NGHIỆP VỤ

        await db.execute('''
          CREATE TABLE plans(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            start_date TEXT NOT NULL,
            end_date TEXT NOT NULL,
            participants TEXT,
            cover_image TEXT,
            note TEXT,
            status TEXT NOT NULL DEFAULT 'DRAFT',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE plan_days(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plan_id INTEGER NOT NULL,
            date TEXT NOT NULL,
            day_number INTEGER NOT NULL,
            FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE CASCADE
          )
        ''');

        // destinations tạo TRƯỚC activities (vì activities FK tới đây)
        await db.execute('''
          CREATE TABLE destinations(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plan_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            address TEXT,
            lat REAL,
            lng REAL,
            type TEXT DEFAULT 'OTHER',
            note TEXT,
            map_link TEXT,
            image_path TEXT,
            FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE activities(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plan_day_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            activity_type TEXT DEFAULT 'OTHER',
            start_time TEXT,
            end_time TEXT,
            destination_id INTEGER,
            location_text TEXT,
            note TEXT,
            estimated_cost REAL,
            priority INTEGER DEFAULT 0,
            order_index INTEGER DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'TODO',
            FOREIGN KEY (plan_day_id) REFERENCES plan_days(id) ON DELETE CASCADE,
            FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE SET NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE checklist_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plan_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            quantity INTEGER DEFAULT 1 CHECK(quantity >= 1),
            category TEXT DEFAULT 'OTHER',
            note TEXT,
            priority INTEGER DEFAULT 0,
            is_packed INTEGER DEFAULT 0,
            source TEXT DEFAULT 'MANUAL',
            linked_activity_id INTEGER,
            suggested_level TEXT,
            FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE CASCADE,
            FOREIGN KEY (linked_activity_id) REFERENCES activities(id) ON DELETE SET NULL
          )
        ''');

        // ═══════════════════════════════════════════════
        // 3. SEED DATA: 3 tài khoản test
        // ═══════════════════════════════════════════════

        final now = DateTime.now().toIso8601String();
        final defaultHash = PasswordHasher.sha256Hash('123456');

        await db.insert('users', {
          'user_name': 'admin',
          'full_name': 'Quản trị viên',
          'password_hash': defaultHash,
          'created_at': now,
        });

        await db.insert('users', {
          'user_name': 'htai',
          'full_name': 'Nguyễn Hữu Tài',
          'password_hash': defaultHash,
          'created_at': now,
        });

        await db.insert('users', {
          'user_name': 'guest',
          'full_name': 'Khách',
          'password_hash': defaultHash,
          'created_at': now,
        });
      },
    );
  }
}
