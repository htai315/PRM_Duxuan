# Public Share Stub

Stub local này dùng để test end-to-end tính năng `link công khai` mà chưa cần backend thật.

## Chạy stub server

Từ root project:

```powershell
dart run tool/public_share_stub_server.dart
```

Server mặc định:

- API cho Android emulator: `http://10.0.2.2:8787`
- Trang public trên máy host: `http://localhost:8787`

## Cấu hình app

Trong debug build hiện tại, app đã mặc định trỏ `PUBLIC_SHARE_API_URL` tới:

```text
http://10.0.2.2:8787
```

Nếu muốn đổi host/port khi chạy stub:

```powershell
$env:PUBLIC_SHARE_STUB_PORT='8899'
$env:PUBLIC_SHARE_PUBLIC_BASE_URL='http://localhost:8899'
dart run tool/public_share_stub_server.dart
```

Và build app với:

```powershell
flutter run --dart-define=PUBLIC_SHARE_API_URL=http://10.0.2.2:8899
```

## Smoke test

Có sẵn script kiểm tra nhanh API + public page:

```powershell
dart run tool/public_share_stub_smoke_test.dart
```

## Luồng test tay

1. Chạy stub server.
2. Mở app debug trên emulator Android.
3. Vào `Chi tiết kế hoạch` -> menu `...`.
4. Chọn `Tạo link công khai`.
5. App sẽ copy link vào clipboard.
6. Mở link đó trên emulator hoặc vào `http://localhost:8787` trên máy để xem danh sách share và public page.
