import 'package:du_xuan/core/enums/expense_category.dart';
import 'package:du_xuan/core/enums/expense_source.dart';
import 'package:du_xuan/core/utils/app_form_validators.dart';
import 'package:du_xuan/data/interfaces/repositories/i_expense_repository.dart';
import 'package:du_xuan/domain/entities/expense.dart';
import 'package:flutter/material.dart';

class ExpenseViewModel extends ChangeNotifier {
  final IExpenseRepository _repository;

  ExpenseViewModel(this._repository);

  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _loadedPlanId;

  List<Expense> get expenses => List.unmodifiable(_expenses);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalCount => _expenses.length;
  int? get loadedPlanId => _loadedPlanId;

  double get totalAmount =>
      _expenses.fold(0.0, (sum, expense) => sum + expense.amount);

  Future<void> loadExpenses(int planId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _expenses = await _repository.getByPlanId(planId);
      _sortExpenses();
      _loadedPlanId = planId;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Expense?> addExpense({
    required int planId,
    int? planDayId,
    int? activityId,
    required String title,
    required String amountText,
    required ExpenseCategory category,
    String? note,
    DateTime? spentAt,
  }) async {
    if (title.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập tên khoản chi';
      notifyListeners();
      return null;
    }

    final amountResult = AppFormValidators.parseEstimatedCost(amountText);
    if (!amountResult.isValid || amountResult.value == null) {
      _errorMessage = amountResult.errorMessage ?? 'Chi phí không hợp lệ';
      notifyListeners();
      return null;
    }
    if (amountResult.value! <= 0) {
      _errorMessage = 'Số tiền phải lớn hơn 0';
      notifyListeners();
      return null;
    }

    try {
      final now = DateTime.now();
      final expense = Expense(
        id: 0,
        planId: planId,
        planDayId: planDayId,
        activityId: activityId,
        title: title.trim(),
        amount: amountResult.value!,
        category: category,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        spentAt: spentAt ?? now,
        createdAt: now,
        updatedAt: now,
        source: ExpenseSource.manual,
      );
      final created = await _repository.create(expense);
      _expenses.add(created);
      _sortExpenses();
      _errorMessage = null;
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateExpense(Expense expense) async {
    if (expense.title.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập tên khoản chi';
      notifyListeners();
      return false;
    }
    if (expense.amount <= 0) {
      _errorMessage = 'Số tiền phải lớn hơn 0';
      notifyListeners();
      return false;
    }

    try {
      await _repository.update(expense);
      final index = _expenses.indexWhere((item) => item.id == expense.id);
      if (index >= 0) {
        _expenses[index] = expense;
      }
      _sortExpenses();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await _repository.delete(id);
      _expenses.removeWhere((expense) => expense.id == id);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  List<Expense> expensesForDay(int planDayId) {
    return _expenses
        .where((expense) => expense.planDayId == planDayId)
        .toList();
  }

  List<Expense> get uncategorizedExpenses {
    return _expenses.where((expense) => expense.planDayId == null).toList();
  }

  double totalAmountForDay(int planDayId) {
    return expensesForDay(
      planDayId,
    ).fold(0.0, (sum, expense) => sum + expense.amount);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _sortExpenses() {
    _expenses.sort((a, b) {
      final spentAtCompare = a.spentAt.compareTo(b.spentAt);
      if (spentAtCompare != 0) return spentAtCompare;
      final createdAtCompare = a.createdAt.compareTo(b.createdAt);
      if (createdAtCompare != 0) return createdAtCompare;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
  }
}
