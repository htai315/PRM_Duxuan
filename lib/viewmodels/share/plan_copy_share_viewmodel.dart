import 'package:flutter/material.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_copy_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_user_repository.dart';
import 'package:du_xuan/domain/entities/user.dart';

class PlanCopyShareViewModel extends ChangeNotifier {
  final IUserRepository _userRepository;
  final IPlanCopyRepository _planCopyRepository;
  static const int _searchLimit = 20;

  PlanCopyShareViewModel({
    required IUserRepository userRepository,
    required IPlanCopyRepository planCopyRepository,
  }) : _userRepository = userRepository,
       _planCopyRepository = planCopyRepository;

  List<User> _users = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _hasSearched = false;
  String? _errorMessage;
  String _query = '';
  int? _excludeUserId;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get hasSearched => _hasSearched;
  String? get errorMessage => _errorMessage;
  String get query => _query;

  Future<void> loadRecipients({required int excludeUserId}) async {
    _excludeUserId = excludeUserId;
    _users = [];
    _query = '';
    _hasSearched = false;
    _errorMessage = null;
    notifyListeners();
  }

  void updateQuery(String value) {
    _query = value.trim();
    _errorMessage = null;
    if (_query.isEmpty) {
      _users = [];
      _hasSearched = false;
    }
    notifyListeners();
  }

  Future<void> searchRecipients() async {
    final normalizedQuery = _query.trim();
    if (normalizedQuery.isEmpty) {
      _users = [];
      _hasSearched = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _hasSearched = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _userRepository.search(
        normalizedQuery,
        excludeUserId: _excludeUserId,
        limit: _searchLimit,
      );
    } catch (e) {
      _users = [];
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
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
}
