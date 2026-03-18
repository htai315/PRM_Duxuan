import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/utils/activity_cost_ui.dart';
import 'package:du_xuan/core/utils/app_feedback.dart';
import 'package:du_xuan/core/utils/app_form_validators.dart';
import 'package:du_xuan/core/utils/date_ui.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/domain/entities/expense.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';
import 'package:du_xuan/viewmodels/expense/expense_viewmodel.dart';
import 'package:du_xuan/viewmodels/itinerary/itinerary_viewmodel.dart';
import 'package:du_xuan/views/expense/widgets/expense_editor_bottom_sheet.dart';
import 'package:du_xuan/views/shared/widgets/app_action_chip.dart';
import 'package:du_xuan/views/shared/widgets/app_badge_chip.dart';
import 'package:du_xuan/views/shared/widgets/app_empty_state.dart';
import 'package:du_xuan/views/shared/widgets/app_loading_state.dart';
import 'package:flutter/material.dart';

class ExpensePage extends StatefulWidget {
  final ExpenseViewModel expenseViewModel;
  final ItineraryViewModel itineraryViewModel;
  final bool embeddedMode;

  const ExpensePage({
    super.key,
    required this.expenseViewModel,
    required this.itineraryViewModel,
    this.embeddedMode = false,
  });

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  bool get _canEditExpenses => widget.itineraryViewModel.canManageExpenses;

  double get _estimatedTotal {
    var total = 0.0;
    for (final day in widget.itineraryViewModel.days) {
      total += widget.itineraryViewModel
          .activitiesForDay(day.id)
          .fold(0.0, (sum, activity) => sum + (activity.estimatedCost ?? 0));
    }
    return total;
  }

  List<Activity> _activitiesForDay(int planDayId) {
    return widget.itineraryViewModel.activitiesForDay(planDayId);
  }

  DateTime _resolveSpentAt(int? planDayId, {DateTime? fallback}) {
    if (planDayId != null) {
      for (final day in widget.itineraryViewModel.days) {
        if (day.id == planDayId) return day.date;
      }
    }
    return fallback ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.expenseViewModel,
        widget.itineraryViewModel,
      ]),
      builder: (context, _) {
        if (widget.expenseViewModel.isLoading &&
            widget.expenseViewModel.expenses.isEmpty) {
          return AppLoadingState(
            title: 'Đang tải chi tiêu',
            subtitle: 'Theo dõi các khoản chi thực tế của chuyến đi.',
            icon: Icons.receipt_long_rounded,
            accentColor: AppColors.goldDeep,
            compact: widget.embeddedMode,
          );
        }

        final days = widget.itineraryViewModel.days;
        final estimatedTotal = _estimatedTotal;
        final actualTotal = widget.expenseViewModel.totalAmount;
        final variance = actualTotal - estimatedTotal;

        if (days.isEmpty && widget.expenseViewModel.expenses.isEmpty) {
          return const AppEmptyState(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Chưa có dữ liệu chi tiêu',
            subtitle: 'Thêm lịch trình hoặc khoản chi để bắt đầu theo dõi.',
            accentColor: AppColors.goldDeep,
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            _buildSummaryCard(
              estimatedTotal: estimatedTotal,
              actualTotal: actualTotal,
              variance: variance,
            ),
            const SizedBox(height: 16),
            ...days.map((day) => _buildDaySection(day)),
            if (widget.expenseViewModel.uncategorizedExpenses.isNotEmpty ||
                _canEditExpenses)
              _buildUnassignedSection(),
          ],
        );
      },
    );
  }

  Future<void> _openCreateExpense({int? preselectedPlanDayId}) async {
    if (!_canEditExpenses) {
      if (mounted) {
        AppFeedback.showInfoSnack(
          context,
          'Kế hoạch lưu trữ chỉ có thể xem lại chi tiêu.',
        );
      }
      return;
    }

    final result = await ExpenseEditorBottomSheet.show(
      context,
      title: 'Thêm khoản chi',
      days: widget.itineraryViewModel.days,
      activitiesForDay: _activitiesForDay,
      initialPlanDayId: preselectedPlanDayId,
    );

    if (result == null) return;

    final created = await widget.expenseViewModel.addExpense(
      planId: widget.itineraryViewModel.plan!.id,
      planDayId: result.planDayId,
      activityId: result.activityId,
      title: result.title,
      amountText: result.amountText,
      category: result.category,
      note: result.note,
      spentAt: _resolveSpentAt(result.planDayId),
    );

    if (!mounted) return;
    if (created != null) {
      AppFeedback.showSuccessSnack(context, 'Đã thêm khoản chi');
    } else {
      AppFeedback.showErrorSnack(
        context,
        widget.expenseViewModel.errorMessage ?? 'Không thể thêm khoản chi',
      );
    }
  }

  Future<void> _openEditExpense(Expense expense) async {
    if (!_canEditExpenses) {
      if (mounted) {
        AppFeedback.showInfoSnack(
          context,
          'Kế hoạch lưu trữ chỉ có thể xem lại chi tiêu.',
        );
      }
      return;
    }

    final result = await ExpenseEditorBottomSheet.show(
      context,
      title: 'Sửa khoản chi',
      days: widget.itineraryViewModel.days,
      activitiesForDay: _activitiesForDay,
      initialExpense: expense,
    );

    if (result == null) return;

    final parsedAmount = AppFormValidators.parseEstimatedCost(
      result.amountText,
    );
    if (!parsedAmount.isValid || parsedAmount.value == null) {
      if (!mounted) return;
      AppFeedback.showErrorSnack(
        context,
        parsedAmount.errorMessage ?? 'Số tiền không hợp lệ',
      );
      return;
    }

    final success = await widget.expenseViewModel.updateExpense(
      expense.copyWith(
        planDayId: result.planDayId,
        activityId: result.activityId,
        title: result.title,
        amount: parsedAmount.value!,
        category: result.category,
        note: result.note,
        spentAt: _resolveSpentAt(result.planDayId, fallback: expense.spentAt),
        updatedAt: DateTime.now(),
      ),
    );

    if (!mounted) return;
    if (success) {
      AppFeedback.showSuccessSnack(context, 'Đã cập nhật khoản chi');
    } else {
      AppFeedback.showErrorSnack(
        context,
        widget.expenseViewModel.errorMessage ?? 'Không thể cập nhật khoản chi',
      );
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    if (!_canEditExpenses) {
      if (mounted) {
        AppFeedback.showInfoSnack(
          context,
          'Kế hoạch lưu trữ chỉ có thể xem lại chi tiêu.',
        );
      }
      return;
    }

    final confirmed = await AppFeedback.showConfirmDialog(
      context: context,
      title: 'Xóa khoản chi',
      message: 'Khoản chi "${expense.title}" sẽ bị xóa khỏi phần chi tiêu.',
      confirmText: 'Xóa',
      destructive: true,
    );

    if (!confirmed) return;

    final success = await widget.expenseViewModel.deleteExpense(expense.id);
    if (!mounted) return;
    if (success) {
      AppFeedback.showSuccessSnack(context, 'Đã xóa khoản chi');
    } else {
      AppFeedback.showErrorSnack(
        context,
        widget.expenseViewModel.errorMessage ?? 'Không thể xóa khoản chi',
      );
    }
  }

  Widget _buildSummaryCard({
    required double estimatedTotal,
    required double actualTotal,
    required double variance,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Tổng quan chi tiêu',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_canEditExpenses)
                AppActionChip(
                  label: 'Thêm khoản chi',
                  icon: Icons.add_rounded,
                  onTap: _openCreateExpense,
                  textColor: Colors.white,
                  gradient: const LinearGradient(
                    colors: [AppColors.gold, AppColors.goldDeep],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Dự kiến',
                  value: ActivityCostUi.formatCurrency(estimatedTotal),
                  accentColor: AppColors.goldDeep,
                  icon: Icons.event_note_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  label: 'Thực tế',
                  value: ActivityCostUi.formatCurrency(actualTotal),
                  accentColor: AppColors.success,
                  icon: Icons.savings_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  label: 'Chênh lệch',
                  value: ActivityCostUi.varianceLabel(variance),
                  accentColor: variance >= 0
                      ? AppColors.error
                      : AppColors.success,
                  icon: variance >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                ),
              ),
            ],
          ),
          if (!_canEditExpenses) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.bgCream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_clock_rounded,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kế hoạch đã lưu trữ nên tab này chỉ còn ở chế độ xem.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDaySection(PlanDay day) {
    final activities = widget.itineraryViewModel.activitiesForDay(day.id);
    final expenses = widget.expenseViewModel.expensesForDay(day.id);
    final costSummary = ActivityCostUi.buildDaySummary(
      activities: activities,
      expenses: expenses,
    );
    final variance = costSummary.actualTotal - costSummary.estimatedTotal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${day.dayNumber}',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.goldDeep,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngày ${day.dayNumber}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateUi.weekdayFullDate(day.date),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppBadgeChip(
                    label: costSummary.dayChipLabel,
                    icon: Icons.account_balance_wallet_rounded,
                    textColor: costSummary.hasActualEntries
                        ? AppColors.success
                        : AppColors.goldDeep,
                    backgroundColor:
                        (costSummary.hasActualEntries
                                ? AppColors.success
                                : AppColors.gold)
                            .withValues(alpha: 0.12),
                  ),
                  if (_canEditExpenses) ...[
                    const SizedBox(height: 8),
                    AppActionChip(
                      label: 'Thêm',
                      icon: Icons.add_rounded,
                      onTap: () =>
                          _openCreateExpense(preselectedPlanDayId: day.id),
                      textColor: AppColors.goldDeep,
                      backgroundColor: AppColors.gold.withValues(alpha: 0.12),
                      borderColor: AppColors.gold.withValues(alpha: 0.25),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      borderRadius: 10,
                      fontSize: 10.5,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InlineLabel(
                label: 'Dự kiến',
                value: ActivityCostUi.formatCurrency(
                  costSummary.estimatedTotal,
                ),
              ),
              const SizedBox(width: 12),
              _InlineLabel(
                label: 'Chênh lệch',
                value: costSummary.hasActualEntries
                    ? ActivityCostUi.varianceLabel(variance)
                    : 'Chưa có',
                accentColor: costSummary.hasActualEntries
                    ? (variance >= 0 ? AppColors.error : AppColors.success)
                    : AppColors.textLight,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (expenses.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgCream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.7),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _canEditExpenses
                          ? 'Chưa có khoản chi nào được ghi cho ngày này.'
                          : 'Chưa ghi nhận khoản chi thực tế cho ngày này.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...expenses.map(_buildExpenseItem),
        ],
      ),
    );
  }

  Widget _buildUnassignedSection() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Khoản chi chưa gắn ngày',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_canEditExpenses)
                AppActionChip(
                  label: 'Thêm',
                  icon: Icons.add_rounded,
                  onTap: _openCreateExpense,
                  textColor: AppColors.goldDeep,
                  backgroundColor: AppColors.gold.withValues(alpha: 0.12),
                  borderColor: AppColors.gold.withValues(alpha: 0.25),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  borderRadius: 10,
                  fontSize: 10.5,
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.expenseViewModel.uncategorizedExpenses.isEmpty)
            Text(
              'Chưa có khoản chi tự do nào ngoài lịch trình.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...widget.expenseViewModel.uncategorizedExpenses.map(
              _buildExpenseItem,
            ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(Expense expense) {
    final category = expense.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.bgCream.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _canEditExpenses ? () => _openEditExpense(expense) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(category.icon, size: 16, color: category.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          AppBadgeChip(
                            label: category.label,
                            textColor: category.color,
                            backgroundColor: category.color.withValues(
                              alpha: 0.12,
                            ),
                            fontSize: 10,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ],
                      ),
                      if (expense.note != null &&
                          expense.note!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          expense.note!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ActivityCostUi.formatCurrency(expense.amount),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.goldDeep,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateUi.shortDate(expense.spentAt),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                        if (_canEditExpenses) ...[
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.more_horiz_rounded,
                              size: 18,
                              color: AppColors.textLight,
                            ),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _openEditExpense(expense);
                              } else if (value == 'delete') {
                                _deleteExpense(expense);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Text('Sửa khoản chi'),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Xóa khoản chi'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final IconData icon;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color? accentColor;

  const _InlineLabel({
    required this.label,
    required this.value,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.textMedium;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
