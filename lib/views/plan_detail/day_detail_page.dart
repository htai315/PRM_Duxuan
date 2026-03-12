import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/enums/activity_type.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';
import 'package:du_xuan/viewmodels/itinerary/itinerary_viewmodel.dart';
import 'package:du_xuan/views/itinerary/activity_detail_page.dart';
import 'package:du_xuan/views/itinerary/location_action_sheet.dart';
import 'package:intl/intl.dart';

/// Trang chi tiết 1 ngày — Premium UI với Fixed Bottom Bar (Blur) và Neumorphism Cards.
class DayDetailPage extends StatefulWidget {
  final ItineraryViewModel viewModel;
  final int dayIndex;
  final int planId;

  const DayDetailPage({
    super.key,
    required this.viewModel,
    required this.dayIndex,
    required this.planId,
  });

  @override
  State<DayDetailPage> createState() => _DayDetailPageState();
}

class _DayDetailPageState extends State<DayDetailPage> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.selectDay(widget.dayIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Cho phép body scroll dướí bottom navigation bar
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgWarm, AppColors.bgCream],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, _) {
              final day = widget.viewModel.selectedDay;
              if (day == null) {
                return const Center(child: Text('Không tìm thấy ngày'));
              }

              final isViewMode = widget.viewModel.isViewMode;
              final activities = widget.viewModel.activities;

              return Column(
                children: [
                  _buildAppBar(day),
                  Expanded(
                    child: Stack(
                      children: [
                        _buildActivityList(activities, isViewMode),
                        if (!isViewMode)
                          Positioned(
                            bottom: activities.isNotEmpty
                                ? MediaQuery.of(context).padding.bottom + 92
                                : 24,
                            right: 16,
                            child: _buildFab(),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) => _buildBottomBar(),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────

  Widget _buildAppBar(PlanDay day) {
    final dateStr = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(day.date);
    final activityCount = widget.viewModel.activities.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: AppColors.textDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.93),
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NGÀY ${day.dayNumber}',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.primary,
                            letterSpacing: 1.1,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: AppTextStyles.titleLarge.copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$activityCount hoạt động',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ListView ─────────────────────────────────────────

  Widget _buildActivityList(List<Activity> activities, bool isViewMode) {
    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.luggage_rounded,
                  size: 50, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Một ngày trống rỗng...',
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                isViewMode
                    ? 'Ngày này không có lịch trình nào. Hãy tận hưởng kỳ nghỉ ngơi!'
                    : '"Một cuộc hành trình ngàn dặm bắt đầu từ một bước chân nhỏ" - Bấm + để lên kế hoạch nào!',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMedium,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      // Chừa không gian cho bottom bar + FAB để không che nội dung.
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 196),
      itemCount: activities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final isLast = index == activities.length - 1;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 180 + (index * 70)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 14 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _activityTimelineNode(
            activities[index],
            isViewMode,
            isLast: isLast,
          ),
        );
      },
    );
  }

  // ─── Timeline Node ────────────────────────────────────

  Widget _activityTimelineNode(
    Activity activity,
    bool isViewMode, {
    required bool isLast,
  }) {
    final isDone = activity.status.name == 'done';
    final typeColor = _getTypeColor(activity.activityType);
    final hasLocation =
        activity.locationText != null && activity.locationText!.isNotEmpty;

    return Dismissible(
      key: ValueKey(activity.id),
      direction:
          isViewMode ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error, size: 28),
      ),
      onDismissed: (_) => _undoableDelete(activity),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.whiteSoft.withValues(alpha: 0.9)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.divider.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        activity.startTime ?? '--:--',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDone ? AppColors.textMedium : AppColors.textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      if (activity.endTime != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          activity.endTime!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.textLight.withValues(alpha: 0.5)
                        : typeColor,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDone
                                ? AppColors.textLight.withValues(alpha: 0.5)
                                : typeColor)
                            .withValues(alpha: 0.32),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 1.5,
                    height: 94,
                    decoration: BoxDecoration(
                      color: AppColors.divider.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: isDone ? 0.74 : 1,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _navigateToDetail(activity),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.whiteSoft.withValues(alpha: 0.92)
                          : AppColors.white.withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.divider.withValues(alpha: 0.78),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity.title,
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: isDone
                                            ? AppColors.textMedium
                                            : AppColors.textDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17,
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (hasLocation) ...[
                                      const SizedBox(height: 7),
                                      GestureDetector(
                                        onTap: () {
                                          LocationActionSheet.show(
                                            context: context,
                                            locationText: activity.locationText!,
                                            activityTitle: activity.title,
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.whiteSoft.withValues(
                                              alpha: 0.95,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(11),
                                            border: Border.all(
                                              color: AppColors.divider
                                                  .withValues(alpha: 0.8),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.place_rounded,
                                                size: 14,
                                                color: isDone
                                                    ? AppColors.textMedium
                                                    : typeColor,
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  activity.locationText!,
                                                  style: AppTextStyles.bodySmall.copyWith(
                                                    color: AppColors.textMedium,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 9),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _buildBadge(
                                          icon: activity.activityType.icon,
                                          label: activity.activityType.label,
                                          color: isDone
                                              ? AppColors.textMedium
                                              : typeColor,
                                        ),
                                        if (activity.estimatedCost != null &&
                                            activity.estimatedCost! > 0)
                                          _buildBadge(
                                            icon: Icons
                                                .account_balance_wallet_rounded,
                                            label: _formatCost(
                                              activity.estimatedCost!,
                                            ),
                                            color: isDone
                                                ? AppColors.textMedium
                                                : AppColors.goldDeep,
                                            bgColor: isDone
                                                ? AppColors.bgCream
                                                : AppColors.gold.withValues(
                                                    alpha: 0.15,
                                                  ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _buildStatusButton(
                                  isDone: isDone,
                                  isViewMode: isViewMode,
                                  onTap: () => widget.viewModel
                                      .toggleActivityStatus(activity.id),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required bool isDone,
    required bool isViewMode,
    required VoidCallback onTap,
  }) {
    final text = isDone ? 'Hoàn thành' : 'Chưa xong';
    final bgColor = isDone
        ? AppColors.success.withValues(alpha: 0.14)
        : AppColors.white;
    final textColor = isDone ? AppColors.success : AppColors.textMedium;
    final borderColor = isDone
        ? AppColors.success.withValues(alpha: 0.32)
        : AppColors.divider.withValues(alpha: 0.9);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: isDone
                ? AppColors.success.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextButton(
        onPressed: isViewMode ? null : onTap,
        style: TextButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          foregroundColor: textColor,
          disabledForegroundColor: textColor,
          backgroundColor: bgColor,
          disabledBackgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: borderColor, width: 1.15),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: Row(
            key: ValueKey(text),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDone ? Icons.check_circle_rounded : Icons.timelapse_rounded,
                size: 14,
                color: textColor,
              ),
              const SizedBox(width: 5),
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: AppTextStyles.bodySmall.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    Color? bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor ?? color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Persistent Bottom Bar (Glassmorphism) ────────────

  Widget _buildBottomBar() {
    final activities = widget.viewModel.activities;
    if (activities.isEmpty) return const SizedBox.shrink();

    final total = widget.viewModel.totalCostOfDay;
    
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.84),
            border: Border(
              top: BorderSide(
                color: AppColors.divider.withValues(alpha: 0.62),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    size: 20, color: AppColors.goldDeep),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng chi phí ngày',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatCost(total),
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.goldDeep,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── FAB ──────────────────────────────────────────────

  Widget _buildFab() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _navigateToAddActivity,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDeep],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  // ─── Controller Helpers ───────────────────────────────

  Color _getTypeColor(ActivityType activityType) {
    switch (activityType.name) {
      case 'travel':
        return AppColors.primary;
      case 'dining':
        return AppColors.gold;
      case 'sightseeing':
        return AppColors.blossom;
      case 'shopping':
        return AppColors.goldDeep;
      case 'worship':
        return AppColors.primaryDeep;
      case 'rest':
        return AppColors.blossomDeep;
      default:
        return AppColors.textMedium;
    }
  }

  String _formatCost(double cost) {
    if (cost <= 0) return '0₫';
    final formatted = NumberFormat('#,###', 'vi').format(cost.toInt());
    return '$formatted₫';
  }

  Future<void> _navigateToAddActivity() async {
    final day = widget.viewModel.selectedDay;
    if (day == null) return;
    final result = await Navigator.pushNamed(
      context,
      '/activity/create',
      arguments: day.id,
    );
    if (result == true) {
      widget.viewModel.refreshActivities();
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Thêm hoạt động thành công!', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _navigateToDetail(Activity activity) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailPage(
          activity: activity,
          isViewMode: widget.viewModel.isViewMode,
        ),
      ),
    );
    if (!mounted) return;
    
    if (result == 'edited') {
      final editResult = await Navigator.pushNamed(
        context,
        '/activity/edit',
        arguments: activity,
      );
      if (editResult == true) {
        widget.viewModel.refreshActivities();
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Cập nhật thành công!', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else if (result == 'deleted') {
      _undoableDelete(activity);
    }
  }

  void _undoableDelete(Activity activity) {
    final removedIndex = widget.viewModel.removeLocally(activity.id);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa "${activity.title}"'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Hoàn tác',
          textColor: AppColors.gold,
          onPressed: () {
            widget.viewModel.restoreLocally(activity, removedIndex);
          },
        ),
      ),
    );

    // Xóa DB sau 4s nếu không undo
    Future.delayed(const Duration(seconds: 4), () {
      if (!widget.viewModel.activities.any((a) => a.id == activity.id)) {
        widget.viewModel.deleteActivity(activity.id);
      }
    });
  }
}

