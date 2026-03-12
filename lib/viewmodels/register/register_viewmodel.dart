import 'package:flutter/material.dart';
import 'package:du_xuan/data/interfaces/repositories/iauth_repository.dart';
import 'package:du_xuan/domain/entities/auth_session.dart';

class RegisterViewModel extends ChangeNotifier {
  final IAuthRepository _repository;

  RegisterViewModel(this._repository);

  // ─── State ────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ─── Getters ──────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;

  // ─── Actions ──────────────────────────────────────────

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleObscureConfirmPassword() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Đăng ký. Trả về AuthSession nếu thành công, null nếu thất bại.
  Future<AuthSession?> register(
    String userName,
    String fullName,
    String password,
    String confirmPassword,
  ) async {
    // Validation
    if (userName.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập tên đăng nhập';
      notifyListeners();
      return null;
    }
    if (fullName.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập họ tên';
      notifyListeners();
      return null;
    }
    if (password.isEmpty) {
      _errorMessage = 'Vui lòng nhập mật khẩu';
      notifyListeners();
      return null;
    }
    if (password.length < 6) {
      _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự';
      notifyListeners();
      return null;
    }
    if (password != confirmPassword) {
      _errorMessage = 'Mật khẩu xác nhận không khớp';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _repository.register(
        userName.trim(),
        fullName.trim(),
        password,
      );
      _isLoading = false;
      notifyListeners();
      return session;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
}
