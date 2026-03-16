import 'package:flutter/material.dart';
import 'package:du_xuan/core/utils/notification_service.dart';
import 'package:du_xuan/core/utils/pagination_utils.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_repository.dart';
import 'package:du_xuan/domain/entities/plan.dart';

class PlanListViewModel extends ChangeNotifier {
  final IPlanRepository _repository;
  final NotificationService _notificationService;

  PlanListViewModel(this._repository, this._notificationService);

  // ─── State ────────────────────────────────────────────
  List<Plan> _plans = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Pagination state
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = PaginationConfig.defaultPageSize;

  // ─── Getters ──────────────────────────────────────────
  List<Plan> get plans => _plans;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get planCount => _plans.length;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  // ─── Actions ──────────────────────────────────────────

  Future<void> loadPlans(int userId, {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _plans = [];
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_hasMore) {
        final result = await _repository.getMyPlansPaged(userId, _currentPage, _pageSize);
        _plans = result.items;
        _hasMore = result.hasMore;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore(int userId) async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final result = await _repository.getMyPlansPaged(userId, nextPage, _pageSize);
      
      _plans.addAll(result.items);
      _currentPage = nextPage;
      _hasMore = result.hasMore;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<bool> deletePlan(int id) async {
    try {
      await _repository.delete(id);
      try {
        await _notificationService.cancelPlanReminder(id);
      } catch (e) {
        debugPrint('Notification cleanup error (plan $id): $e');
      }
      _plans.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
