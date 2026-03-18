import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/utils/app_feedback.dart';
import 'package:du_xuan/core/utils/date_ui.dart';
import 'package:du_xuan/core/utils/plan_ui.dart';
import 'package:du_xuan/core/utils/plan_share_builder.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/routes/app_routes.dart';
import 'package:du_xuan/routes/route_args.dart';
import 'package:du_xuan/viewmodels/itinerary/itinerary_viewmodel.dart';
import 'package:du_xuan/viewmodels/checklist/checklist_viewmodel.dart';
import 'package:du_xuan/viewmodels/expense/expense_viewmodel.dart';
import 'package:du_xuan/views/plan_detail/tabs/day_list_tab.dart';
import 'package:du_xuan/views/plan_detail/tabs/checklist_tab.dart';
import 'package:du_xuan/views/plan_detail/tabs/expense_tab.dart';
import 'package:du_xuan/views/plan_detail/tabs/locations_tab.dart';
import 'package:du_xuan/views/shared/widgets/app_badge_chip.dart';
import 'package:du_xuan/views/shared/widgets/app_circle_icon.dart';
import 'package:du_xuan/views/shared/widgets/app_loading_state.dart';
import 'package:du_xuan/di.dart';

/// Trang chi tiết 1 kế hoạch.
/// TabBar 3 tabs: Lịch trình | Checklist | Điểm đến.
class PlanDetailPage extends StatefulWidget {
  final ItineraryViewModel viewModel;
  final int planId;

  const PlanDetailPage({
    super.key,
    required this.viewModel,
    required this.planId,
  });

  @override
  State<PlanDetailPage> createState() => _PlanDetailPageState();
}

class _PlanDetailPageState extends State<PlanDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ChecklistViewModel _checklistVM;
  late final ExpenseViewModel _expenseVM;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checklistVM = buildChecklistVM();
    _expenseVM = buildExpenseVM();
    widget.viewModel.loadPlan(widget.planId);
    _checklistVM.loadItems(widget.planId);
    _expenseVM.loadExpenses(widget.planId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload: load lại dữ liệu để tránh state cũ.
    widget.viewModel.loadPlan(widget.planId);
    _checklistVM.loadItems(widget.planId);
    _expenseVM.loadExpenses(widget.planId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgWarm, AppColors.bgCream],
          ),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, _) {
              if (widget.viewModel.isLoading && widget.viewModel.plan == null) {
                return const AppLoadingState(
                  title: 'Đang tải kế hoạch',
                  subtitle:
                      'Lịch trình, checklist và điểm đến đang được chuẩn bị.',
                  icon: Icons.calendar_month_rounded,
                );
              }
              if (widget.viewModel.plan == null) {
                return const Center(child: Text('Không tìm thấy kế hoạch'));
              }

              final plan = widget.viewModel.plan!;

              return Column(
                children: [
                  _buildAppBar(plan),
                  const SizedBox(height: 4),
                  _buildTabBar(),
                  const SizedBox(height: 6),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        DayListTab(
                          viewModel: widget.viewModel,
                          expenseViewModel: _expenseVM,
                          planId: widget.planId,
                          onDayDetailClosed: () =>
                              _expenseVM.loadExpenses(widget.planId),
                        ),
                        ChecklistTab(
                          checklistVM: _checklistVM,
                          planId: widget.planId,
                          planName: plan.name,
                          readOnly: widget.viewModel.isViewMode,
                        ),
                        ExpenseTab(
                          expenseVM: _expenseVM,
                          itineraryVM: widget.viewModel,
                        ),
                        LocationsTab(viewModel: widget.viewModel),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Plan plan) {
    final status = plan.statusBadgeLabel;
    final statusColor = PlanUi.statusColor(plan);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context, true),
            backgroundColor: AppColors.white.withValues(alpha: 0.88),
            borderColor: AppColors.divider.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.2,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildStatusChip(status, statusColor),
                    _miniInfoChip(
                      icon: Icons.calendar_today_rounded,
                      text: DateUi.shortDateRange(plan.startDate, plan.endDate),
                    ),
                    _miniInfoChip(
                      icon: Icons.timelapse_rounded,
                      text: DateUi.dayCountLabel(plan.totalDays),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Tùy chọn',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            color: AppColors.white,
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (_) => [
              if (!widget.viewModel.isViewMode)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: AppColors.textMedium,
                      ),
                      SizedBox(width: 10),
                      Text('Sửa kế hoạch'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(
                      Icons.share_rounded,
                      size: 18,
                      color: AppColors.textMedium,
                    ),
                    SizedBox(width: 10),
                    Text('Chia sẻ'),
                  ],
                ),
              ),
            ],
            child: AppCircleIconSurface(
              icon: Icons.more_horiz_rounded,
              backgroundColor: AppColors.white.withValues(alpha: 0.88),
              borderColor: AppColors.divider.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMedium,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDeep],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        dividerColor: Colors.transparent,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
        unselectedLabelStyle: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.calendar_month_rounded, size: 16),
            text: 'Lịch trình',
            height: 42,
          ),
          Tab(
            icon: Icon(Icons.checklist_rounded, size: 16),
            text: 'Checklist',
            height: 42,
          ),
          Tab(
            icon: Icon(Icons.receipt_long_rounded, size: 16),
            text: 'Chi tiêu',
            height: 42,
          ),
          Tab(
            icon: Icon(Icons.place_rounded, size: 16),
            text: 'Điểm đến',
            height: 42,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return AppBadgeChip(
      label: status,
      textColor: color,
      backgroundColor: color.withValues(alpha: 0.12),
    );
  }

  Widget _miniInfoChip({required IconData icon, required String text}) {
    return AppBadgeChip(
      label: text,
      icon: icon,
      textColor: AppColors.textMedium,
      backgroundColor: AppColors.white.withValues(alpha: 0.84),
      borderColor: AppColors.divider.withValues(alpha: 0.75),
      fontWeight: FontWeight.w600,
    );
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'edit':
        final result = await Navigator.pushNamed(
          context,
          AppRoutes.planEdit,
          arguments: PlanEditRouteArgs(planId: widget.planId),
        );
        if (!mounted) return;
        if (result == true) {
          widget.viewModel.loadPlan(widget.planId);
          _expenseVM.loadExpenses(widget.planId);
          AppFeedback.showSuccessSnack(
            context,
            'Cập nhật kế hoạch thành công',
            duration: const Duration(seconds: 3),
          );
        }
        break;
      case 'share':
        final text = await PlanShareBuilder.build(widget.planId);
        await Share.share(text, subject: 'Kế hoạch chuyến đi');
        break;
    }
  }
}
