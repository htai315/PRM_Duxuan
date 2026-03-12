# 📋 DU XUÂN PLANNER — TÀI LIỆU PHÂN TÍCH DỰ ÁN

---

## I. TỔNG QUAN DỰ ÁN

### 1.1. Bài Toán
Ứng dụng **Du Xuân Planner** giải quyết các vấn đề khi chuẩn bị chuyến du xuân Tết:
- Quên mang vật dụng quan trọng
- Lịch trình không rõ ràng, khó theo dõi theo nhóm/gia đình
- Địa điểm phân tán, khó chỉ đường
- Khó chia sẻ kế hoạch
- Không biết cần mang gì cho từng hoạt động

### 1.2. Mục Tiêu
- Lập kế hoạch theo chuyến đi (Plan)
- Quản lý lịch trình theo ngày + hoạt động chi tiết
- Checklist đồ mang theo + gợi ý thông minh
- Quản lý điểm đến + bản đồ
- Chia sẻ kế hoạch text / link

### 1.3. Tech Stack

| Thành phần | Công nghệ |
|------------|-----------|
| **Nền tảng** | Flutter/Dart (Android first, mở rộng iOS) |
| **Kiến trúc** | MVVM + Clean Architecture |
| **Database** | SQLite (sqflite) — offline-first |
| **State Management** | Provider (ChangeNotifier) |
| **Auth** | SQLite giả lập (mock API) |
| **Mã hóa** | SHA-256 (package `crypto`) |
| **Fonts** | Google Fonts |
| **Thông báo** | flutter_local_notifications |
| **Chia sẻ** | share_plus |
| **Bản đồ** | url_launcher (MVP) / google_maps_flutter (mở rộng) |

---

## II. TỔ CHỨC SOURCE CODE

### 2.1. Kiến Trúc Tổng Quan

```
┌─────────────────────────────────────────────┐
│                   Views                     │  ← UI (Widgets)
│         (StatelessWidget / StatefulWidget)   │
└──────────────────┬──────────────────────────┘
                   │ ListenableBuilder / Consumer
┌──────────────────▼──────────────────────────┐
│              ViewModels                     │  ← Business Logic + UI State
│           (ChangeNotifier)                  │
└──────────────────┬──────────────────────────┘
                   │ gọi methods trên interface
┌──────────────────▼──────────────────────────┐
│           Data Layer                        │
│  interfaces/ → Repository + API + Mapper    │
│  implementations/ → Code thực thi           │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│        Domain (Entities thuần)              │
└─────────────────────────────────────────────┘
```

### 2.2. Cấu Trúc Thư Mục Chi Tiết (94 files)

```
lib/
├── main.dart                                  # Entry point, MaterialApp, theme, route
├── di.dart                                    # Dependency Injection (build VM functions)
│
├── core/                                      # ─── DÙNG CHUNG ───
│   ├── constants/
│   │   ├── app_colors.dart                    # Bảng màu Tết (đỏ, vàng, cam)
│   │   ├── app_text_styles.dart               # Text styles chuẩn (Google Fonts)
│   │   └── app_constants.dart                 # Hằng số, suggestion templates
│   ├── enums/
│   │   ├── plan_status.dart                   # DRAFT / ACTIVE / COMPLETED / ARCHIVED
│   │   ├── activity_type.dart                 # TEMPLE_VISIT, FAMILY_VISIT, DINING...
│   │   ├── activity_status.dart               # TODO / IN_PROGRESS / DONE
│   │   ├── checklist_category.dart            # DOCUMENTS, CLOTHING, ELECTRONICS...
│   │   ├── destination_type.dart              # TEMPLE, RESTAURANT, CAFE...
│   │   └── suggestion_level.dart              # REQUIRED / RECOMMENDED / OPTIONAL
│   ├── theme/
│   │   └── app_theme.dart                     # ThemeData toàn app
│   ├── errors/
│   │   └── app_exception.dart                 # Exception hierarchy
│   └── utils/
│       ├── date_utils.dart                    # Format ngày, tính số ngày
│       ├── string_utils.dart                  # Trim, lowercase, normalize
│       └── share_formatter.dart               # Format text chia sẻ
│
├── domain/                                    # ─── ENTITY THUẦN ───
│   └── entities/
│       ├── user.dart                          # User(id, userName)
│       ├── auth_session.dart                  # AuthSession(token, user)
│       ├── plan.dart                          # Plan(id, name, startDate, endDate, status...)
│       ├── plan_day.dart                      # PlanDay(id, planId, date, dayNumber)
│       ├── activity.dart                      # Activity(id, planDayId, title, type, time...)
│       ├── checklist_item.dart                # ChecklistItem(id, planId, name, isPacked...)
│       └── destination.dart                   # Destination(id, planId, name, lat, lng...)
│
├── data/                                      # ─── DATA LAYER ───
│   ├── dtos/
│   │   ├── login/
│   │   │   ├── login_request_dto.dart         # { userName, password }
│   │   │   ├── login_response_dto.dart        # { token, UserDto }
│   │   │   └── user_dto.dart                  # fromJson + fromMap (SQLite)
│   │   ├── plan_dto.dart
│   │   ├── activity_dto.dart
│   │   ├── checklist_item_dto.dart
│   │   └── destination_dto.dart
│   │
│   ├── interfaces/                            # Hợp đồng (abstract class)
│   │   ├── api/
│   │   │   ├── iauth_api.dart                 # login, getCurrentSession, logout
│   │   │   ├── i_plan_api.dart                # CRUD Plan
│   │   │   ├── i_activity_api.dart            # CRUD Activity
│   │   │   ├── i_checklist_api.dart           # CRUD ChecklistItem
│   │   │   └── i_destination_api.dart         # CRUD Destination
│   │   ├── mapper/
│   │   │   └── imapper.dart                   # IMapper<I, O> { O map(I input); }
│   │   └── repositories/
│   │       ├── iauth_repository.dart          # login, logout, getCurrentSession
│   │       ├── i_plan_repository.dart         # CRUD Plan + PlanDay
│   │       ├── i_activity_repository.dart     # CRUD Activity
│   │       ├── i_checklist_repository.dart    # CRUD ChecklistItem
│   │       └── i_destination_repository.dart  # CRUD Destination
│   │
│   └── implementations/                       # Code thực thi
│       ├── api/                               # Giả lập API bằng SQLite
│       │   ├── auth_api.dart                  # ✅ Login/session qua SQLite
│       │   ├── plan_api.dart                  # CRUD plans table
│       │   ├── activity_api.dart              # CRUD activities table
│       │   ├── checklist_api.dart             # CRUD checklist_items table
│       │   └── destination_api.dart           # CRUD destinations table
│       ├── local/
│       │   ├── db/
│       │   │   └── app_database.dart          # SQLite schema (7 bảng) + seed data
│       │   ├── password_hasher.dart           # SHA-256 hash
│       │   └── dao/                           # SQL queries thuần
│       │       ├── plan_dao.dart
│       │       ├── activity_dao.dart
│       │       ├── checklist_dao.dart
│       │       └── destination_dao.dart
│       ├── mapper/                            # DTO ↔ Entity
│       │   ├── auth_mapper.dart               # ✅ LoginResponseDto → AuthSession
│       │   ├── plan_mapper.dart
│       │   ├── activity_mapper.dart
│       │   ├── checklist_mapper.dart
│       │   └── destination_mapper.dart
│       └── repositories/                      # Orchestrator: API + Mapper + Rules
│           ├── auth_repository.dart           # ✅ Hoàn chỉnh
│           ├── plan_repository_impl.dart
│           ├── activity_repository_impl.dart
│           ├── checklist_repository_impl.dart
│           └── destination_repository_impl.dart
│
├── services/                                  # ─── LOGIC ĐẶC BIỆT ───
│   ├── suggestion_service.dart                # Gợi ý vật dụng theo activityType
│   ├── duplicate_detector.dart                # Kiểm tra trùng checklist item
│   ├── share_service.dart                     # Tạo payload chia sẻ text
│   └── reminder_service.dart                  # Local notifications
│
├── viewmodels/                                # ─── STATE MANAGEMENT ───
│   ├── login/
│   │   └── login_viewmodel.dart               # ✅ Login form + auth state
│   ├── plan/
│   │   ├── plan_list_viewmodel.dart           # Danh sách kế hoạch
│   │   └── plan_detail_viewmodel.dart         # Chi tiết 1 plan
│   ├── itinerary/
│   │   └── itinerary_viewmodel.dart           # Lịch trình + activity
│   ├── checklist/
│   │   └── checklist_viewmodel.dart           # Checklist + tiến độ
│   ├── destination/
│   │   └── destination_viewmodel.dart         # Điểm đến
│   ├── suggestion/
│   │   └── suggestion_viewmodel.dart          # Gợi ý vật dụng
│   └── share/
│       └── share_viewmodel.dart               # Chia sẻ kế hoạch
│
├── views/                                     # ─── UI WIDGETS ───
│   ├── login/
│   │   └── login_page.dart                    # ✅ Trang đăng nhập
│   ├── plan/
│   │   ├── plan_list_page.dart                # Danh sách kế hoạch
│   │   ├── plan_form_page.dart                # Tạo/sửa kế hoạch
│   │   └── plan_detail_page.dart              # Dashboard chi tiết
│   ├── itinerary/
│   │   ├── itinerary_page.dart                # Lịch trình theo ngày
│   │   └── activity_form_page.dart            # Thêm/sửa hoạt động
│   ├── checklist/
│   │   ├── checklist_page.dart                # Checklist + progress
│   │   └── checklist_item_form_page.dart      # Thêm/sửa vật dụng
│   ├── destination/
│   │   ├── destination_list_page.dart         # Danh sách điểm đến
│   │   ├── destination_form_page.dart         # Thêm/sửa điểm đến
│   │   └── destination_map_page.dart          # Bản đồ (MVP)
│   ├── suggestion/
│   │   └── suggestion_bottom_sheet.dart       # Bottom sheet gợi ý
│   ├── share/
│   │   └── share_page.dart                    # Chia sẻ kế hoạch
│   └── widgets/                               # Reusable widgets
│       ├── plan_card.dart
│       ├── activity_card.dart
│       ├── checklist_tile.dart
│       ├── destination_card.dart
│       ├── empty_state.dart
│       └── progress_bar.dart
│
└── routes/
    └── app_routes.dart                        # Route constants + generator
```

### 2.3. Luồng Dữ Liệu (Data Flow)

```
User Action → View
  → ViewModel.method()
    → Repository.method(Entity)
      → API.method(DTO)          ← Giả lập bằng SQLite
        → Database (SQL)
      ← DTO result
    ← Mapper.map(DTO → Entity)
  ← notifyListeners()
→ UI rebuilds
```

**Ví dụ cụ thể — Luồng Login:**
```
LoginPage (nhấn "Đăng nhập")
  → LoginViewModel.login()
    → AuthRepository.login(userName, password)
      → AuthApi.login(LoginRequestDto)
        → SQLite: SELECT users WHERE user_name=? AND password_hash=?
        → SQLite: INSERT session (token, user_id)
      ← LoginResponseDto(token, UserDto)
    ← AuthMapper.map(dto) → AuthSession(token, User)
  ← _session = result, notifyListeners()
→ Navigator.pushReplacementNamed('/home')
```

### 2.4. Dependency Injection

```dart
// di.dart — Chuỗi khởi tạo
AppDatabase.instance → AuthApi → AuthMapper → AuthRepository → LoginViewModel
```

Mỗi module nghiệp vụ sẽ có hàm `buildXxxVM()` tương tự:
```dart
// Ví dụ tương lai:
PlanViewModel buildPlanListVM() {
  final api = PlanApi(AppDatabase.instance);
  final mapper = PlanMapper();
  final repo = PlanRepository(api: api, mapper: mapper);
  return PlanListViewModel(repo);
}
```

---

## III. DATABASE SCHEMA

### 3.1. Sơ Đồ Quan Hệ

```
┌──────────┐
│  users   │   Đăng nhập (auth)
├──────────┤
│ id (PK)  │
│ user_name│
│ pwd_hash │
└──────────┘

┌──────────┐
│ session  │   Phiên đăng nhập (id luôn = 1)
├──────────┤
│ id (PK)  │
│ user_id  │
│ token    │
│ created  │
└──────────┘

┌──────────────┐     1:N     ┌──────────────┐     1:N     ┌──────────────┐
│    plans     │────────────▶│  plan_days   │────────────▶│  activities  │
├──────────────┤             ├──────────────┤             ├──────────────┤
│ id (PK)      │             │ id (PK)      │             │ id (PK)      │
│ name         │             │ plan_id (FK) │             │ plan_day_id  │
│ description  │             │ date         │             │ title        │
│ start_date   │             │ day_number   │             │ activity_type│
│ end_date     │             └──────────────┘             │ start_time   │
│ participants │                                          │ end_time     │
│ cover_image  │                                          │ dest_id (FK) │
│ note         │                                          │ location_text│
│ status       │     1:N     ┌──────────────┐             │ note         │
│ created_at   │────────────▶│checklist_item│             │ est_cost     │
│ updated_at   │             ├──────────────┤             │ priority     │
└──────────────┘             │ id (PK)      │             │ order_index  │
       │                     │ plan_id (FK) │             │ status       │
       │                     │ name         │             └──────┬───────┘
       │ 1:N                 │ quantity     │                    │
       │                     │ category     │              N:1 (optional)
       ▼                     │ note         │                    │
┌──────────────┐             │ priority     │                    ▼
│ destinations │             │ is_packed    │             ┌──────────────┐
├──────────────┤             │ source       │             │ destinations │
│ id (PK)      │             │ linked_act_id│             │  (same table)│
│ plan_id (FK) │             │ suggest_level│             └──────────────┘
│ name         │             └──────────────┘
│ address      │
│ lat, lng     │
│ type         │
│ note         │
│ map_link     │
│ image_path   │
└──────────────┘
```

### 3.2. Cascade Rules
- **Xóa Plan** → tự động xóa `plan_days`, `activities`, `checklist_items`, `destinations`
- **Xóa PlanDay** → tự động xóa `activities`
- **Xóa Destination** → `activities.destination_id` được SET NULL
- **Xóa Activity** → `checklist_items.linked_activity_id` được SET NULL

---

## IV. PHÂN TÍCH CHI TIẾT TỪNG MODULE

### MODULE 0: ĐĂNG NHẬP (AUTH) ✅ ĐÃ HOÀN THÀNH

**Mục đích:** Xác thực người dùng trước khi vào app.

**Luồng:**
1. User nhập username + password tại `LoginPage`
2. `LoginViewModel.login()` → `AuthRepository` → `AuthApi`
3. `AuthApi` query SQLite: so sánh `password_hash` (SHA-256)
4. Tạo session token, lưu vào bảng `session`
5. Trả về `AuthSession(token, User)` → navigate đến Home

**Files liên quan:**
| File | Vai trò |
|------|---------|
| `data/dtos/login/*.dart` (3 files) | LoginRequestDto, LoginResponseDto, UserDto |
| `domain/entities/user.dart` | Entity User thuần |
| `domain/entities/auth_session.dart` | Entity AuthSession (token + User) |
| `data/interfaces/api/iauth_api.dart` | Interface API |
| `data/interfaces/repositories/iauth_repository.dart` | Interface Repository |
| `data/implementations/api/auth_api.dart` | Giả lập API bằng SQLite |
| `data/implementations/mapper/auth_mapper.dart` | LoginResponseDto → AuthSession |
| `data/implementations/repositories/auth_repository.dart` | Orchestrator |
| `data/implementations/local/password_hasher.dart` | SHA-256 hash |
| `viewmodels/login/login_viewmodel.dart` | Form state + auth logic |
| `views/login/login_page.dart` | UI trang đăng nhập |

**Tài khoản mặc định:** `admin` / `123456`

---

### MODULE 1: QUẢN LÝ KẾ HOẠCH (PLAN MANAGEMENT)

**Use Cases:** UC-01 → UC-06

**Dữ liệu:**
- Bắt buộc: `name`, `startDate`, `endDate`
- Tùy chọn: `description`, `participants`, `coverImage`, `note`
- Trạng thái: `DRAFT` → `ACTIVE` → `COMPLETED` → `ARCHIVED`

**Business Rules quan trọng:**
- BR-P03: Tạo Plan → **tự sinh PlanDay** cho mỗi ngày trong khoảng
- BR-P04: Sửa ngày → đồng bộ lại PlanDay, cảnh báo Activity ngoài khoảng
- BR-P05: Xóa Plan → **cascade delete** toàn bộ dữ liệu con

**Hiển thị danh sách:**
- Tên, khoảng ngày, số ngày
- Tiến độ checklist (X/Y - Z%)
- Số hoạt động, badge trạng thái

---

### MODULE 2: LỊCH TRÌNH THEO NGÀY (DAILY ITINERARY)

**Use Cases:** UC-07 → UC-13

**8 loại ActivityType:**

| Type | Icon gợi ý | Mô tả |
|------|-----------|--------|
| TEMPLE_VISIT | 🛕 | Đi chùa / lễ đền |
| FAMILY_VISIT | 👨‍👩‍👧 | Thăm họ hàng / chúc Tết |
| DINING | 🍜 | Ăn uống / cafe |
| PICNIC | ⛺ | Picnic / cắm trại |
| SHOPPING | 🛍️ | Mua sắm |
| MOTORBIKE_TRIP | 🏍️ | Đi xe máy đường xa |
| CHECKIN_PHOTO | 📸 | Check-in / chụp ảnh |
| OTHER | ❓ | Khác |

**Business Rules quan trọng:**
- BR-I06: Cho phép trùng giờ (rule mềm)
- BR-I08/I09: Xóa Activity → hỏi user giữ/xóa checklist items gợi ý
- BR-I10: Đổi activityType → không tự sửa checklist, user bấm "Xem gợi ý lại"

---

### MODULE 3: CHECKLIST ĐỒ MANG THEO

**Use Cases:** UC-14 → UC-21

**Metadata đặc biệt:**
- `source`: `MANUAL` (user tự thêm) / `SUGGESTED` (từ gợi ý)
- `linkedActivityId`: liên kết với activity gợi ý
- `suggestedLevel`: `REQUIRED` / `RECOMMENDED` / `OPTIONAL`

**Business Rules quan trọng:**
- BR-C04: Tiến độ = isPacked=true / tổng items
- BR-C06: Kiểm tra trùng tên bằng `trim() + toLowerCase()`
- BR-C09: Item từ gợi ý đã tồn tại → đánh dấu "Đã có trong checklist"

---

### MODULE 4: BẢN ĐỒ ĐIỂM ĐẾN

**Use Cases:** UC-22 → UC-27

**MVP tiếp cận:**
- Lưu text + mapLink
- Nút "Mở Google Maps" qua `url_launcher`
- Không bắt buộc lat/lng

**Business Rules:**
- BR-D03: 1 Destination → nhiều Activity tham chiếu
- BR-D04: Xóa Destination đang dùng → xác nhận + gỡ liên kết
- BR-D05: Mất mạng → vẫn xem được danh sách text

---

### MODULE 5: GỢI Ý VẬT DỤNG ⭐ TÍNH NĂNG ĐỘC ĐÁO

**Use Cases:** UC-28 → UC-32

**Luồng:**
```
Activity (save) → SuggestionService.getSuggestions(activityType)
  → SuggestionBottomSheet (grouped: BẮT BUỘC → NÊN CÓ → TÙY CHỌN)
  → User chọn items
  → DuplicateDetector.check(selected, existingChecklist)
  → Thêm vào ChecklistItem (source=SUGGESTED, linkedActivityId)
```

**Nguồn gợi ý:**
1. **Rule-based** theo activityType (ưu tiên)
2. **Fallback** theo từ khóa title: "chùa", "lễ", "xe máy", "picnic"

**Business Rules:**
- BR-S05: activityType=OTHER → "Chưa có gợi ý phù hợp"
- BR-S06: Tất cả đã có → "Đã có sẵn tất cả"
- BR-S07: Nhóm theo: BẮT BUỘC → NÊN CÓ → TÙY CHỌN

---

### MODULE 6: CHIA SẺ KẾ HOẠCH

**Use Cases:** UC-33 → UC-37

**MVP:** Text có cấu trúc qua share intent / clipboard
```
📋 KẾ HOẠCH DU XUÂN: Về quê đón Tết
📅 28/01 - 02/02/2026 (6 ngày)

🗓️ NGÀY 1 - 28/01 (Thứ Tư)
  09:00 - 🛕 Lễ chùa Bái Đính
  14:00 - 👨‍👩‍👧 Thăm bà ngoại

☑️ CHECKLIST
  📄 Giấy tờ: ☑ CCCD, ☐ Bằng lái
  👕 Quần áo: ☑ Áo dài, ☐ Giày
```

---

### MODULE 7: NHẮC NHỞ

**Use Cases:** UC-38 → UC-41
- Nhắc chuẩn bị đồ: 1 ngày trước ngày khởi hành
- Nhắc hoạt động: trước startTime (nếu có)
- Sử dụng `flutter_local_notifications`

---

### MODULE 8: TÌM KIẾM / LỌC / THỐNG KÊ

**Use Cases:** UC-42 → UC-46
- Tìm kiếm không phân biệt hoa/thường
- Kết hợp nhiều filter
- Empty state với gợi ý hành động

---

## V. THỨ TỰ TRIỂN KHAI

| Pha | Module | Trạng thái | Mô tả |
|-----|--------|------------|-------|
| 0 | Auth (Login) | ✅ Done | Đăng nhập + session |
| 0 | Cấu trúc + DB Schema | ✅ Done | 94 files + 7 bảng SQLite |
| 1 | Enums + Entities | ⬜ | Code nội dung thực cho enums và entities |
| 2 | Plan Management | ⬜ | Module trung tâm |
| 3 | Daily Itinerary | ⬜ | Phụ thuộc Plan |
| 4 | Checklist | ⬜ | Phụ thuộc Plan |
| 5 | Destination Map | ⬜ | Phụ thuộc Plan + Activity |
| 6 | Smart Suggestion | ⬜ | Liên kết Itinerary ↔ Checklist |
| 7 | Share Plan | ⬜ | Cần M1-M4 hoàn thành |
| 8 | Reminder + Utility | ⬜ | Tính năng bổ trợ |

---

## VI. QUY TẮC QUAN TRỌNG CHO DEVELOPER

| Quy tắc | Mô tả |
|---------|-------|
| **Entity = thuần** | Không import flutter, sqflite, http |
| **DTO chỉ trong data/** | View và ViewModel không bao giờ thấy DTO |
| **IMapper<I, O> generic** | 1 interface dùng cho tất cả mapper |
| **API = giả lập** | Dùng SQLite, dễ swap sang REST API sau |
| **Repository = orchestrator** | Kết nối API + Mapper + business rules |
| **ViewModel = UI state** | Chỉ gọi Repository, không truy cập DB |
| **View = hiển thị** | Không chứa logic, chỉ gọi ViewModel |
| **DI tập trung** | Tất cả wiring trong di.dart |
