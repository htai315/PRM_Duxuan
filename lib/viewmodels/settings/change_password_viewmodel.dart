import 'package:flutter/material.dart';
import 'package:du_xuan/data/interfaces/repositories/iauth_repository.dart';

class ChangePasswordViewModel extends ChangeNotifier {
  final IAuthRepository _authRepo;

  ChangePasswordViewModel(this._authRepo);

  // ─── State ────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // ─── Getters ──────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSuccess => _isSuccess;
  bool get obscureOld => _obscureOld;
  bool get obscureNew => _obscureNew;
  bool get obscureConfirm => _obscureConfirm;

  // ─── Toggle visibility ────────────────────────────────
  void toggleObscureOld() {
    _obscureOld = !_obscureOld;
    notifyListeners();
  }

  void toggleObscureNew() {
    _obscureNew = !_obscureNew;
    notifyListeners();
  }

  void toggleObscureConfirm() {
    _obscureConfirm = !_obscureConfirm;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Đổi mật khẩu ────────────────────────────────────

  Future<bool> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // Validation
    if (oldPassword.isEmpty) {
      _errorMessage = 'Vui lòng nhập mật khẩu cũ';
      notifyListeners();
      return false;
    }
    if (newPassword.isEmpty) {
      _errorMessage = 'Vui lòng nhập mật khẩu mới';
      notifyListeners();
      return false;
    }
    if (newPassword.length < 6) {
      _errorMessage = 'Mật khẩu mới phải có ít nhất 6 ký tự';
      notifyListeners();
      return false;
    }
    if (newPassword != confirmPassword) {
      _errorMessage = 'Mật khẩu xác nhận không khớp';
      notifyListeners();
      return false;
    }
    if (newPassword == oldPassword) {
      _errorMessage = 'Mật khẩu mới phải khác mật khẩu cũ';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepo.changePassword(userId, oldPassword, newPassword);
      _isLoading = false;
      _isSuccess = true;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
