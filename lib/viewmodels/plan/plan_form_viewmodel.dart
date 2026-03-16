import 'package:flutter/material.dart';
import 'package:du_xuan/core/enums/plan_status.dart';
import 'package:du_xuan/core/utils/notification_service.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_repository.dart';
import 'package:du_xuan/domain/entities/plan.dart';

class PlanFormViewModel extends ChangeNotifier {
  final IPlanRepository _repository;
  final NotificationService _notificationService;

  PlanFormViewModel(this._repository, this._notificationService);

  // ─── State ────────────────────────────────────────────
  Plan? _existingPlan;
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ──────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEditMode => _existingPlan != null;

  // ─── Actions ──────────────────────────────────────────

  /// Load plan hiện tại nếu edit mode
  Future<void> loadPlan(int planId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _existingPlan = await _repository.getById(planId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Plan? get existingPlan => _existingPlan;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Validate + Save plan. Trả về Plan nếu thành công.
  Future<Plan?> savePlan({
    required int userId,
    required String name,
    String? description,
    required DateTime? startDate,
    required DateTime? endDate,
    String? participants,
    String? note,
  }) async {
    // ─── Validation ─────────────────────────────────
    if (name.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập tên kế hoạch';
      notifyListeners();
      return null;
    }
    if (startDate == null) {
      _errorMessage = 'Vui lòng chọn ngày bắt đầu';
      notifyListeners();
      return null;
    }
    if (endDate == null) {
      _errorMessage = 'Vui lòng chọn ngày kết thúc';
      notifyListeners();
      return null;
    }
    if (endDate.isBefore(startDate)) {
      _errorMessage = 'Ngày kết thúc phải sau ngày bắt đầu';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final plan = Plan(
        id: _existingPlan?.id ?? 0,
        userId: isEditMode ? _existingPlan!.userId : userId,
        name: name.trim(),
        description: description?.trim(),
        startDate: startDate,
        endDate: endDate,
        participants: participants?.trim(),
        note: note?.trim(),
        status: _existingPlan?.status ?? PlanStatus.active,
        createdAt: _existingPlan?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      Plan result;
      if (isEditMode) {
        await _repository.update(plan);
        result = plan;
      } else {
        result = await _repository.create(plan);
      }
      await _syncPlanReminder(result);

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<void> _syncPlanReminder(Plan plan) async {
    try {
      if (plan.status == PlanStatus.active) {
        await _notificationService.schedulePlanReminder(plan);
      } else {
        await _notificationService.cancelPlanReminder(plan.id);
      }
    } catch (e) {
      debugPrint('Notification sync error (plan ${plan.id}): $e');
    }
  }
}
