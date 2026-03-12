import 'package:flutter/material.dart';
import 'package:du_xuan/data/interfaces/repositories/iauth_repository.dart';
import 'package:du_xuan/domain/entities/auth_session.dart';

class HomeViewModel extends ChangeNotifier {
  final IAuthRepository _authRepo;

  HomeViewModel(this._authRepo);

  // ─── State ────────────────────────────────────────────
  int _currentTab = 0;
  AuthSession? _session;
  bool _isLoading = true;

  // ─── Getters ──────────────────────────────────────────
  int get currentTab => _currentTab;
  AuthSession? get session => _session;
  bool get isLoading => _isLoading;
  String get userName => _session?.user.fullName ?? 'Bạn';

  // ─── Actions ──────────────────────────────────────────

  void switchTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  /// Load thông tin user hiện tại
  Future<void> loadSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      _session = await _authRepo.getCurrentSession();
    } catch (e) {
      debugPrint('❌ loadSession error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Đăng xuất
  Future<void> logout() async {
    await _authRepo.logout();
  }
}
