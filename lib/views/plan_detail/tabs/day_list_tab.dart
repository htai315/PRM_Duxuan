import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/enums/activity_status.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';
import 'package:du_xuan/viewmodels/itinerary/itinerary_viewmodel.dart';
import 'package:du_xuan/views/plan_detail/day_detail_page.dart';
import 'package:intl/intl.dart';

/// Tab 1: Danh sách ngày — mỗi ngày là 1 card, bấm drill-down.
class DayListTab extends StatelessWidget {
  final ItineraryViewModel viewModel;
  final int planId;

  const DayListTab({super.key, required this.viewModel, required this.planId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final days = viewModel.days;
        if (days.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    size: 30,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Chưa có ngày nào', style: AppTextStyles.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Sửa kế hoạch để thêm ngày',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          );
        }

        // Overdue / View mode banners
        final isViewMode = viewModel.isViewMode;
        final isOverdue = viewModel.isOverdue;
        final canMarkPlanCompleted = viewModel.canMarkPlanCompleted;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
    final activityCount = activities.length;
    final doneCount = activities
        .where((a) => a.status == ActivityStatus.done)
        .length;
    final totalCost = activities.fold<double>(
      0,
      (s, a) => s + (a.estimatedCost ?? 0),
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
              dayIndex: day.dayNumber - 1,
              planId: planId,
            ),
          ),
        );
        viewModel.loadPlan(planId);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  // Day number badge (gradient đa sắc)
                  Container(
                    width: 50,
                    height: 50,
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
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

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
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
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
                  if (totalCost > 0) ...[
                    const SizedBox(width: 12),
                    _summaryChip(
                      icon: Icons.payments_rounded,
                      text: _formatCost(totalCost),
                      color: AppColors.goldDeep,
                    ),
                  ],
                  const Spacer(),
                  if (activityCount > 0)
                    Text(
                      '$doneCount/$activityCount',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isAllDone
                            ? AppColors.success
                            : AppColors.textLight,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),

            // ── Progress bar ──
            if (activityCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isAllDone ? AppColors.success : grad[0],
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 8),
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

  String _formatCost(double cost) {
    if (cost >= 1000000) {
      return '${(cost / 1000000).toStringAsFixed(1)}tr';
    } else if (cost >= 1000) {
      return '${(cost / 1000).toStringAsFixed(0)}k';
    }
    return '₫${cost.toStringAsFixed(0)}';
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
          GestureDetector(
            onTap: () => _confirmReopen(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.textLight.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Mở lại sửa',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                ),
              ),
            ),
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
              'Tất cả hoạt động đã hoàn thành',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _handleMarkCompleted(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Hoàn thành plan',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmReopen(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Mở lại chỉnh sửa?', style: AppTextStyles.titleMedium),
        content: Text(
          'Kế hoạch sẽ chuyển về chế độ chỉnh sửa.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: TextStyle(color: AppColors.textLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Mở lại', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
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
