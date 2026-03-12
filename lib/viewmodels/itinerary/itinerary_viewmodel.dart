import 'package:flutter/material.dart';
import 'package:du_xuan/core/enums/plan_status.dart';
import 'package:du_xuan/data/interfaces/repositories/i_activity_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_repository.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';

class ItineraryViewModel extends ChangeNotifier {
  final IPlanRepository _planRepo;
  final IActivityRepository _activityRepo;

  ItineraryViewModel({
    required IPlanRepository planRepo,
    required IActivityRepository activityRepo,
  })  : _planRepo = planRepo,
        _activityRepo = activityRepo;

  // ─── State ────────────────────────────────────────────
  Plan? _plan;
  int _selectedDayIndex = 0;
  List<Activity> _activities = [];
  Map<int, List<Activity>> _allActivitiesByDay = {};
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ──────────────────────────────────────────
  Plan? get plan => _plan;
  List<PlanDay> get days => _plan?.days ?? [];
  int get selectedDayIndex => _selectedDayIndex;
  PlanDay? get selectedDay =>
      days.isNotEmpty && _selectedDayIndex < days.length
          ? days[_selectedDayIndex]
          : null;
  List<Activity> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Lấy activities cho 1 ngày cụ thể (dùng cho DayListTab summary)
  List<Activity> activitiesForDay(int planDayId) =>
      _allActivitiesByDay[planDayId] ?? [];

  /// Tổng chi phí ước tính của ngày hiện tại
  double get totalCostOfDay {
    return _activities.fold(0.0, (sum, a) => sum + (a.estimatedCost ?? 0));
  }

  /// Chế độ xem: chỉ khi status đã completed/archived
  bool get isViewMode {
    if (_plan == null) return false;
    final status = _plan!.status;
    return status == PlanStatus.completed || status == PlanStatus.archived;
  }

  /// Đã qua ngày kết thúc nhưng chưa đánh dấu hoàn thành
  bool get isOverdue {
    if (_plan == null) return false;
    if (isViewMode) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(
      _plan!.endDate.year, _plan!.endDate.month, _plan!.endDate.day,
    );
    return today.isAfter(end);
  }

  // ─── Actions ──────────────────────────────────────────

  Future<void> loadPlan(int planId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _plan = await _planRepo.getById(planId);
      _selectedDayIndex = 0;

      // Load activities cho TẤT CẢ ngày song song (tránh block main thread)
      _allActivitiesByDay = {};
      final futures = days.map((day) async {
        final acts = await _activityRepo.getByPlanDayId(day.id);
        _allActivitiesByDay[day.id] = acts;
      });
      await Future.wait(futures);

      if (selectedDay != null) {
        _activities = _allActivitiesByDay[selectedDay!.id] ?? [];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectDay(int index) async {
    if (index == _selectedDayIndex) return;
    _selectedDayIndex = index;
    notifyListeners();
    await _loadActivities();
  }

  Future<void> _loadActivities() async {
    final day = selectedDay;
    if (day == null) {
      _activities = [];
      notifyListeners();
      return;
    }

    try {
      _activities = await _activityRepo.getByPlanDayId(day.id);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> refreshActivities() async {
    await _loadActivities();
  }

  Future<bool> deleteActivity(int id) async {
    try {
      await _activityRepo.delete(id);
      _activities.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Xóa khỏi UI (chưa xóa DB) — dùng cho undo snackbar
  int removeLocally(int activityId) {
    final index = _activities.indexWhere((a) => a.id == activityId);
    if (index >= 0) {
      _activities.removeAt(index);
      notifyListeners();
    }
    return index;
  }

  /// Khôi phục activity vào UI — dùng cho undo
  void restoreLocally(Activity activity, int index) {
    if (index >= 0 && index <= _activities.length) {
      _activities.insert(index, activity);
    } else {
      _activities.add(activity);
    }
    notifyListeners();
  }

  Future<void> toggleActivityStatus(int id) async {
    try {
      await _activityRepo.toggleStatus(id);
      await _loadActivities();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Đánh dấu plan hoàn thành
  Future<bool> markPlanCompleted() async {
    if (_plan == null) return false;
    try {
      final updated = _plan!.copyWith(status: PlanStatus.completed);
      await _planRepo.update(updated);
      _plan = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Mở lại chỉnh sửa (từ completed → active)
  Future<bool> reopenForEditing() async {
    if (_plan == null) return false;
    try {
      final updated = _plan!.copyWith(status: PlanStatus.active);
      await _planRepo.update(updated);
      _plan = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
