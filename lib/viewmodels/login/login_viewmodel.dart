import 'package:flutter/material.dart';
import 'package:du_xuan/data/interfaces/repositories/iauth_repository.dart';
import 'package:du_xuan/domain/entities/auth_session.dart';

class LoginViewModel extends ChangeNotifier {
  final IAuthRepository _repository;

  LoginViewModel(this._repository);

  // ─── State ────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  // ─── Getters ──────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get obscurePassword => _obscurePassword;

  // ─── Actions ──────────────────────────────────────────

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Đăng nhập. Trả về AuthSession nếu thành công, null nếu thất bại.
  Future<AuthSession?> login(String userName, String password) async {
    // Validation
    if (userName.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập tài khoản';
      notifyListeners();
      return null;
    }
    if (password.isEmpty) {
      _errorMessage = 'Vui lòng nhập mật khẩu';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _repository.login(userName.trim(), password);
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

  /// Kiểm tra session hiện tại (auto-login)
  Future<AuthSession?> checkCurrentSession() async {
    try {
      return await _repository.getCurrentSession();
    } catch (_) {
      return null;
    }
  }
}
