import 'package:flutter/material.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_copy_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_user_repository.dart';
import 'package:du_xuan/domain/entities/user.dart';

class PlanCopyShareViewModel extends ChangeNotifier {
  final IUserRepository _userRepository;
  final IPlanCopyRepository _planCopyRepository;

  PlanCopyShareViewModel({
    required IUserRepository userRepository,
    required IPlanCopyRepository planCopyRepository,
  }) : _userRepository = userRepository,
       _planCopyRepository = planCopyRepository;

  List<User> _allUsers = [];
  List<User> _users = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String _query = '';

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get query => _query;

  Future<void> loadRecipients({required int excludeUserId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allUsers = await _userRepository.getAll(excludeUserId: excludeUserId);
      _applyFilter(_query);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  void updateQuery(String value) {
    _query = value.trim();
    _applyFilter(_query);
    notifyListeners();
  }

  Future<int?> sendRequest({
    required int sourcePlanId,
    required int sourceUserId,
    required int targetUserId,
  }) async {
    if (_isSubmitting) return null;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final requestId = await _planCopyRepository.createCopyRequest(
        sourcePlanId: sourcePlanId,
        sourceUserId: sourceUserId,
        targetUserId: targetUserId,
      );
      _isSubmitting = false;
      notifyListeners();
      return requestId;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void _applyFilter(String query) {
    if (query.isEmpty) {
      _users = List<User>.from(_allUsers);
      return;
    }

    final normalized = query.toLowerCase();
    _users = _allUsers.where((user) {
      return user.fullName.toLowerCase().contains(normalized) ||
          user.userName.toLowerCase().contains(normalized);
    }).toList();
  }
}
