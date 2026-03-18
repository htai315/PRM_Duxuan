import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/enums/activity_status.dart';
import 'package:du_xuan/core/utils/activity_cost_ui.dart';
import 'package:du_xuan/core/utils/app_feedback.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';
import 'package:du_xuan/viewmodels/expense/expense_viewmodel.dart';
import 'package:du_xuan/viewmodels/itinerary/itinerary_viewmodel.dart';
import 'package:du_xuan/views/plan_detail/day_detail_page.dart';
import 'package:du_xuan/views/shared/widgets/app_action_chip.dart';
import 'package:du_xuan/views/shared/widgets/app_empty_state.dart';
import 'package:intl/intl.dart';

/// Tab 1: Danh sách ngày — mỗi ngày là 1 card, bấm drill-down.
class DayListTab extends StatelessWidget {
  final ItineraryViewModel viewModel;
  final ExpenseViewModel expenseViewModel;
  final int planId;
  final Future<void> Function()? onDayDetailClosed;

  const DayListTab({
    super.key,
    required this.viewModel,
    required this.expenseViewModel,
    required this.planId,
    this.onDayDetailClosed,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, expenseViewModel]),
      builder: (context, _) {
        final days = viewModel.days;
        if (days.isEmpty) {
          return const AppEmptyState(
            icon: Icons.calendar_month_rounded,
            title: 'Chưa có ngày nào',
            subtitle: 'Sửa kế hoạch để thêm ngày.',
            accentColor: AppColors.primary,
            iconBoxSize: 60,
          );
        }

        // Overdue / View mode banners
        final isViewMode = viewModel.isViewMode;
        final isOverdue = viewModel.isOverdue;
        final canMarkPlanCompleted = viewModel.canMarkPlanCompleted;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          children: [
            // Status banners
            if (isViewMode) _buildCompletedBanner(context),
            if (!isViewMode && canMarkPlanCompleted)
              _buildReadyToCompleteBanner(context),
            if (!isViewMode && isOverdue) _buildOverdueBanner(),
            if (isViewMode || canMarkPlanCompleted || isOverdue)
              const SizedBox(height: 12),

            // Day cards
            ...days.map((day) => _dayCard(context, day)),
          ],
        );
      },
    );
  }

  // ─── Gradient mỗi ngày khác nhau ───────────────────────
  static const _dayGradients = [
    [Color(0xFFD4403A), Color(0xFFA82828)], // đỏ tết
    [Color(0xFFE8A838), Color(0xFFC08520)], // vàng mai
    [Color(0xFFE06888), Color(0xFFC54E70)], // hồng đào
    [Color(0xFFD96B4B), Color(0xFFBF4C35)], // cam đất
    [Color(0xFFBE5A31), Color(0xFF8E2F1D)], // nâu đỏ
    [Color(0xFFC99A32), Color(0xFFA06D17)], // vàng đậm
  ];

  Widget _dayCard(BuildContext context, PlanDay day) {
    final dateStr = DateFormat('EEEE, dd/MM', 'vi').format(day.date);
    final activities = viewModel.activitiesForDay(day.id);
    final expenses = expenseViewModel.expensesForDay(day.id);
    final activityCount = activities.length;
    final doneCount = activities
        .where((a) => a.status == ActivityStatus.done)
        .length;
    final costSummary = ActivityCostUi.buildDaySummary(
      activities: activities,
      expenses: expenses,
    );
    final progress = activityCount > 0 ? doneCount / activityCount : 0.0;
    final isAllDone = activityCount > 0 && doneCount == activityCount;

    // Hôm nay?
    final now = DateTime.now();
    final isToday =
        day.date.year == now.year &&
        day.date.month == now.month &&
        day.date.day == now.day;

    // Gradient xoay vòng theo dayNumber
    final grad = _dayGradients[(day.dayNumber - 1) % _dayGradients.length];

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DayDetailPage(
              viewModel: viewModel,
              expenseViewModel: expenseViewModel,
              dayIndex: day.dayNumber - 1,
              planId: planId,
            ),
          ),
        );
        await viewModel.loadPlan(planId);
        await onDayDetailClosed?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: grad[0].withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
          border: isToday
              ? Border.all(color: grad[0].withValues(alpha: 0.40), width: 1.8)
              : null,
        ),
        child: Column(
          children: [
            // ── Header row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  // Day number badge (gradient đa sắc)
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: grad,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: grad[0].withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${day.dayNumber}',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title + date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Ngày ${day.dayNumber}',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: grad[0].withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Hôm nay',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: grad[0],
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                            if (isAllDone) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: AppColors.success,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dateStr,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: grad[0].withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: grad[0],
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // ── Summary chips ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 2),
              child: Row(
                children: [
                  // Activities count
                  _summaryChip(
                    icon: Icons.event_note_rounded,
                    text: activityCount > 0
                        ? '$activityCount hoạt động'
                        : 'Chưa có hoạt động',
                    color: activityCount > 0
                        ? AppColors.textMedium
                        : AppColors.textLight,
                  ),
                  if (costSummary.hasAnyCost) ...[
                    const SizedBox(width: 12),
                    _summaryChip(
                      icon: Icons.payments_rounded,
                      text: costSummary.dayChipLabel,
                      color: AppColors.goldDeep,
                    ),
                  ],
                  const Spacer(),
                  if (activityCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (isAllDone ? AppColors.success : grad[0])
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: (isAllDone ? AppColors.success : grad[0])
                              .withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        '$doneCount/$activityCount',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isAllDone ? AppColors.success : grad[0],
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Progress bar ──
            if (activityCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: grad[0].withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isAllDone ? AppColors.success : grad[0],
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ─── Banners ─────────────────────────────────────────
  Widget _buildCompletedBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.08),
            AppColors.success.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chuyến đi đã hoàn tất!',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ),
          AppActionChip(
            label: 'Mở lại sửa',
            onTap: () => _confirmReopen(context),
            textColor: AppColors.textMedium,
            backgroundColor: AppColors.white.withValues(alpha: 0.72),
            borderColor: AppColors.textLight.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            borderRadius: 8,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  Widget _buildReadyToCompleteBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.1),
            AppColors.success.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.task_alt_rounded,
            size: 20,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tất cả hoạt động hiện có đã hoàn thành',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ),
          AppActionChip(
            label: 'Hoàn thành plan',
            onTap: () => _handleMarkCompleted(context),
            textColor: AppColors.success,
            backgroundColor: AppColors.success.withValues(alpha: 0.12),
            borderColor: AppColors.success.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            borderRadius: 8,
            fontSize: 11,
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.1),
            AppColors.gold.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 18,
            color: AppColors.goldDeep,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kế hoạch đã quá ngày kết thúc. Bạn có thể tiếp tục chỉnh sửa, '
              'nhưng không thể đánh dấu hoàn thành theo rule hiện tại.',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.goldDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMarkCompleted(BuildContext context) async {
    final success = await viewModel.markPlanCompleted();
    if (!context.mounted) return;
    if (success) {
      _showSuccessSnack(context, 'Đã đánh dấu kế hoạch hoàn thành');
    } else {
      _showErrorSnack(
        context,
        viewModel.errorMessage ?? 'Cập nhật trạng thái thất bại',
      );
    }
  }

  void _showSuccessSnack(BuildContext context, String message) {
    AppFeedback.showSuccessSnack(context, message);
  }

  void _showErrorSnack(BuildContext context, String message) {
    AppFeedback.showErrorSnack(context, message);
  }

  Future<void> _confirmReopen(BuildContext context) async {
    final confirmed = await AppFeedback.showConfirmDialog(
      context: context,
      title: 'Mở lại chỉnh sửa?',
      message: 'Kế hoạch sẽ chuyển về chế độ chỉnh sửa.',
      confirmText: 'Mở lại',
    );
    if (confirmed == true) {
      final success = await viewModel.reopenForEditing();
      if (!context.mounted) return;
      if (success) {
        _showSuccessSnack(context, 'Kế hoạch đã mở lại để chỉnh sửa');
      } else {
        _showErrorSnack(
          context,
          viewModel.errorMessage ?? 'Không thể mở lại kế hoạch',
        );
      }
    }
  }
}
