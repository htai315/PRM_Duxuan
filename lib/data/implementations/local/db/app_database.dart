import 'package:du_xuan/data/implementations/local/password_hasher.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const int _dbVersion = 1;

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
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedDefaultUsers(db);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await _createUsersTable(db);
    await _createSessionTable(db);
    await _createPlansTable(db);
    await _createPlanCopyRequestsTable(db);
    await _createPlanCopySourcesTable(db);
    await _createPublicShareLinksTable(db);
    await _createPlanDaysTable(db);
    await _createDestinationsTable(db);
    await _createActivitiesTable(db);
    await _createExpensesTable(db);
    await _createChecklistItemsTable(db);
    await _createNotificationsTable(db);
    await _createIndexes(db);
  }

  Future<void> _createUsersTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_name TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createSessionTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS session(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        user_id INTEGER NOT NULL,
        token TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
  }

  Future<void> _createPlansTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plans(
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
  }

  Future<void> _createPublicShareLinksTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS public_share_links(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL UNIQUE,
        share_id TEXT NOT NULL UNIQUE,
        slug TEXT NOT NULL UNIQUE,
        public_url TEXT NOT NULL,
        owner_token TEXT NOT NULL,
        snapshot_version INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_synced_at TEXT NOT NULL,
        revoked_at TEXT,
        FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createPlanCopyRequestsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plan_copy_requests(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_plan_id INTEGER NOT NULL,
        source_user_id INTEGER NOT NULL,
        target_user_id INTEGER NOT NULL,
        target_plan_id INTEGER,
        status TEXT NOT NULL DEFAULT 'PENDING',
        created_at TEXT NOT NULL,
        responded_at TEXT,
        FOREIGN KEY (source_plan_id) REFERENCES plans(id) ON DELETE CASCADE,
        FOREIGN KEY (source_user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (target_user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (target_plan_id) REFERENCES plans(id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _createPlanCopySourcesTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plan_copy_sources(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_plan_id INTEGER NOT NULL,
        source_user_id INTEGER NOT NULL,
        target_plan_id INTEGER NOT NULL UNIQUE,
        target_user_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (source_plan_id) REFERENCES plans(id) ON DELETE CASCADE,
        FOREIGN KEY (source_user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (target_plan_id) REFERENCES plans(id) ON DELETE CASCADE,
        FOREIGN KEY (target_user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(source_plan_id, target_user_id)
      )
    ''');
  }

  Future<void> _createPlanDaysTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plan_days(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        day_number INTEGER NOT NULL,
        FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createDestinationsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS destinations(
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
  }

  Future<void> _createActivitiesTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activities(
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
  }

  Future<void> _createExpensesTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        plan_day_id INTEGER,
        activity_id INTEGER,
        title TEXT NOT NULL,
        amount REAL NOT NULL CHECK(amount >= 0),
        category TEXT NOT NULL DEFAULT 'OTHER',
        note TEXT,
        spent_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'MANUAL',
        FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE CASCADE,
        FOREIGN KEY (plan_day_id) REFERENCES plan_days(id) ON DELETE SET NULL,
        FOREIGN KEY (activity_id) REFERENCES activities(id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _createChecklistItemsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS checklist_items(
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
  }

  Future<void> _createNotificationsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        plan_id INTEGER,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        type TEXT DEFAULT 'SYSTEM',
        event_key TEXT UNIQUE,
        scheduled_at TEXT,
        created_at TEXT NOT NULL,
        read_at TEXT,
        payload TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createIndexes(DatabaseExecutor db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_plans_user_id ON plans(user_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_plan_days_plan_id ON plan_days(plan_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_public_share_links_last_synced_at ON public_share_links(last_synced_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_plan_copy_requests_target_user_status ON plan_copy_requests(target_user_id, status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_plan_copy_requests_source_target ON plan_copy_requests(source_plan_id, target_user_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_plan_copy_requests_target_plan_id ON plan_copy_requests(target_plan_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_plan_copy_sources_target_plan_id ON plan_copy_sources(target_plan_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_plan_copy_sources_target_user_id ON plan_copy_sources(target_user_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_activities_plan_day_id ON activities(plan_day_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_expenses_plan_id ON expenses(plan_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_expenses_plan_day_id ON expenses(plan_day_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_expenses_activity_id ON expenses(activity_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_expenses_spent_at ON expenses(spent_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_checklist_items_plan_id ON checklist_items(plan_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notifications_user_schedule ON notifications(user_id, scheduled_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notifications_plan_id ON notifications(plan_id)',
    );
  }

  Future<void> _seedDefaultUsers(Database db) async {
    if (!kDebugMode) return;
    final now = DateTime.now().toIso8601String();
    final defaultHash = PasswordHasher.sha256Hash('123456');

    await db.insert('users', {
      'user_name': 'nhanle',
      'full_name': 'Nguyễn Thị Nhàn',
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
  }
}
