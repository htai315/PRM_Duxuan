# PROJECT REVIEW

## 0. Scope Review

Tài liệu này được viết sau khi rà soát codebase hiện tại của dự án `du_xuan`, bao gồm:

- Cấu trúc thư mục trong `lib/`
- Cấu hình và dependency chính trong `pubspec.yaml`, `analysis_options.yaml`
- Cơ sở dữ liệu local trong `app_database.dart`
- Các tầng `views`, `viewmodels`, `repositories`, `api`, `dto`, `mapper`, `domain`
- Luồng notification, share, public share local stub
- Các file tool/doc quan trọng như `tool/public_share_stub_server.dart`, `doc/project_specification.md`, `doc/source_structure_blueprint.md`

Lưu ý:

- Đây là review kiến trúc và kỹ thuật dựa trên code thực tế hiện tại.
- Dự án là local-first Flutter app, nên không có backend production thật.
- Một vài nhận định về sản phẩm được suy ra từ cách code đang vận hành.

---

## 1. Tổng quan dự án

### 1.1. Mục tiêu chính của hệ thống

`Du Xuân` là một ứng dụng Flutter local-first để quản lý kế hoạch đi chơi / hành hương / du xuân.

Mục tiêu sản phẩm hiện tại là:

- Giúp người dùng tạo và quản lý kế hoạch chuyến đi
- Chia kế hoạch theo ngày và theo activity
- Quản lý checklist đồ cần mang
- Theo dõi chi phí dự kiến và chi phí thực tế
- Nhắc lịch bằng notification local
- Cho phép chia sẻ kế hoạch dưới dạng:
  - share text
  - public link local demo
  - gửi template kế hoạch cho tài khoản khác

### 1.2. Business problem đang giải quyết

Dự án giải quyết bài toán cá nhân hóa kế hoạch chuyến đi trong bối cảnh:

- người dùng cần một công cụ gọn để lên lịch theo ngày
- cần kiểm soát đồ cần chuẩn bị
- cần theo dõi chi tiêu
- cần nhắc lịch trước chuyến đi
- có thể tái sử dụng một kế hoạch như template cho người khác

Đây không phải app social, không phải collaborative planner thật, và hiện không có cloud sync.

### 1.3. Kiến trúc tổng thể

Kiến trúc hiện tại phù hợp nhất để mô tả là:

- **Modular monolith**
- **Layered architecture**
- **MVVM-style presentation**
- **Local-first application**

Không phải Clean Architecture đầy đủ, nhưng có xu hướng “clean-ish”:

- `views`: UI
- `viewmodels`: state + orchestration
- `repositories`: abstraction/use-case-oriented data access
- `api`: implementation thao tác SQLite / HTTP / service cụ thể
- `domain/entities`: model nghiệp vụ

Đây là kiến trúc hợp lý cho một Flutter app local-first tầm MVP tới demo/đồ án.

### 1.4. Tech stack

#### Frontend / app

- Flutter
- Dart
- `provider` + `ChangeNotifier` cho state management
- `google_fonts`, `intl`, `share_plus`, `url_launcher`

#### Persistence

- SQLite local qua `sqflite`
- `shared_preferences`

#### Notification / device

- `flutter_local_notifications`
- `timezone`
- permission/request exact alarm ở Android

#### Map / geocoding

- `flutter_map`
- `latlong2`
- geocoding qua Nominatim/OpenStreetMap

#### AI / external service

- Gọi OpenAI trực tiếp từ client để gợi ý checklist

#### Public share demo

- Stub server local chạy bằng Dart ở `tool/public_share_stub_server.dart`

#### Infra / runtime model

- Không có backend production
- Không có CI/CD thể hiện trong repo
- Không có test automation đáng kể ngoài `test/widget_test.dart`

---

## 2. Phân tích cấu trúc thư mục

### 2.1. Cấu trúc chính

```text
lib/
  core/
  data/
  domain/
  routes/
  viewmodels/
  views/
tool/
doc/
test/
```

### 2.2. Ý nghĩa từng folder chính

| Folder | Vai trò |
|---|---|
| `lib/core` | constants, enums, utils, formatter, notification service, helper dùng chung |
| `lib/data` | DTO, interface, implementation của data access, mapper, SQLite API, remote API |
| `lib/domain` | entity nghiệp vụ |
| `lib/routes` | route name, route args, route generation |
| `lib/viewmodels` | state management + orchestration theo từng feature |
| `lib/views` | màn hình, widget UI theo feature |
| `tool` | công cụ dev/demo như public share stub server |
| `doc` | tài liệu dự án và blueprint |
| `test` | test automation, hiện rất mỏng |

### 2.3. Đánh giá cách tổ chức code

#### Điểm tốt

- Cấu trúc thư mục rõ ràng và dễ lần theo feature.
- Tách `data`, `domain`, `viewmodels`, `views` khá ổn.
- Các feature chính như `plan`, `expense`, `checklist`, `notification`, `share` có vùng code tương đối độc lập.
- Dễ onboard hơn so với việc dồn hết vào `screens/` hoặc `services/`.

#### Pattern đang được áp dụng

- MVVM tương đối rõ ở tầng presentation
- Repository pattern
- DTO + Mapper pattern
- Manual DI qua `di.dart`

#### Code smell / drift đáng chú ý

- `di.dart` đang phình to và dần trở thành service locator tập trung quá mức.
- Một số màn lớn như `PlanDetailPage`, `NotificationPage`, `HomePage` đang ôm nhiều orchestration.
- Tài liệu trong `README.md` và `doc/source_structure_blueprint.md` không còn phản ánh đúng code hiện tại.
- Schema DB vẫn là `version = 1` nhưng được chỉnh trực tiếp nhiều lần; đây là dấu hiệu nợ kỹ thuật rõ.

### 2.4. Kết luận về cấu trúc thư mục

Tổ chức thư mục hiện tại **đủ rõ ràng và hợp lý cho quy mô hiện có**. Vấn đề không nằm ở cây thư mục, mà nằm ở:

- một vài file quá tải trách nhiệm
- manual DI tập trung
- drift giữa tài liệu và code
- thiếu chiến lược migration/test khi hệ thống lớn dần

---

## 3. Phân tích nghiệp vụ (Business Logic)

### 3.1. Các flow chính của hệ thống

#### Auth / session

- User đăng ký / đăng nhập local
- Tạo session local trong bảng `session`
- Đăng xuất xóa session

#### Plan management

- Tạo kế hoạch
- Tự sinh `plan_days` theo khoảng ngày
- Sửa kế hoạch và đồng bộ lại ngày
- Xóa kế hoạch
- Chuyển trạng thái kế hoạch theo lifecycle

#### Itinerary / activities

- Mỗi plan có nhiều `plan_days`
- Mỗi `plan_day` có nhiều `activities`
- Activity có thời gian, loại, địa điểm, chi phí dự kiến
- Có thể mark done / undone

#### Checklist

- Checklist gắn theo `plan`
- Có category, quantity, note, linked activity
- Có trạng thái đã chuẩn bị / chưa

#### Expense

- Expense gắn với plan, có thể gắn day/activity
- `estimated cost` nằm ở `Activity`
- `actual spending` nằm ở `Expense`

#### Notification

- Notification local cho plan active
- Rule hiện tại:
  - 22:00 ngày hôm trước
  - 1 tiếng trước activity đầu tiên của ngày đầu
- In-app notification center lưu trong DB

#### Public share

- Dùng snapshot builder để build dữ liệu public share
- Remote API hiện trỏ tới local stub server
- Đây là demo flow, chưa phải production backend thật

#### Template share

- A chọn plan
- Tìm user B và gửi lời mời
- B nhận notification
- B accept/reject
- Nếu accept:
  - chọn ngày bắt đầu mới
  - sinh một **plan mới riêng** cho B
  - copy cấu trúc như template, không dùng chung plan gốc

### 3.2. Cách dữ liệu đi qua các tầng

Trong app này không có `Controller` theo nghĩa backend web.

Flow thực tế là:

```text
View -> ViewModel -> Repository -> API -> SQLite / HTTP / OS service
```

Ví dụ:

```text
PlanDetailPage
  -> ItineraryViewModel
  -> IPlanRepository / IActivityRepository
  -> PlanApi / ActivityApi
  -> SQLite
```

### 3.3. Điểm mạnh của thiết kế nghiệp vụ

- Tách `estimated` và `actual` là đúng, giúp expense module không bị nhập nhằng.
- `plan_days` giúp itinerary theo ngày rõ ràng và dễ mở rộng.
- Template share hiện tại đúng với sản phẩm hơn nhiều so với collaborative shared-plan.
- Notification được gắn tương đối chặt với lifecycle plan active.
- Checklist, itinerary, expense đều bám cùng một source-of-truth là `planId`, nên logic tổng thể nhất quán.

### 3.4. Điểm chưa hợp lý / dễ gây hiểu nhầm

- `plan.getById()` không guard theo current user, nên business ownership chưa kín.
- `NotificationType` chỉ có `reminder/system`, nhưng template request lại sống trong `system + payload JSON`; đây là logic ngầm.
- `destinations` tồn tại trong schema, nhưng sản phẩm thực tế lại dùng `activity.locationText` là chính; source-of-truth bị lửng.
- Dashboard/Home đang dựa nhiều vào danh sách plan phân trang để suy ra tổng quan; điều này không đúng về business khi dữ liệu tăng.

---

## 4. Phân tích các module

## 4.1. Module Auth / Session

### Vai trò

- Đăng ký, đăng nhập, đổi mật khẩu, quản lý session local

### Class/file chính

- `lib/data/implementations/api/auth_api.dart`
- `lib/data/implementations/repositories/auth_repository.dart`
- `lib/viewmodels/login/login_viewmodel.dart`
- `lib/viewmodels/register/register_viewmodel.dart`
- `lib/viewmodels/settings/change_password_viewmodel.dart`

### Liên kết

- UI gọi viewmodel
- viewmodel gọi auth repository
- repository gọi `AuthApi`
- `AuthApi` thao tác với bảng `users`, `session`

### Đánh giá coupling / cohesion

- Cohesion tốt: module nhỏ, rõ trách nhiệm
- Coupling thấp với phần còn lại

### Nhận xét

- Đây là một trong những module sạch hơn của dự án.
- Điểm trừ lớn nhất là password hashing còn rất basic và session model chỉ hợp cho local demo.

## 4.2. Module Plan

### Vai trò

- Quản lý vòng đời plan
- Tạo/sửa/xóa plan
- Tạo `plan_days`

### Class/file chính

- `lib/domain/entities/plan.dart`
- `lib/data/implementations/api/plan_api.dart`
- `lib/data/implementations/repositories/plan_repository.dart`
- `lib/viewmodels/plan/plan_form_viewmodel.dart`
- `lib/viewmodels/plan/plan_list_viewmodel.dart`

### Liên kết

- Là module lõi
- Bị phụ thuộc bởi itinerary, checklist, expense, notification, share, map

### Đánh giá coupling / cohesion

- Cohesion cao
- Coupling cao nhưng hợp lý vì plan là aggregate root của app

### Nhận xét

- Thiết kế tổng thể tốt.
- Vấn đề lớn nằm ở `getById()` không kiểm tra quyền sở hữu user.

## 4.3. Module Itinerary / Activity

### Vai trò

- Quản lý lịch trình theo ngày và activity

### Class/file chính

- `lib/domain/entities/activity.dart`
- `lib/domain/entities/plan_day.dart`
- `lib/data/implementations/api/activity_api.dart`
- `lib/viewmodels/itinerary/itinerary_viewmodel.dart`
- `lib/viewmodels/itinerary/activity_form_viewmodel.dart`
- `lib/views/plan_detail/plan_detail_page.dart`
- `lib/views/itinerary/day_detail_page.dart`

### Liên kết

- Dùng `planId` và `planDayId`
- Liên quan trực tiếp đến checklist, expense, notification, map

### Đánh giá

- Cohesion tương đối tốt
- Nhưng orchestration đang dồn khá nhiều vào `ItineraryViewModel` và `PlanDetailPage`

### Nhận xét

- Flow nghiệp vụ tốt
- UI detail mạnh nhưng code page hơi nặng

## 4.4. Module Checklist

### Vai trò

- Theo dõi vật dụng cần chuẩn bị cho plan

### Class/file chính

- `lib/domain/entities/checklist_item.dart`
- `lib/data/implementations/api/checklist_api.dart`
- `lib/viewmodels/checklist/checklist_viewmodel.dart`
- `lib/views/checklist/`

### Liên kết

- Gắn với `planId`
- Có thể linked tới activity
- Có AI suggestion qua OpenAI

### Đánh giá

- Cohesion tốt
- Coupling vừa phải

### Nhận xét

- Đây là feature có giá trị sản phẩm cao.
- Việc AI suggestion gọi trực tiếp từ client là điểm rủi ro lớn về bảo mật.

## 4.5. Module Expense

### Vai trò

- Ghi nhận chi tiêu thực tế của kế hoạch

### Class/file chính

- `lib/domain/entities/expense.dart`
- `lib/data/implementations/api/expense_api.dart`
- `lib/viewmodels/expense/expense_viewmodel.dart`
- `lib/views/expense/`

### Liên kết

- Gắn với `planId`
- Có thể gắn `planDayId` và `activityId`

### Đánh giá

- Cohesion tốt
- Module này khá rõ ràng và thực dụng

### Nhận xét

- Một trong những phần nghiệp vụ sạch nhất.
- UI thao tác hiện cũng tương đối thống nhất với các module khác.

## 4.6. Module Notification

### Vai trò

- Lưu notification in-app
- Local reminder
- Điều phối navigation khi tap notification

### Class/file chính

- `lib/core/utils/notification_service.dart`
- `lib/domain/entities/app_notification.dart`
- `lib/data/implementations/api/notification_api.dart`
- `lib/viewmodels/notification/notification_viewmodel.dart`
- `lib/views/notification/notification_page.dart`

### Liên kết

- Gắn với `plan`
- Gắn với template share request
- Gắn với OS local notifications

### Đánh giá

- Cohesion trung bình
- Coupling cao vì vừa đụng DB, OS notification, navigation, business event

### Nhận xét

- Chạy được, nhưng đây là module có xu hướng phình nhanh nhất.
- Nên xem lại typing của notification action.

## 4.7. Module Map

### Vai trò

- Hiển thị địa điểm từ activity trên bản đồ

### Class/file chính

- `lib/viewmodels/map/map_viewmodel.dart`
- `lib/core/utils/geocoding_service.dart`
- `lib/views/home/map_tab.dart`

### Liên kết

- Lấy plan ongoing
- Lấy activities theo plan day
- Geocode `locationText`

### Đánh giá

- Cohesion ổn
- Nhưng performance path còn yếu

### Nhận xét

- Về ý tưởng sản phẩm: hợp lý
- Về kỹ thuật: hiện mới ở mức demo/local dataset

## 4.8. Module Public Share

### Vai trò

- Share plan bằng text
- Tạo public snapshot local demo

### Class/file chính

- `lib/core/utils/plan_share_builder.dart`
- `lib/core/utils/plan_share_snapshot_builder.dart`
- `lib/viewmodels/share/public_share_viewmodel.dart`
- `tool/public_share_stub_server.dart`

### Liên kết

- Phụ thuộc plan, activity, expense, checklist

### Đánh giá

- Public snapshot builder đi đúng hướng hơn share text builder
- Share text builder vẫn còn phụ thuộc `di.dart` fallback, chưa sạch bằng snapshot builder

### Nhận xét

- Phù hợp cho demo
- Chưa nên coi là production-ready feature

## 4.9. Module Template Share

### Vai trò

- Gửi template kế hoạch cho user khác
- Recipient chấp nhận / từ chối
- Tạo bản sao riêng

### Class/file chính

- `lib/data/implementations/api/plan_copy_api.dart`
- `lib/data/implementations/api/plan_clone_service.dart`
- `lib/viewmodels/share/plan_copy_share_viewmodel.dart`
- `lib/viewmodels/share/plan_copy_request_viewmodel.dart`
- `lib/viewmodels/share/plan_copy_source_viewmodel.dart`
- `lib/views/plan_detail/widgets/plan_copy_share_sheet.dart`

### Liên kết

- Liên quan chặt với notification, plan, activity, checklist

### Đánh giá

- Đây là một trong những phần thiết kế có ý thức nhất của hệ thống.
- Tách clone logic sang service riêng là quyết định đúng.

### Nhận xét

- Sau khi bỏ flow “bạn bè”, module này hợp sản phẩm hơn nhiều.
- Semantics hiện tại là template clone, và đây là hướng nên giữ.

---

## 5. Đánh giá kỹ thuật

### 5.1. Code quality

#### Điểm tốt

- Naming nhìn chung nhất quán và dễ hiểu.
- Entity/repository/viewmodel được đặt tên khá rõ trách nhiệm.
- Các luồng CRUD chính đọc khá thẳng.
- Sử dụng `copyWith`, DTO, mapper có chủ đích.

#### Điểm chưa tốt

- Một số file rất dài:
  - `PlanDetailPage`
  - `NotificationPage`
  - `DashboardTab`
  - `di.dart`
- Logic điều phối còn nằm nhiều trong page/widget thay vì VM/helper riêng.
- Drift giữa tài liệu và code làm tăng cognitive load cho người mới đọc.

### 5.2. Convention / clean code

- Convention tổng thể ổn.
- Không có dấu hiệu spaghetti code nặng.
- Tuy nhiên có “stringly typed logic” ở notification payload và một số enum/state mapping.

### 5.3. Design pattern đã dùng

- MVVM
- Repository
- DTO + Mapper
- Service object ở một số nơi như `PlanCloneService`, `NotificationService`
- Manual dependency factory

### 5.4. Scalability

#### Theo chiều tính năng

- Có thể mở rộng thêm vừa phải nếu còn giữ local-first.
- Nhưng sẽ bắt đầu đau ở:
  - DI thủ công
  - migration DB
  - các page/viewmodel lớn

#### Theo chiều dữ liệu

- Không tốt lắm nếu user có nhiều dữ liệu hơn hiện tại
- Điểm nghẽn rõ:
  - dashboard dùng paged list như full list
  - map geocode tuần tự
  - sync reminder theo tập plan lấy từ UI state

#### Theo chiều nhiều thiết bị / cloud

- Kiến trúc hiện tại chưa sẵn sàng
- Muốn đi xa phải thay đổi khá lớn ở data ownership và sync model

### 5.5. Maintainability

Đánh giá chung: **maintain được ở mức MVP**, nhưng chưa bền nếu mở rộng mạnh.

Điểm cản chính:

- `di.dart` tăng dần thành điểm nghẽn
- thiếu test
- thiếu migration strategy
- thiếu policy rõ cho module boundary

### 5.6. Performance

Các điểm rủi ro:

- `MapViewModel` geocode sequential + artificial delay
- Home/dashboard dựa trên list đã paginate
- Màn Home và PlanDetail refresh khá rộng sau navigation
- Notification sync có nguy cơ không đúng khi plan list chưa đầy đủ

### 5.7. Security

Đây là phần yếu nhất của dự án hiện tại.

#### Vấn đề lớn

- `ApiConstants.openAiApiKey` đang hardcode trực tiếp trong client
- Gọi OpenAI từ mobile app bằng secret key thật
- Session/token local không được thiết kế cho môi trường hostile

#### Mức độ ảnh hưởng

- Với demo nội bộ: chấp nhận được tạm thời
- Với app phát hành thật: không chấp nhận được

### 5.8. Bug risk

Những điểm có nguy cơ bug thực tế cao:

- Lấy plan theo `id` mà không chặn theo `userId`
- Stats/home dùng dữ liệu phân trang để suy ra tổng quan
- Notification action phụ thuộc payload JSON thay vì type rõ
- Schema DB sửa trực tiếp nhưng không có migration

---

## 6. Đề xuất cải tiến

### 6.1. Refactor cấu trúc project

#### Mức ưu tiên cao

1. Tách `di.dart`
- Tạo các builder theo nhóm:
  - `buildAuthDependencies()`
  - `buildPlanDependencies()`
  - `buildShareDependencies()`
  - `buildNotificationDependencies()`
- Giảm một file factory trung tâm quá tải

2. Tách các page quá lớn
- `PlanDetailPage`
  - tách menu actions
  - tách tab setup
  - tách header/source badge
- `NotificationPage`
  - tách notification item renderer
  - tách actionable request handling helper

3. Làm sạch docs
- Update `README.md`
- Update hoặc thay mới `doc/source_structure_blueprint.md`
- Ghi rõ feature nào là local demo, feature nào là MVP thật

### 6.2. Cải thiện kiến trúc

1. Thêm ownership guard cho plan access
- Tạo `getByIdForUser(planId, userId)`
- Chuyển tất cả route/viewmodel liên quan sang dùng API này

2. Tách dashboard stats khỏi paged plan list
- Tạo repository riêng cho Home stats
- Không dùng `planListVM.plans.length` như total business metrics

3. Typed notification actions
- Thêm enum/type riêng cho template share notification
- Tránh parse payload JSON như contract ngầm

4. Chốt source-of-truth cho location
- Nếu dùng `activity.locationText` là chính, nên cân nhắc bỏ `destinations`
- Nếu giữ `destinations`, cần đưa nó trở lại vai trò thực tế trong product flow

### 6.3. Tối ưu code

1. Map/geocode
- Cache geocode result
- Batch hoặc precompute location
- Tránh load tuần tự từng location với delay cố định

2. Notification scheduling
- Tách `permission`, `scheduler`, `navigation callback`
- Không xin quyền ngay khi app vừa mở

3. Share text builder
- Đồng bộ cách dependency injection với snapshot builder
- Bỏ fallback resolve từ `di.dart` bên trong util

### 6.4. Best practices nên áp dụng

- Thêm test tối thiểu cho:
  - plan lifecycle
  - template share request
  - clone semantics
  - notification scheduling rules
- Thêm DB migration strategy trước khi mở thêm bảng/cột nữa
- Dùng environment config cho secret và URL
- Tách output logic khỏi UI state logic ở các page lớn

### 6.5. Nếu build lại từ đầu

Nếu làm lại nhưng vẫn giữ local-first, tôi sẽ chọn:

- Flutter
- Feature-first modular structure
- MVVM hoặc state notifier rõ hơn
- Repository interfaces vẫn giữ
- DB migration strategy từ ngày đầu
- Notification action typed model
- Home stats repository riêng
- Không hardcode bất kỳ external secret nào trong app

Nếu xác định đi xa hơn thành app nhiều thiết bị:

- backend nhỏ cho auth/share/AI proxy/public share
- đồng bộ plan qua backend
- tách rõ local cache và remote source-of-truth

---

## 7. Tổng kết

### 7.1. 10 điểm quan trọng nhất cần chú ý

1. Kiến trúc tổng thể của app là hợp lý cho local-first MVP.
2. Module plan/checklist/expense được thiết kế tương đối tốt và đúng trọng tâm sản phẩm.
3. Template share là hướng đúng; không nên quay lại collaborative shared-plan lúc này.
4. `di.dart` đang phình to và cần được chia nhỏ.
5. `PlanDetailPage` và `NotificationPage` là hai điểm quá tải lớn nhất ở UI layer.
6. Lấy plan theo `id` mà không guard theo current user là rủi ro nghiệp vụ thật.
7. Dashboard/home hiện chưa có nguồn stats chuẩn khi dữ liệu nhiều hơn 1 trang.
8. Hardcoded OpenAI key là rủi ro bảo mật nghiêm trọng nhất.
9. DB migration chưa được xử lý bài bản; hiện vẫn sống bằng chiến lược “schema v1 sạch”.
10. Tài liệu trong repo đang lạc nhịp với code, cần cập nhật nếu dùng để bàn giao/nghiệm thu.

### 7.2. Đánh giá tổng thể

#### Theo góc nhìn sản phẩm MVP / demo

- **8.0/10**

Lý do:

- feature set rõ
- flow chính khá mạch lạc
- app đã có chiều sâu hơn MVP CRUD cơ bản
- local-first model phù hợp demo

#### Theo góc nhìn kỹ thuật sản phẩm dài hạn

- **6.5/10**

Lý do:

- kiến trúc nền ổn
- nhưng còn nợ rõ ở security, ownership guard, migration, test, và modularization của UI/service layer

---

## 8. Kết luận thực dụng

Dự án này **đủ tốt để demo, nghiệm thu, hoặc làm đồ án/MVP local-first**.

Điểm mạnh nhất của hệ thống là:

- focus sản phẩm đúng
- model nghiệp vụ khá hợp lý
- template share là một feature có giá trị và đã được thiết kế theo hướng đúng

Điểm yếu lớn nhất là:

- secret hardcode
- ownership guard chưa kín
- stats/home và notification đang hơi “lấy tạm dữ liệu UI state để làm business decision”
- thiếu chiến lược test + migration

Nếu tiếp tục phát triển, thứ tự ưu tiên hợp lý nhất là:

1. chặn truy cập plan theo current user
2. tách home stats khỏi paged list
3. loại bỏ OpenAI key khỏi client
4. chia nhỏ `di.dart`, `PlanDetailPage`, `NotificationPage`
5. thêm test và migration strategy

---

## 9. Recommendation cuối cùng

Nếu mục tiêu trước mắt là **chốt project**, tôi khuyên:

- dừng mở thêm feature lớn
- polish UX nhẹ
- test end-to-end thật kỹ
- cập nhật tài liệu bàn giao

Nếu mục tiêu là **tiếp tục phát triển lên app dùng thật**, cần coi 4 việc sau là bắt buộc:

- security cleanup
- access control cleanup
- DB migration
- test automation tối thiểu

