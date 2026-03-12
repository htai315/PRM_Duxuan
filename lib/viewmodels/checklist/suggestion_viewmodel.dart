import 'package:flutter/material.dart';
import 'package:du_xuan/core/enums/checklist_category.dart';
import 'package:du_xuan/core/enums/checklist_source.dart';
import 'package:du_xuan/data/implementations/api/openai_service.dart';
import 'package:du_xuan/data/interfaces/repositories/i_activity_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_checklist_repository.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_repository.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/domain/entities/checklist_item.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';

class SuggestionViewModel extends ChangeNotifier {
  final IPlanRepository _planRepo;
  final IActivityRepository _activityRepo;
  final IChecklistRepository _checklistRepo;
  final OpenAiService _openAiService;

  SuggestionViewModel({
    required IPlanRepository planRepo,
    required IActivityRepository activityRepo,
    required IChecklistRepository checklistRepo,
    required OpenAiService openAiService,
  })  : _planRepo = planRepo,
        _activityRepo = activityRepo,
        _checklistRepo = checklistRepo,
        _openAiService = openAiService;

  // ─── State ────────────────────────────────────────────
  List<SuggestedItem> _suggestions = [];
  Set<int> _selectedIndices = {};
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ──────────────────────────────────────────
  List<SuggestedItem> get suggestions => _suggestions;
  Set<int> get selectedIndices => _selectedIndices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedCount => _selectedIndices.length;

  /// Nhóm suggestions theo category
  Map<ChecklistCategory, List<MapEntry<int, SuggestedItem>>>
      get groupedSuggestions {
    final map =
        <ChecklistCategory, List<MapEntry<int, SuggestedItem>>>{};
    for (var i = 0; i < _suggestions.length; i++) {
      final item = _suggestions[i];
      map
          .putIfAbsent(item.category, () => [])
          .add(MapEntry(i, item));
    }
    return map;
  }

  // ─── Actions ──────────────────────────────────────────

  /// Gọi AI gợi ý dựa trên plan + activities + existing checklist
  Future<void> fetchSuggestions(int planId) async {
    _isLoading = true;
    _errorMessage = null;
    _suggestions = [];
    _selectedIndices = {};
    notifyListeners();

    try {
      // 1. Load plan + activities + existing checklist
      final plan = await _planRepo.getById(planId);
      if (plan == null) throw Exception('Không tìm thấy kế hoạch');

      final activitiesByDay = <PlanDay, List<Activity>>{};
      for (final day in plan.days) {
        final activities = await _activityRepo.getByPlanDayId(day.id);
        activitiesByDay[day] = activities;
      }

      final existingItems = await _checklistRepo.getByPlanId(planId);
      final existingNames = existingItems.map((i) => i.name).toList();

      // 2. Gọi OpenAI (key đã hardcode trong ApiConstants)
      _suggestions = await _openAiService.suggestItems(
        plan: plan,
        activitiesByDay: activitiesByDay,
        existingItemNames: existingNames,
      );

      // Mặc định chọn tất cả
      _selectedIndices = Set.from(
        List.generate(_suggestions.length, (i) => i),
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  void toggleSelect(int index) {
    if (_selectedIndices.contains(index)) {
      _selectedIndices.remove(index);
    } else {
      _selectedIndices.add(index);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedIndices = Set.from(
      List.generate(_suggestions.length, (i) => i),
    );
    notifyListeners();
  }

  void deselectAll() {
    _selectedIndices = {};
    notifyListeners();
  }

  /// Thêm các items đã chọn vào checklist DB
  Future<int> addSelectedToChecklist(int planId) async {
    var addedCount = 0;
    for (final idx in _selectedIndices) {
      final suggestion = _suggestions[idx];
      final item = ChecklistItem(
        id: 0,
        planId: planId,
        name: suggestion.name,
        quantity: suggestion.quantity,
        category: suggestion.category,
        source: ChecklistSource.suggested,
      );
      await _checklistRepo.create(item);
      addedCount++;
    }
    return addedCount;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
