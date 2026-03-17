import 'package:flutter/material.dart';
import 'package:du_xuan/core/enums/activity_status.dart';
import 'package:du_xuan/core/enums/plan_status.dart';
import 'package:du_xuan/core/utils/notification_service.dart';
import 'package:du_xuan/data/interfaces/repositories/i_activity_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_repository.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';

class ItineraryViewModel extends ChangeNotifier {
  final IPlanRepository _planRepo;
  final IActivityRepository _activityRepo;
  final NotificationService _notificationService;

  ItineraryViewModel({
    required IPlanRepository planRepo,
    required IActivityRepository activityRepo,
    required NotificationService notificationService,
  }) : _planRepo = planRepo,
       _activityRepo = activityRepo,
       _notificationService = notificationService;

  // ─── State ────────────────────────────────────────────
  Plan? _plan;
  int _selectedDayIndex = 0;
  Map<int, List<Activity>> _allActivitiesByDay = {};
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ──────────────────────────────────────────
  Plan? get plan => _plan;
  List<PlanDay> get days => _plan?.days ?? [];
  int get selectedDayIndex => _selectedDayIndex;
  PlanDay? get selectedDay => days.isNotEmpty && _selectedDayIndex < days.length
      ? days[_selectedDayIndex]
      : null;
  List<Activity> get activities {
    final day = selectedDay;
    if (day == null) return const [];
    return List.unmodifiable(_allActivitiesByDay[day.id] ?? const <Activity>[]);
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Lấy activities cho 1 ngày cụ thể (dùng cho DayListTab summary)
  List<Activity> activitiesForDay(int planDayId) =>
      _allActivitiesByDay[planDayId] ?? [];

  /// Tổng chi phí ước tính của ngày hiện tại
  double get totalCostOfDay {
    return activities.fold(0.0, (sum, a) => sum + (a.estimatedCost ?? 0));
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
      _plan!.endDate.year,
      _plan!.endDate.month,
      _plan!.endDate.day,
    );
    return today.isAfter(end);
  }

  /// Plan đang diễn ra (hôm nay nằm trong khoảng startDate..endDate)
  bool get isOngoing {
    if (_plan == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      _plan!.startDate.year,
      _plan!.startDate.month,
      _plan!.startDate.day,
    );
    final end = DateTime(
      _plan!.endDate.year,
      _plan!.endDate.month,
      _plan!.endDate.day,
    );
    return !today.isBefore(start) && !today.isAfter(end);
  }

  /// Tất cả activity hiện có đều đã done và có ít nhất một activity.
  bool get isAllDaysCompleted {
    if (_plan == null || days.isEmpty) return false;
    var hasAnyActivity = false;

    for (final day in days) {
      final activities = _allActivitiesByDay[day.id] ?? const <Activity>[];
      if (activities.isEmpty) continue;
      hasAnyActivity = true;
      final hasUndone = activities.any((a) => a.status != ActivityStatus.done);
      if (hasUndone) return false;
    }
    return hasAnyActivity;
  }

  /// Có thể đánh dấu completed khi plan đang diễn ra và toàn bộ hoạt động đã xong.
  bool get canMarkPlanCompleted {
    if (_plan == null || isViewMode) return false;
    if (_plan!.status != PlanStatus.active) return false;
    return isOngoing && isAllDaysCompleted;
  }

  // ─── Actions ──────────────────────────────────────────

  Future<void> loadPlan(int planId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final loadedPlan = await _planRepo.getById(planId);
      final allActivitiesByDay = <int, List<Activity>>{};

      _plan = loadedPlan;
      _selectedDayIndex = 0;
      _errorMessage = null;

      // Load activities cho TẤT CẢ ngày song song (tránh block main thread)
      final futures = days.map((day) async {
        final acts = await _activityRepo.getByPlanDayId(day.id);
        allActivitiesByDay[day.id] = acts;
      });
      await Future.wait(futures);
      _allActivitiesByDay = allActivitiesByDay;
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
    await _refreshSelectedDayActivities(notifyAfterFetch: true);
  }

  Future<void> _refreshSelectedDayActivities({
    bool notifyAfterFetch = true,
  }) async {
    final day = selectedDay;
    if (day == null) {
      if (notifyAfterFetch) {
        notifyListeners();
      }
      return;
    }

    try {
      final refreshed = await _activityRepo.getByPlanDayId(day.id);
      _setActivitiesForDay(day.id, refreshed);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    if (notifyAfterFetch) {
      notifyListeners();
    }
  }

  Future<void> refreshActivities() async {
    await _refreshSelectedDayActivities();
  }

  Future<bool> deleteActivity(int id) async {
    try {
      await _activityRepo.delete(id);
      _removeActivityFromCache(id);
      _errorMessage = null;
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
    final location = _findActivityLocation(activityId);
    if (location != null) {
      final dayActivities = _activitiesBucket(location.dayId);
      dayActivities.removeAt(location.index);
      notifyListeners();
      return location.index;
    }
    return -1;
  }

  /// Khôi phục activity vào UI — dùng cho undo
  void restoreLocally(Activity activity, int index) {
    final dayActivities = _activitiesBucket(activity.planDayId);
    if (index >= 0 && index <= dayActivities.length) {
      dayActivities.insert(index, activity);
    } else {
      dayActivities.add(activity);
    }
    notifyListeners();
  }

  Future<void> toggleActivityStatus(int id) async {
    try {
      await _activityRepo.toggleStatus(id);
      await _refreshSelectedDayActivities();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Đánh dấu plan hoàn thành
  Future<bool> markPlanCompleted() async {
    if (_plan == null) return false;
    if (!canMarkPlanCompleted) {
      _errorMessage =
          'Chỉ có thể hoàn thành khi kế hoạch đang diễn ra và tất cả hoạt động hiện có đã xong.';
      notifyListeners();
      return false;
    }
    try {
      final updated = _plan!.copyWith(status: PlanStatus.completed);
      await _planRepo.update(updated);
      await _syncPlanReminder(updated);
      _plan = updated;
      _errorMessage = null;
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
      await _syncPlanReminder(updated);
      _plan = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
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

  void _setActivitiesForDay(int planDayId, List<Activity> activities) {
    _allActivitiesByDay[planDayId] = List<Activity>.from(activities);
  }

  List<Activity> _activitiesBucket(int planDayId) {
    return _allActivitiesByDay.putIfAbsent(planDayId, () => <Activity>[]);
  }

  ({int dayId, int index})? _findActivityLocation(int activityId) {
    final currentDayId = selectedDay?.id;
    if (currentDayId != null) {
      final currentIndex = _activitiesBucket(
        currentDayId,
      ).indexWhere((a) => a.id == activityId);
      if (currentIndex >= 0) {
        return (dayId: currentDayId, index: currentIndex);
      }
    }

    for (final entry in _allActivitiesByDay.entries) {
      final index = entry.value.indexWhere((a) => a.id == activityId);
      if (index >= 0) {
        return (dayId: entry.key, index: index);
      }
    }
    return null;
  }

  void _removeActivityFromCache(int activityId) {
    final location = _findActivityLocation(activityId);
    if (location == null) return;
    _activitiesBucket(location.dayId).removeAt(location.index);
  }
}
