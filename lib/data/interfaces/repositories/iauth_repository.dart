import 'package:du_xuan/domain/entities/auth_session.dart';

abstract class IAuthRepository {
  /// Đăng nhập
  Future<AuthSession> login(String userName, String password);

  /// Đăng ký tài khoản mới
  Future<AuthSession> register(String userName, String fullName, String password);

  /// Lấy session hiện tại
  Future<AuthSession?> getCurrentSession();

  /// Đăng xuất
  Future<void> logout();

  /// Đổi mật khẩu
  Future<void> changePassword(int userId, String oldPassword, String newPassword);
}
