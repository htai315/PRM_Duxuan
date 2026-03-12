import 'package:du_xuan/data/dtos/login/login_request_dto.dart';
import 'package:du_xuan/data/dtos/login/login_response_dto.dart';
import 'package:du_xuan/data/dtos/login/register_request_dto.dart';

abstract class IAuthApi {
  /// Đăng nhập: kiểm tra username + password
  Future<LoginResponseDto> login(LoginRequestDto req);

  /// Đăng ký: tạo tài khoản mới
  Future<LoginResponseDto> register(RegisterRequestDto req);

  /// Lấy session hiện tại (null nếu chưa đăng nhập)
  Future<LoginResponseDto?> getCurrentSession();

  /// Đăng xuất: xóa session
  Future<void> logout();

  /// Đổi mật khẩu
  Future<void> changePassword(int userId, String oldPassword, String newPassword);
}
