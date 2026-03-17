import 'package:flutter/material.dart';
import 'package:du_xuan/core/enums/checklist_category.dart';
import 'package:du_xuan/core/enums/checklist_source.dart';
import 'package:du_xuan/data/interfaces/repositories/i_checklist_repository.dart';
import 'package:du_xuan/domain/entities/checklist_item.dart';

class ChecklistViewModel extends ChangeNotifier {
  final IChecklistRepository _repository;

  ChecklistViewModel(this._repository);

  // ─── State ────────────────────────────────────────────
  List<ChecklistItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Getters ──────────────────────────────────────────
  List<ChecklistItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalCount => _items.length;
  int get packedCount => _items.where((i) => i.isPacked).length;

  /// Phần trăm tiến trình 0.0 → 1.0
  double get progressPercent => totalCount == 0 ? 0 : packedCount / totalCount;

  /// Nhóm items theo category
  Map<ChecklistCategory, List<ChecklistItem>> get groupedByCategory {
    final map = <ChecklistCategory, List<ChecklistItem>>{};
    for (final item in _items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  // ─── Actions ──────────────────────────────────────────

  Future<void> loadItems(int planId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _repository.getByPlanId(planId);
      _sortItems();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<ChecklistItem?> addItem({
    required int planId,
    required String name,
    int quantity = 1,
    ChecklistCategory category = ChecklistCategory.other,
    String? note,
  }) async {
    if (name.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập tên vật dụng';
      notifyListeners();
      return null;
    }

    try {
      final item = ChecklistItem(
        id: 0,
        planId: planId,
        name: name.trim(),
        quantity: quantity,
        category: category,
        note: note?.trim(),
        source: ChecklistSource.manual,
      );
      final created = await _repository.create(item);
      _items.add(created);
      _sortItems();
      _errorMessage = null;
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateItem(ChecklistItem item) async {
    try {
      await _repository.update(item);
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index >= 0) _items[index] = item;
      _sortItems();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(int id) async {
    try {
      await _repository.delete(id);
      _items.removeWhere((i) => i.id == id);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> togglePacked(int id) async {
    try {
      await _repository.togglePacked(id);
      final index = _items.indexWhere((i) => i.id == id);
      if (index >= 0) {
        _items[index] = _items[index].copyWith(
          isPacked: !_items[index].isPacked,
        );
      }
      _sortItems();
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void _sortItems() {
    _items.sort((a, b) {
      final categoryCompare = a.category.name.compareTo(b.category.name);
      if (categoryCompare != 0) return categoryCompare;

      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
