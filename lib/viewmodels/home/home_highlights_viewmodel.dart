import 'package:flutter/material.dart';
import 'package:du_xuan/data/interfaces/repositories/i_checklist_repository.dart';
import 'package:du_xuan/domain/entities/checklist_item.dart';
import 'package:du_xuan/domain/entities/plan.dart';

class HomeHighlightsViewModel extends ChangeNotifier {
  final IChecklistRepository _checklistRepository;

  HomeHighlightsViewModel({
    required IChecklistRepository checklistRepository,
  }) : _checklistRepository = checklistRepository;

  bool _isLoading = false;
  String? _errorMessage;
  int? _planId;
  List<ChecklistItem> _checklistItems = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ChecklistItem> get checklistItems => _checklistItems;
  int? get planId => _planId;

  int get checklistPackedCount => _checklistItems.where((item) => item.isPacked).length;
  int get checklistTotalCount => _checklistItems.length;
  int get checklistRemainingCount =>
      _checklistItems.where((item) => !item.isPacked).length;
  double get checklistProgress {
    if (_checklistItems.isEmpty) return 0;
    return checklistPackedCount / _checklistItems.length;
  }

  List<ChecklistItem> get remainingChecklistPreview {
    final items = _checklistItems.where((item) => !item.isPacked).toList()
      ..sort((a, b) {
        final priorityCompare = b.priority.compareTo(a.priority);
        if (priorityCompare != 0) return priorityCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return items.take(3).toList();
  }

  Future<void> loadForPlan(Plan? plan) async {
    final targetPlanId = plan?.id;
    _planId = targetPlanId;

    if (plan == null) {
      _checklistItems = [];
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final checklist = await _checklistRepository.getByPlanId(plan.id);

      if (_planId != targetPlanId) return;

      _checklistItems = checklist;
      _errorMessage = null;
    } catch (e) {
      if (_planId != targetPlanId) return;
      _checklistItems = [];
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    if (_planId != targetPlanId) return;
    _isLoading = false;
    notifyListeners();
  }
}
