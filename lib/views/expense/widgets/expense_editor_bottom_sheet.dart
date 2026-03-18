import 'package:du_xuan/core/enums/expense_category.dart';
import 'package:du_xuan/core/utils/app_currency_input_formatter.dart';
import 'package:du_xuan/core/utils/app_form_validators.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/domain/entities/expense.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';
import 'package:du_xuan/views/expense/widgets/expense_form_sheet.dart';
import 'package:flutter/material.dart';

class ExpenseEditorResult {
  final String title;
  final String amountText;
  final ExpenseCategory category;
  final String? note;
  final int? planDayId;
  final int? activityId;

  const ExpenseEditorResult({
    required this.title,
    required this.amountText,
    required this.category,
    required this.note,
    required this.planDayId,
    required this.activityId,
  });
}

class ExpenseEditorBottomSheet extends StatefulWidget {
  final String title;
  final Expense? initialExpense;
  final int? initialPlanDayId;
  final List<PlanDay> days;
  final List<Activity> Function(int planDayId) activitiesForDay;

  const ExpenseEditorBottomSheet({
    super.key,
    required this.title,
    required this.days,
    required this.activitiesForDay,
    this.initialExpense,
    this.initialPlanDayId,
  });

  static Future<ExpenseEditorResult?> show(
    BuildContext context, {
    required String title,
    required List<PlanDay> days,
    required List<Activity> Function(int planDayId) activitiesForDay,
    Expense? initialExpense,
    int? initialPlanDayId,
  }) {
    return showModalBottomSheet<ExpenseEditorResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseEditorBottomSheet(
        title: title,
        days: days,
        activitiesForDay: activitiesForDay,
        initialExpense: initialExpense,
        initialPlanDayId: initialPlanDayId,
      ),
    );
  }

  @override
  State<ExpenseEditorBottomSheet> createState() =>
      _ExpenseEditorBottomSheetState();
}

class _ExpenseEditorBottomSheetState extends State<ExpenseEditorBottomSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late ExpenseCategory _category;
  int? _selectedPlanDayId;
  int? _selectedActivityId;
  String? _nameError;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialExpense;
    _nameCtrl = TextEditingController(text: initial?.title ?? '');
    _amountCtrl = TextEditingController(
      text: AppCurrencyInputFormatter.formatStoredAmount(initial?.amount),
    );
    _noteCtrl = TextEditingController(text: initial?.note ?? '');
    _category = initial?.category ?? ExpenseCategory.other;
    _selectedPlanDayId = initial?.planDayId ?? widget.initialPlanDayId;
    _selectedActivityId = initial?.activityId;
    _normalizeSelectedActivity();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  List<Activity> get _availableActivities {
    if (_selectedPlanDayId == null) return const [];
    return widget.activitiesForDay(_selectedPlanDayId!);
  }

  @override
  Widget build(BuildContext context) {
    return ExpenseFormSheet(
      title: widget.title,
      nameCtrl: _nameCtrl,
      amountCtrl: _amountCtrl,
      noteCtrl: _noteCtrl,
      nameError: _nameError,
      amountError: _amountError,
      category: _category,
      selectedPlanDayId: _selectedPlanDayId,
      selectedActivityId: _selectedActivityId,
      days: widget.days,
      availableActivities: _availableActivities,
      onCategoryChanged: (value) => setState(() => _category = value),
      onPlanDayChanged: (value) {
        setState(() {
          _selectedPlanDayId = value;
          _normalizeSelectedActivity();
        });
      },
      onActivityChanged: (value) => setState(() => _selectedActivityId = value),
      onSave: _save,
      saveLabel: widget.initialExpense == null
          ? 'Lưu khoản chi'
          : 'Cập nhật khoản chi',
    );
  }

  void _normalizeSelectedActivity() {
    final activityStillExists = _availableActivities.any(
      (activity) => activity.id == _selectedActivityId,
    );
    if (!activityStillExists) {
      _selectedActivityId = null;
    }
  }

  void _save() {
    final trimmedName = _nameCtrl.text.trim();
    final parsedAmount = AppFormValidators.parseEstimatedCost(_amountCtrl.text);

    setState(() {
      _nameError = trimmedName.isEmpty ? 'Vui lòng nhập tên khoản chi' : null;
      if (!parsedAmount.isValid || parsedAmount.value == null) {
        _amountError = parsedAmount.errorMessage ?? 'Số tiền không hợp lệ';
      } else if (parsedAmount.value! <= 0) {
        _amountError = 'Số tiền phải lớn hơn 0';
      } else {
        _amountError = null;
      }
    });

    if (_nameError != null || _amountError != null) return;

    Navigator.pop(
      context,
      ExpenseEditorResult(
        title: trimmedName,
        amountText: _amountCtrl.text.trim(),
        category: _category,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        planDayId: _selectedPlanDayId,
        activityId: _selectedActivityId,
      ),
    );
  }
}
