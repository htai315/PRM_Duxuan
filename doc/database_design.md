# 🗄️ DATABASE DESIGN — Du Xuân Planner

## Sơ Đồ Quan Hệ (ERD)

```
┌────────────┐
│   users    │
├────────────┤        ┌─────────────┐
│ PK id      │───1:1──│   session   │
│ user_name  │        ├─────────────┤
│ full_name  │        │ PK id (=1)  │
│ pwd_hash   │        │ FK user_id  │
│ created_at │        │ token       │
└─────┬──────┘        │ created_at  │
      │               └─────────────┘
      │ 1:N (owner)
      ▼
┌─────────────────┐    1:N    ┌───────────────┐    1:N    ┌─────────────────┐
│     plans       │──────────▶│   plan_days   │──────────▶│   activities    │
├─────────────────┤           ├───────────────┤           ├─────────────────┤
│ PK id           │           │ PK id         │           │ PK id           │
│ FK user_id      │           │ FK plan_id    │           │ FK plan_day_id  │
│ name            │           │ date          │           │ title           │
│ description     │           │ day_number    │           │ activity_type   │
│ start_date      │           └───────────────┘           │ start_time      │
│ end_date        │                                       │ end_time        │
│ participants    │    1:N    ┌─────────────────┐          │ FK dest_id      │
│ cover_image     │──────────▶│ checklist_items │          │ location_text   │
│ note            │           ├─────────────────┤          │ note            │
│ status          │           │ PK id           │          │ estimated_cost  │
│ created_at      │           │ FK plan_id      │          │ priority        │
│ updated_at      │           │ name            │          │ order_index     │
└────────┬────────┘           │ quantity        │          │ status          │
         │                    │ category        │          └────────┬────────┘
         │ 1:N                │ note            │                   │
         ▼                    │ priority        │              N:1 (optional)
┌─────────────────┐           │ is_packed       │                   │
│  destinations   │           │ source          │                   ▼
├─────────────────┤           │ FK linked_act_id│           ┌───────────────┐
│ PK id           │           │ suggested_level │           │  destinations │
│ FK plan_id      │           └─────────────────┘           │  (cùng bảng)  │
│ name            │                                         └───────────────┘
│ address         │
│ lat             │
│ lng             │
│ type            │
│ note            │
│ map_link        │
│ image_path      │
└─────────────────┘
```

---

## Chi Tiết Từng Bảng

### 1. `users` — Quản lý tài khoản

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| `id` | INTEGER | PK, AUTOINCREMENT | ID tự tăng |
| `user_name` | TEXT | NOT NULL, UNIQUE | Tên đăng nhập |
| `full_name` | TEXT | NOT NULL | Tên hiển thị |
| `password_hash` | TEXT | NOT NULL | Mật khẩu SHA-256 |
| `created_at` | TEXT | NOT NULL | Ngày tạo (ISO 8601) |

**Seed data (3 tài khoản test):**

| user_name | full_name | password |
|-----------|-----------|----------|
| `admin` | Quản trị viên | `123456` |
| `chung` | Nguyễn Văn Chung | `123456` |
| `guest` | Khách | `123456` |

---

### 2. `session` — Phiên đăng nhập

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| `id` | INTEGER | PK, CHECK(id=1) | Luôn = 1 (chỉ 1 session) |
| `user_id` | INTEGER | NOT NULL, FK → users(id) | Ai đang đăng nhập |
| `token` | TEXT | NOT NULL | Token giả lập |
| `created_at` | TEXT | NOT NULL | Thời điểm đăng nhập |

---

### 3. `plans` — Kế hoạch du xuân

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| `id` | INTEGER | PK, AUTOINCREMENT | |
| `user_id` | INTEGER | NOT NULL, FK → users(id) | Chủ sở hữu kế hoạch |
| `name` | TEXT | NOT NULL | Tên kế hoạch (BR-P01) |
| `description` | TEXT | | Mô tả |
| `start_date` | TEXT | NOT NULL | Ngày bắt đầu (yyyy-MM-dd) |
| `end_date` | TEXT | NOT NULL | Ngày kết thúc (BR-P02: ≥ start_date) |
| `participants` | TEXT | | Danh sách người đi (text tự do) |
| `cover_image` | TEXT | | Đường dẫn ảnh bìa |
| `note` | TEXT | | Ghi chú chung |
| `status` | TEXT | NOT NULL, DEFAULT 'DRAFT' | DRAFT/ACTIVE/COMPLETED/ARCHIVED |
| `created_at` | TEXT | NOT NULL | |
| `updated_at` | TEXT | NOT NULL | |

> ⚠️ **plans.user_id** đảm bảo mỗi user chỉ thấy kế hoạch của mình khi query.

---

### 4. `plan_days` — Ngày trong kế hoạch

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| `id` | INTEGER | PK, AUTOINCREMENT | |
| `plan_id` | INTEGER | NOT NULL, FK → plans(id) ON DELETE CASCADE | |
| `date` | TEXT | NOT NULL | Ngày cụ thể (yyyy-MM-dd) |
| `day_number` | INTEGER | NOT NULL | Ngày thứ mấy (1, 2, 3...) |

> Tự sinh khi tạo Plan (BR-P03). Ví dụ: Plan 28/01 → 30/01 sẽ tạo 3 PlanDay.

---

### 5. `activities` — Hoạt động

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| `id` | INTEGER | PK, AUTOINCREMENT | |
| `plan_day_id` | INTEGER | NOT NULL, FK → plan_days(id) ON DELETE CASCADE | Thuộc ngày nào (BR-I01) |
| `title` | TEXT | NOT NULL | Tên hoạt động (BR-I02) |
| `activity_type` | TEXT | DEFAULT 'OTHER' | TEMPLE_VISIT, FAMILY_VISIT, DINING, PICNIC, SHOPPING, MOTORBIKE_TRIP, CHECKIN_PHOTO, OTHER |
| `start_time` | TEXT | | Giờ bắt đầu (HH:mm) |
| `end_time` | TEXT | | Giờ kết thúc (BR-I03: ≥ start_time) |
| `destination_id` | INTEGER | FK → destinations(id) ON DELETE SET NULL | Gắn điểm đến (optional) |
| `location_text` | TEXT | | Địa điểm dạng text (MVP) |
| `note` | TEXT | | Ghi chú |
| `estimated_cost` | REAL | | Chi phí ước tính |
| `priority` | INTEGER | DEFAULT 0 | 0=bình thường, 1=quan trọng |
| `order_index` | INTEGER | DEFAULT 0 | Thứ tự sắp xếp |
| `status` | TEXT | NOT NULL, DEFAULT 'TODO' | TODO/IN_PROGRESS/DONE |

---

### 6. `checklist_items` — Vật dụng mang theo

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| `id` | INTEGER | PK, AUTOINCREMENT | |
| `plan_id` | INTEGER | NOT NULL, FK → plans(id) ON DELETE CASCADE | Thuộc plan nào |
| `name` | TEXT | NOT NULL | Tên vật dụng (BR-C01) |
| `quantity` | INTEGER | DEFAULT 1, CHECK(quantity >= 1) | Số lượng (BR-C02) |
| `category` | TEXT | DEFAULT 'OTHER' | DOCUMENTS, CLOTHING, ELECTRONICS, FOOD, MEDICINE, TOILETRIES, MONEY, RELIGIOUS, OTHER |
| `note` | TEXT | | Ghi chú |
| `priority` | INTEGER | DEFAULT 0 | 0=bình thường, 1=quan trọng |
| `is_packed` | INTEGER | DEFAULT 0 | 0=chưa, 1=đã chuẩn bị |
| `source` | TEXT | DEFAULT 'MANUAL' | MANUAL / SUGGESTED |
| `linked_activity_id` | INTEGER | FK → activities(id) ON DELETE SET NULL | Activity đã gợi ý item này |
| `suggested_level` | TEXT | | REQUIRED / RECOMMENDED / OPTIONAL |

---

### 7. `destinations` — Điểm đến

| Cột | Kiểu | Ràng buộc | Mô tả |
|-----|------|-----------|-------|
| `id` | INTEGER | PK, AUTOINCREMENT | |
| `plan_id` | INTEGER | NOT NULL, FK → plans(id) ON DELETE CASCADE | Thuộc plan nào |
| `name` | TEXT | NOT NULL | Tên điểm đến |
| `address` | TEXT | | Địa chỉ |
| `lat` | REAL | | Vĩ độ (optional - BR-D02) |
| `lng` | REAL | | Kinh độ (optional) |
| `type` | TEXT | DEFAULT 'OTHER' | TEMPLE, RESTAURANT, CAFE, RELATIVE_HOME, PARK, CHECKIN, OTHER |
| `note` | TEXT | | Ghi chú |
| `map_link` | TEXT | | Link Google Maps |
| `image_path` | TEXT | | Ảnh điểm đến |

---

## Foreign Key & Cascade Summary

```
users.id ──────→ session.user_id
users.id ──────→ plans.user_id

plans.id ──────→ plan_days.plan_id          (ON DELETE CASCADE)
plans.id ──────→ checklist_items.plan_id    (ON DELETE CASCADE)
plans.id ──────→ destinations.plan_id       (ON DELETE CASCADE)

plan_days.id ──→ activities.plan_day_id     (ON DELETE CASCADE)

destinations.id → activities.destination_id  (ON DELETE SET NULL)
activities.id ──→ checklist_items.linked_activity_id (ON DELETE SET NULL)
```

**Giải thích:**
- **CASCADE**: Xóa Plan → tự xóa tất cả plan_days, checklist_items, destinations. Xóa PlanDay → tự xóa activities.
- **SET NULL**: Xóa Destination → activities.destination_id = NULL (activity vẫn còn, chỉ mất liên kết). Xóa Activity → checklist_items.linked_activity_id = NULL (item vẫn còn trong checklist).

---

## SQL Tạo Bảng

```sql
-- 1. users
CREATE TABLE users(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_name TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TEXT NOT NULL
);

-- 2. session
CREATE TABLE session(
  id INTEGER PRIMARY KEY CHECK (id = 1),
  user_id INTEGER NOT NULL,
  token TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 3. plans
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
);

-- 4. plan_days
CREATE TABLE plan_days(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  plan_id INTEGER NOT NULL,
  date TEXT NOT NULL,
  day_number INTEGER NOT NULL,
  FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE CASCADE
);

-- 5. destinations (tạo TRƯỚC activities vì activities FK tới đây)
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
);

-- 6. activities
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
);

-- 7. checklist_items
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
);

-- SEED: 3 tài khoản test
INSERT INTO users (user_name, full_name, password_hash, created_at) VALUES
  ('admin', 'Quản trị viên', '<sha256_of_123456>', '<now>'),
  ('chung', 'Nguyễn Văn Chung', '<sha256_of_123456>', '<now>'),
  ('guest', 'Khách', '<sha256_of_123456>', '<now>');
```

> ⚠️ SQLite cần `PRAGMA foreign_keys = ON;` để enforce foreign keys.
