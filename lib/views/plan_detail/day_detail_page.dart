import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/utils/app_feedback.dart';
import 'package:du_xuan/core/utils/date_ui.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/routes/app_routes.dart';
import 'package:du_xuan/routes/route_args.dart';
import 'package:du_xuan/viewmodels/itinerary/itinerary_viewmodel.dart';
import 'package:du_xuan/views/itinerary/activity_detail_page.dart';
import 'package:du_xuan/views/itinerary/location_action_sheet.dart';
import 'package:du_xuan/views/plan_detail/widgets/day_detail_activity_node.dart';
import 'package:du_xuan/views/plan_detail/widgets/day_detail_bottom_bar.dart';
import 'package:du_xuan/views/plan_detail/widgets/day_detail_empty_state.dart';
import 'package:du_xuan/views/plan_detail/widgets/day_detail_fab.dart';
import 'package:du_xuan/views/plan_detail/widgets/day_detail_header.dart';
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
                  DayDetailHeader(
                    dayNumber: day.dayNumber,
                    dateLabel: DateUi.weekdayFullDate(day.date),
                    activityCount: activities.length,
                    onBack: () => Navigator.pop(context),
                  ),
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
                            child: DayDetailFab(onTap: _navigateToAddActivity),
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
        builder: (context, _) {
          final activities = widget.viewModel.activities;
          if (activities.isEmpty) return const SizedBox.shrink();
          return DayDetailBottomBar(
            totalCostLabel: _formatCost(widget.viewModel.totalCostOfDay),
          );
        },
      ),
    );
  }

  // ─── ListView ─────────────────────────────────────────

  Widget _buildActivityList(List<Activity> activities, bool isViewMode) {
    if (activities.isEmpty) {
      return DayDetailEmptyState(isViewMode: isViewMode);
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
    final typeColor = activity.activityType.color;
    final hasLocation =
        activity.locationText != null && activity.locationText!.isNotEmpty;

    return DayDetailActivityNode(
      activity: activity,
      isDone: isDone,
      isViewMode: isViewMode,
      isLast: isLast,
      typeColor: typeColor,
      hasLocation: hasLocation,
      costLabel: activity.estimatedCost != null
          ? _formatCost(activity.estimatedCost!)
          : '0₫',
      onOpenDetail: () => _navigateToDetail(activity),
      onToggleStatus: () => widget.viewModel.toggleActivityStatus(activity.id),
      onDelete: () => _undoableDelete(activity),
      onOpenLocation: () {
        if (!hasLocation) return;
        LocationActionSheet.show(
          context: context,
          locationText: activity.locationText!,
          activityTitle: activity.title,
        );
      },
    );
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
      AppRoutes.activityCreate,
      arguments: ActivityCreateRouteArgs(planDayId: day.id),
    );
    if (result == true) {
      widget.viewModel.refreshActivities();
      if (!mounted) return;
      AppFeedback.showSuccessSnack(
        context,
        'Thêm hoạt động thành công!',
        duration: const Duration(seconds: 3),
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
        AppRoutes.activityEdit,
        arguments: ActivityEditRouteArgs(activity: activity),
      );
      if (editResult == true) {
        widget.viewModel.refreshActivities();
        if (!mounted) return;
        AppFeedback.showSuccessSnack(
          context,
          'Cập nhật thành công!',
          duration: const Duration(seconds: 3),
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
