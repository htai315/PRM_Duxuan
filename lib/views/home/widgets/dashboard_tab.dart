import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/utils/date_ui.dart';
import 'package:du_xuan/core/enums/plan_status.dart';
import 'package:du_xuan/core/enums/plan_timeline_state.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/viewmodels/home/home_viewmodel.dart';
import 'package:du_xuan/viewmodels/notification/notification_viewmodel.dart';
import 'package:du_xuan/viewmodels/plan/plan_list_viewmodel.dart';
import 'package:du_xuan/views/home/widgets/profile_bottom_sheet.dart';

class DashboardTab extends StatelessWidget {
  final HomeViewModel viewModel;
  final PlanListViewModel planListVM;
  final NotificationViewModel notificationVM;
  final VoidCallback onCreatePlan;
  final Future<void> Function(int planId) onOpenPlanDetail;
  final VoidCallback onOpenPlans;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenNotifications;
  final VoidCallback onLogout;

  const DashboardTab({
    super.key,
    required this.viewModel,
    required this.planListVM,
    required this.notificationVM,
    required this.onCreatePlan,
    required this.onOpenPlanDetail,
    required this.onOpenPlans,
    required this.onOpenMap,
    required this.onOpenNotifications,
    required this.onLogout,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgWarm, AppColors.bgCream],
        ),
      ),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([planListVM, notificationVM]),
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(context),
                  const SizedBox(height: 18),
                  _sectionTitle('Hành trình gần nhất'),
                  const SizedBox(height: 10),
                  _buildUpcomingTrip(context),
                  const SizedBox(height: 22),
                  _sectionTitle('Tiện ích nhanh'),
                  const SizedBox(height: 10),
                  _buildQuickActions(),
                  const SizedBox(height: 6),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final userName = viewModel.userName.trim().isEmpty
        ? 'Bạn'
        : viewModel.userName.trim();
    final totalPlans = planListVM.plans.length;
    final activePlans = _countActivePlans();
    final upcomingPlans = _countUpcomingPlans();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDeep,
            AppColors.primary,
            AppColors.primarySoft,
          ],
          stops: [0, 0.62, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -28,
            right: -16,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -14,
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _getGreeting(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  _buildNotificationButton(),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          ProfileBottomSheet.show(context, viewModel, onLogout),
                      borderRadius: BorderRadius.circular(999),
                      child: Ink(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            userName[0].toUpperCase(),
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                userName,
                style: AppTextStyles.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sẵn sàng cho chuyến đi tiếp theo chưa?',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _heroStat(value: '$totalPlans', label: 'Kế hoạch'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _heroStat(
                      value: '$activePlans',
                      label: 'Đang diễn ra',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _heroStat(
                      value: '$upcomingPlans',
                      label: 'Sắp khởi hành',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  int _countActivePlans() {
    return planListVM.plans.where((plan) {
      return plan.status == PlanStatus.active &&
          plan.timelineState == PlanTimelineState.ongoing;
    }).length;
  }

  int _countUpcomingPlans() {
    return planListVM.plans.where((plan) {
      return plan.status == PlanStatus.active &&
          plan.timelineState == PlanTimelineState.upcoming;
    }).length;
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
    );
  }

  Widget _buildUpcomingTrip(BuildContext context) {
    final plans = planListVM.plans;

    Plan? upcomingPlan;
    for (final p in plans) {
      if (p.status != PlanStatus.active) continue;
      if (p.timelineState == PlanTimelineState.pastDue) continue;
      if (upcomingPlan == null ||
          p.startDate.isBefore(upcomingPlan.startDate)) {
        upcomingPlan = p;
      }
    }

    if (upcomingPlan == null) {
      return _buildEmptyUpcoming();
    }

    return _buildUpcomingCard(context, upcomingPlan);
  }

  Widget _buildEmptyUpcoming() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.26),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bạn chưa có chuyến đi sắp tới',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tạo kế hoạch mới để bắt đầu theo dõi lịch trình và chi phí.',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onCreatePlan,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'Tạo kế hoạch',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(BuildContext context, Plan plan) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );
    final end = DateTime(
      plan.endDate.year,
      plan.endDate.month,
      plan.endDate.day,
    );
    final isOngoing = !today.isBefore(start) && !today.isAfter(end);
    final daysLeft = start.difference(today).inDays;
    final totalDays = (end.difference(start).inDays + 1).clamp(1, 9999);
    final currentDay = (today.difference(start).inDays + 1)
        .clamp(1, totalDays)
        .toInt();
    final activityProgress = planListVM.activityProgressForPlan(plan.id);
    final double progress = planListVM.progressForPlan(plan);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onOpenPlanDetail(plan.id),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDeep],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      plan.timelineState.label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    isOngoing
                        ? 'Ngày $currentDay/$totalDays'
                        : 'Còn $daysLeft ngày',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                plan.name,
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  height: 1.24,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateUi.shortDateRange(plan.startDate, plan.endDate),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.luggage_rounded,
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateUi.dayCountLabel(plan.totalDays),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                activityProgress.totalActivities > 0
                    ? 'Hoạt động ${activityProgress.completedActivities}/${activityProgress.totalActivities}'
                    : 'Chưa có hoạt động nào',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 112,
                child: _quickActionCard(
                  icon: Icons.add_rounded,
                  title: 'Tạo kế hoạch',
                  subtitle: 'Tạo mới',
                  color: AppColors.primary,
                  onTap: onCreatePlan,
                  minHeight: 112,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 112,
                child: _quickActionCard(
                  icon: Icons.luggage_rounded,
                  title: 'Kế hoạch của tôi',
                  subtitle: 'Xem tất cả',
                  color: AppColors.primaryDeep,
                  onTap: onOpenPlans,
                  minHeight: 112,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _quickActionCard(
          icon: Icons.map_rounded,
          title: 'Bản đồ hành trình',
          subtitle: 'Xem nhanh điểm đến đã thêm',
          color: AppColors.goldDeep,
          onTap: onOpenMap,
          fullWidth: true,
          minHeight: 92,
        ),
      ],
    );
  }

  Widget _buildNotificationButton() {
    final unreadCount = notificationVM.unreadCount;
    final hasUnread = unreadCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenNotifications,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Center(
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              if (hasUnread)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 1.3),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
    double minHeight = 96,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Ink(
            width: fullWidth ? double.infinity : null,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.82),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Icon(icon, size: 19, color: color),
                    ),
                    const Spacer(),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
