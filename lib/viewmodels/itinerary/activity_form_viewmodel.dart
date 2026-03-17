import 'package:flutter/material.dart';
import 'package:du_xuan/core/enums/activity_status.dart';
import 'package:du_xuan/core/enums/activity_type.dart';
import 'package:du_xuan/core/utils/app_form_validators.dart';
import 'package:du_xuan/data/interfaces/repositories/i_activity_repository.dart';
import 'package:du_xuan/domain/entities/activity.dart';

class ActivityFormViewModel extends ChangeNotifier {
  final IActivityRepository _repository;

  ActivityFormViewModel(this._repository);

  // ─── State ────────────────────────────────────────────
  Activity? _existingActivity;
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ──────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEditMode => _existingActivity != null;
  Activity? get existingActivity => _existingActivity;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setExisting(Activity activity) {
    _existingActivity = activity;
    notifyListeners();
  }

  /// Validate + Save
  Future<Activity?> saveActivity({
    required int planDayId,
    required String title,
    required ActivityType activityType,
    String? startTime,
    String? endTime,
    String? locationText,
    String? note,
    String? estimatedCostText,
  }) async {
    final titleError = AppFormValidators.validateActivityTitle(title);
    if (titleError != null) {
      _errorMessage = titleError;
      notifyListeners();
      return null;
    }

    final timeError = AppFormValidators.validateActivityTimeRange(
      startTime,
      endTime,
    );
    if (timeError != null) {
      _errorMessage = timeError;
      notifyListeners();
      return null;
    }

    final costResult = AppFormValidators.parseEstimatedCost(
      estimatedCostText ?? '',
    );
    if (!costResult.isValid) {
      _errorMessage = costResult.errorMessage;
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final activity = Activity(
        id: _existingActivity?.id ?? 0,
        planDayId: planDayId,
        title: title.trim(),
        activityType: activityType,
        startTime: startTime?.isNotEmpty == true ? startTime : null,
        endTime: endTime?.isNotEmpty == true ? endTime : null,
        locationText: locationText?.trim(),
        note: note?.trim(),
        estimatedCost: costResult.value,
        priority: _existingActivity?.priority ?? 0,
        orderIndex: _existingActivity?.orderIndex ?? 0,
        status: _existingActivity?.status ?? ActivityStatus.todo,
      );

      Activity result;
      if (isEditMode) {
        await _repository.update(activity);
        result = activity;
      } else {
        result = await _repository.create(activity);
      }

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
}
