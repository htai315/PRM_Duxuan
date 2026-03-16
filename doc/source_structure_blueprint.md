# DU_XUAN Source Structure Blueprint

Tai lieu nay co 2 muc tieu:
1. Mo ta chi tiet cau truc source code hien tai cua du an `du_xuan` (theo dung code dang chay).
2. Dua ra blueprint de ban copy qua du an khac ma van giu duoc logic va tinh mo rong.

---

## 1) Kien truc tong quan

Du an dang di theo kieu:
- `MVVM` cho UI + state.
- `Clean-ish layering` cho data:
  - `domain/entities` (model thuần)
  - `data/dtos`, `data/interfaces`, `data/implementations`
  - `viewmodels`
  - `views`
- `SQLite offline-first` (qua `sqflite`)
- `Manual DI` qua `lib/di.dart`

Luong du lieu chinh:

```text
View (Widget)
  -> ViewModel (ChangeNotifier)
    -> Repository Interface
      -> Repository Impl
        -> API Interface
          -> API Impl (SQLite/HTTP)
            -> DB or external service
      -> Mapper DTO -> Entity
  -> notifyListeners() -> View rebuild
```

---

## 2) Cay thu muc that su trong `lib/`

```text
lib/
  main.dart
  di.dart
  routes/app_routes.dart

  core/
    constants/
    enums/
    utils/

  domain/
    entities/

  data/
    dtos/
    interfaces/
      api/
      mapper/
      repositories/
    implementations/
      api/
      local/
        db/
      mapper/
      repositories/

  viewmodels/
    login/
    register/
    home/
    plan/
    itinerary/
    checklist/
    map/
    notification/
    settings/

  views/
    auth/widgets/
    splash/
    login/
    register/
    home/
    plan/
    plan_detail/
      tabs/
    itinerary/
    checklist/
    notification/
    settings/
```

---

## 3) Vai tro tung tang

## 3.1 `core/`

### `core/constants`
- [app_colors.dart](../lib/core/constants/app_colors.dart): palette toan app.
- [app_text_styles.dart](../lib/core/constants/app_text_styles.dart): style text chung.
- [api_constants.dart](../lib/core/constants/api_constants.dart): endpoint/model/key OpenAI (hien dang hardcode).

### `core/enums`
- Chua state va metadata hien thi:
  - `plan_status`, `activity_type`, `activity_status`
  - `checklist_category`, `checklist_source`
  - `notification_type`

### `core/utils`
- [notification_service.dart](../lib/core/utils/notification_service.dart): local notification + deeplink vao plan.
- [plan_share_builder.dart](../lib/core/utils/plan_share_builder.dart): build text chia se chi tiet plan.
- [maps_launcher.dart](../lib/core/utils/maps_launcher.dart): mo Google/Apple Maps.
- [pagination_utils.dart](../lib/core/utils/pagination_utils.dart): struct phan trang.

---

## 3.2 `domain/entities`

Entity thuần, khong phu thuoc UI hay DB:
- `User`, `AuthSession`
- `Plan`, `PlanDay`
- `Activity`
- `ChecklistItem`
- `MapMarkerData`
- `AppNotification`

Ghi chu:
- `Plan` co computed getters (`totalDays`, `displayStatus`) de UI dung truc tiep.

---

## 3.3 `data/`

### `dtos/`
- Tach theo nghiep vu: `login/`, `plan/`, `activity/`, `checklist/`, `notification/`.
- Rule: DTO doc DB/API co `fromMap`; DTO ghi DB co `toMap`.

### `interfaces/`
- `api/`: hop dong truy cap data (`IAuthApi`, `IPlanApi`, ...).
- `repositories/`: hop dong cho ViewModel.
- `mapper/imapper.dart`: generic mapper `IMapper<I, O>`.

### `implementations/`

#### `api/`
- Hien tai đa so la local API layer tren SQLite:
  - `AuthApi`, `PlanApi`, `ActivityApi`, `ChecklistApi`, `NotificationApi`
- Ngoai ra co service HTTP:
  - `GeocodingService` (Nominatim)
  - `OpenAiService` (chat completions)

#### `local/db`
- [app_database.dart](../lib/data/implementations/local/db/app_database.dart):
  - singleton DB
  - `version: 1`
  - create tables + seed users
  - `PRAGMA foreign_keys = ON`

#### `mapper/`
- Map DTO -> Entity:
  - `AuthSessionMapper`, `PlanMapper`, `PlanDayMapper`, `ActivityMapper`, `ChecklistMapper`, `NotificationMapper`.

#### `repositories/`
- Orchestrator API + Mapper + business rule data-level.
- Vi du:
  - `PlanRepository.create()` tu sinh `plan_days`.
  - `PlanRepository.update()` sync day thong minh.
  - `ActivityRepository.create()` tu tinh `orderIndex`.
  - `NotificationRepository` quan ly read/unread, event-key.

---

## 3.4 `viewmodels/`

Tat ca deu `extends ChangeNotifier`.

Danh sach:
- `LoginViewModel`, `RegisterViewModel`, `ChangePasswordViewModel`
- `HomeViewModel`
- `PlanListViewModel`, `PlanFormViewModel`
- `ItineraryViewModel`, `ActivityFormViewModel`
- `ChecklistViewModel`, `SuggestionViewModel`
- `MapViewModel`
- `NotificationViewModel`

Pattern chung:
- State fields: `_isLoading`, `_errorMessage`, data list/object.
- Method: `load...`, `create/update/delete`, validation va notify.
- ViewModel khong chua SQL truc tiep.

---

## 3.5 `views/`

UI tach theo page + reusable widget:
- Auth:
  - `views/auth/widgets/auth_ui.dart` chua scaffold/panel/input/button dung lai cho login/register/change-password.
- Main flow:
  - `SplashPage` -> `Login/Register` -> `HomePage`.
- Plan:
  - `PlanListPage`, `PlanFormPage`, `PlanDetailPage`.
- Plan detail tabs:
  - `DayListTab`, `ChecklistTab`, `LocationsTab`.
- Itinerary:
  - `DayDetailPage`, `ActivityFormPage`, `ActivityDetailPage`.
- Checklist:
  - `ChecklistPage`, `SuggestionBottomSheet`.
- Notification:
  - `NotificationPage`.
- Settings:
  - `ChangePasswordPage`.

---

## 4) Thanh phan khoi dong va dieu huong

### Entry point
- [main.dart](../lib/main.dart):
  - init locale (`intl`)
  - init + request permission notification
  - run `MaterialApp`
  - gan `navigatorKey` tu NotificationService de deep link tu push.

### DI
- [di.dart](../lib/di.dart):
  - manual factory functions `buildXxxVM()`
  - ket noi API -> Mapper -> Repository -> ViewModel
  - `NotificationService` duoc giu singleton.

### Router
- [app_routes.dart](../lib/routes/app_routes.dart):
  - route constants + `generateRoute`
  - moi route tu inject dung ViewModel tu `di.dart`.

---

## 5) Luong nghiep vu tieu bieu

## 5.1 Login
1. `LoginPage` goi `LoginViewModel.login`.
2. `LoginViewModel` goi `AuthRepository.login`.
3. `AuthRepository` goi `AuthApi.login`.
4. `AuthApi` verify hash password tu SQLite va tao row `session`.
5. map `LoginResponseDto -> AuthSession`.
6. UI dieu huong vao `/home`.

## 5.2 Tao Plan
1. `PlanFormPage` goi `PlanFormViewModel.savePlan`.
2. validate data.
3. `PlanRepository.create` insert `plans`, auto-gen `plan_days`.
4. sau khi tao xong, `NotificationService.schedulePlanReminder`.

## 5.3 Danh dau plan completed
1. `ItineraryViewModel.markPlanCompleted`.
2. check `canMarkPlanCompleted` (dang dien ra + 100% activity done).
3. update status plan.
4. cancel reminder plan.

## 5.4 Notification
1. `NotificationService` schedule local notification (D-1 14:40, D0 07:00).
2. luu record vao table `notifications` (co `event_key`).
3. user tap notification -> mark read + navigate `/itinerary`.
4. `NotificationPage` doc lich su + unread count.

---

## 6) DB schema tom tat (thuc te)

Bang chinh:
- `users`
- `session`
- `plans`
- `plan_days`
- `activities`
- `destinations`
- `checklist_items`
- `notifications`

Luu y quan trong:
- FK cascade da bat.
- `notifications.event_key` la `UNIQUE` de tranh trung lap schedule.

---

## 7) Blueprint de ap dung sang du an khac

Ban co the copy y nguyen structure nay va doi ten domain.

## 7.1 Folder template khuyen nghi

```text
lib/
  main.dart
  di.dart
  routes/
  core/
    constants/
    enums/
    utils/
  domain/
    entities/
  data/
    dtos/
    interfaces/
      api/
      mapper/
      repositories/
    implementations/
      api/
      local/db/
      mapper/
      repositories/
  viewmodels/
    <feature>/
  views/
    <feature>/
```

## 7.2 Quy tac chia file (rat quan trong)

- 1 Entity = 1 file.
- 1 DTO = 1 file.
- 1 API interface + 1 API impl.
- 1 Repository interface + 1 Repository impl.
- 1 Mapper per entity.
- 1 ViewModel per screen/module.
- UI reusable tach vao `views/<module>/widgets` hoac `views/auth/widgets`.

## 7.3 Quy tac dat ten

- Interface: `IAuthApi`, `IPlanRepository`.
- Impl: `AuthApi`, `PlanRepository`.
- ViewModel: `<Feature>ViewModel`.
- Page: `<Feature>Page`.
- DTO:
  - `CreateXRequestDto`
  - `UpdateXRequestDto`
  - `XDto`

## 7.4 Checklist tao feature moi

Khi them feature moi, lam theo thu tu:
1. Tao Entity.
2. Tao DTO doc/ghi.
3. Tao API interface + impl.
4. Tao Mapper.
5. Tao Repository interface + impl.
6. Tao ViewModel.
7. Tao Page + widgets.
8. Dang ky DI trong `di.dart`.
9. Them route trong `app_routes.dart`.
10. Viet test (nếu có) va `dart analyze lib`.

---

## 8) Diem nen giu va diem nen cai tien khi copy sang du an khac

## Nen giu
- Manual DI don gian, de debug.
- Mapper tach rieng.
- DTO/entity tach ro.
- ViewModel validation tap trung.
- `AuthScaffold` style reusable cho man auth.
- NotificationService doc lap voi UI.

## Nen cai tien
- Khong hardcode API key trong source (hien dang o `ApiConstants`).
- DB migration: tang version + `onUpgrade` thay vi reset app.
- Bo sung unit test cho repository/viewmodel.
- Tach service external (OpenAI/Geocoding) qua interface de mock de hon.
- Can nhac dung `freezed/json_serializable` neu entity/dto tang nhanh.

---

## 9) Ban rut gon de paste vao project moi

Neu ban can scaffold nhanh:
- Copy nguyen 5 tang: `core`, `domain`, `data`, `viewmodels`, `views`.
- Doi schema DB va enum theo domain moi.
- Giu nguyen pattern API/Repository/Mapper.
- Giu `di.dart` va route generator.
- Doi UI theme trong `core/constants`.

Chi can giu dung cac luat tren, ban se co 1 codebase:
- de mo rong feature,
- de maintain,
- de onboard nguoi moi.

