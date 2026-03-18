import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/utils/activity_cost_ui.dart';
import 'package:du_xuan/core/utils/app_feedback.dart';
import 'package:du_xuan/core/utils/date_ui.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/routes/app_routes.dart';
import 'package:du_xuan/routes/route_args.dart';
import 'package:du_xuan/viewmodels/expense/expense_viewmodel.dart';
import 'package:du_xuan/viewmodels/itinerary/itinerary_viewmodel.dart';
import 'package:du_xuan/views/expense/widgets/expense_editor_bottom_sheet.dart';
import 'package:du_xuan/views/itinerary/activity_detail_page.dart';
import 'package:du_xuan/views/itinerary/location_action_sheet.dart';
import 'package:du_xuan/views/plan_detail/widgets/day_detail_activity_node.dart';
import 'package:du_xuan/views/plan_detail/widgets/day_detail_action_sheet.dart';
import 'package:du_xuan/views/plan_detail/widgets/day_detail_bottom_bar.dart';
import 'package:du_xuan/views/plan_detail/widgets/day_detail_empty_state.dart';
import 'package:du_xuan/views/plan_detail/widgets/day_detail_fab.dart';
import 'package:du_xuan/views/plan_detail/widgets/day_detail_header.dart';

/// Trang chi tiết 1 ngày — Premium UI với Fixed Bottom Bar (Blur) và Neumorphism Cards.
class DayDetailPage extends StatefulWidget {
  final ItineraryViewModel viewModel;
  final ExpenseViewModel expenseViewModel;
  final int dayIndex;
  final int planId;

  const DayDetailPage({
    super.key,
    required this.viewModel,
    required this.expenseViewModel,
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
            listenable: Listenable.merge([
              widget.viewModel,
              widget.expenseViewModel,
            ]),
            builder: (context, _) {
              final day = widget.viewModel.selectedDay;
              if (day == null) {
                return const Center(child: Text('Không tìm thấy ngày'));
              }

              final isViewMode = widget.viewModel.isViewMode;
              final canAddActivity = !isViewMode;
              final canAddExpense = widget.viewModel.canManageExpenses;
              final activities = widget.viewModel.activities;
              final expenses = widget.expenseViewModel.expensesForDay(day.id);
              final costSummary = ActivityCostUi.buildDaySummary(
                activities: activities,
                expenses: expenses,
              );
              final hasBottomBar = costSummary.hasAnyCost;

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
                        _buildActivityList(
                          activities,
                          isViewMode: isViewMode,
                          canAddActivity: canAddActivity,
                          canAddExpense: canAddExpense,
                        ),
                        if (canAddActivity || canAddExpense)
                          Positioned(
                            bottom: hasBottomBar
                                ? MediaQuery.of(context).padding.bottom + 92
                                : 24,
                            right: 16,
                            child: DayDetailFab(
                              onTap: () => _handlePrimaryActionTap(
                                canAddActivity: canAddActivity,
                                canAddExpense: canAddExpense,
                              ),
                              isExpenseOnly: !canAddActivity && canAddExpense,
                            ),
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
        listenable: Listenable.merge([
          widget.viewModel,
          widget.expenseViewModel,
        ]),
        builder: (context, _) {
          final day = widget.viewModel.selectedDay;
          if (day == null) return const SizedBox.shrink();
          final activities = widget.viewModel.activities;
          final expenses = widget.expenseViewModel.expensesForDay(day.id);
          final costSummary = ActivityCostUi.buildDaySummary(
            activities: activities,
            expenses: expenses,
          );
          if (!costSummary.hasAnyCost) return const SizedBox.shrink();
          return DayDetailBottomBar(
            title: costSummary.bottomBarTitle,
            totalCostLabel: costSummary.bottomBarTotalLabel,
            supportingText: costSummary.bottomBarSupportingText,
          );
        },
      ),
    );
  }

  // ─── ListView ─────────────────────────────────────────

  Widget _buildActivityList(
    List<Activity> activities, {
    required bool isViewMode,
    required bool canAddActivity,
    required bool canAddExpense,
  }) {
    if (activities.isEmpty) {
      return DayDetailEmptyState(
        canAddActivity: canAddActivity,
        canAddExpense: canAddExpense,
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
      costLabel: ActivityCostUi.activityCostBadgeLabel(activity),
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

  Future<void> _handlePrimaryActionTap({
    required bool canAddActivity,
    required bool canAddExpense,
  }) async {
    if (canAddActivity && !canAddExpense) {
      await _navigateToAddActivity();
      return;
    }

    if (!canAddActivity && canAddExpense) {
      await _openQuickAddExpense();
      return;
    }

    await DayDetailActionSheet.show(
      context,
      onAddActivity: canAddActivity ? _navigateToAddActivity : null,
      onAddExpense: canAddExpense ? _openQuickAddExpense : null,
    );
  }

  Future<void> _openQuickAddExpense() async {
    final day = widget.viewModel.selectedDay;
    final plan = widget.viewModel.plan;
    if (day == null || plan == null) return;

    final result = await ExpenseEditorBottomSheet.show(
      context,
      title: 'Thêm khoản chi',
      days: widget.viewModel.days,
      activitiesForDay: widget.viewModel.activitiesForDay,
      initialPlanDayId: day.id,
    );

    if (result == null) return;

    final created = await widget.expenseViewModel.addExpense(
      planId: plan.id,
      planDayId: result.planDayId,
      activityId: result.activityId,
      title: result.title,
      amountText: result.amountText,
      category: result.category,
      note: result.note,
      spentAt: _resolveExpenseDate(result.planDayId, fallback: day.date),
    );

    if (!mounted) return;

    if (created != null) {
      AppFeedback.showSuccessSnack(
        context,
        'Đã thêm khoản chi cho ngày này',
        duration: const Duration(seconds: 3),
      );
    } else {
      AppFeedback.showErrorSnack(
        context,
        widget.expenseViewModel.errorMessage ?? 'Không thể thêm khoản chi',
      );
    }
  }

  DateTime _resolveExpenseDate(int? planDayId, {required DateTime fallback}) {
    if (planDayId != null) {
      for (final day in widget.viewModel.days) {
        if (day.id == planDayId) return day.date;
      }
    }
    return fallback;
  }

  Future<void> _navigateToDetail(Activity activity) async {
    final result = await Navigator.push<Object?>(
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
