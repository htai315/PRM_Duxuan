import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/utils/plan_share_builder.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/viewmodels/itinerary/itinerary_viewmodel.dart';
import 'package:du_xuan/viewmodels/checklist/checklist_viewmodel.dart';
import 'package:du_xuan/views/plan_detail/tabs/day_list_tab.dart';
import 'package:du_xuan/views/plan_detail/tabs/checklist_tab.dart';
import 'package:du_xuan/views/plan_detail/tabs/locations_tab.dart';
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
  int _locationsRefreshToken = 0;
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChanged);
    _checklistVM = buildChecklistVM();
    widget.viewModel.loadPlan(widget.planId);
    _checklistVM.loadItems(widget.planId);
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;
    final index = _tabController.index;
    if (index == _lastTabIndex) return;
    _lastTabIndex = index;

    if (index == 2 && mounted) {
      setState(() {
        _locationsRefreshToken++;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload: load lại dữ liệu để tránh state cũ.
    widget.viewModel.loadPlan(widget.planId);
    _checklistVM.loadItems(widget.planId);
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
                return const Center(child: CircularProgressIndicator());
              }
              if (widget.viewModel.plan == null) {
                return const Center(child: Text('Không tìm thấy kế hoạch'));
              }

              final plan = widget.viewModel.plan!;

              return Column(
                children: [
                  _buildAppBar(plan),
                  const SizedBox(height: 8),
                  _buildTabBar(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        DayListTab(
                          viewModel: widget.viewModel,
                          planId: widget.planId,
                        ),
                        ChecklistTab(
                          checklistVM: _checklistVM,
                          planId: widget.planId,
                          planName: plan.name,
                          readOnly: widget.viewModel.isViewMode,
                        ),
                        LocationsTab(
                          planId: widget.planId,
                          planName: plan.name,
                          refreshToken: _locationsRefreshToken,
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
    );
  }

  Widget _buildAppBar(Plan plan) {
    final status = plan.displayStatus;
    final statusColor = _statusColor(status);
    final dateFmt = DateFormat('dd/MM', 'vi');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _roundIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context, true),
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
                    fontSize: 20,
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
                      text:
                          '${dateFmt.format(plan.startDate)} - ${dateFmt.format(plan.endDate)}',
                    ),
                    _miniInfoChip(
                      icon: Icons.timelapse_rounded,
                      text: '${plan.totalDays} ngày',
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
            child: _roundIconSurface(icon: Icons.more_horiz_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMedium,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
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
          fontSize: 12,
        ),
        unselectedLabelStyle: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.calendar_month_rounded, size: 17),
            text: 'Lịch trình',
            height: 48,
          ),
          Tab(
            icon: Icon(Icons.checklist_rounded, size: 17),
            text: 'Checklist',
            height: 48,
          ),
          Tab(
            icon: Icon(Icons.place_rounded, size: 17),
            text: 'Điểm đến',
            height: 48,
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: _roundIconSurface(icon: icon),
      ),
    );
  }

  Widget _roundIconSurface({required IconData icon}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.88),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
      ),
      child: Icon(icon, size: 18, color: AppColors.textDark),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _miniInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textMedium),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMedium,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Sắp diễn ra':
        return AppColors.primary;
      case 'Đang diễn ra':
        return AppColors.success;
      case 'Đã qua ngày':
        return AppColors.goldDeep;
      case 'Hoàn thành':
        return AppColors.success;
      default:
        return AppColors.textLight;
    }
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'edit':
        final result = await Navigator.pushNamed(
          context,
          '/plan/edit',
          arguments: widget.planId,
        );
        if (!mounted) return;
        if (result == true) {
          widget.viewModel.loadPlan(widget.planId);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Cập nhật kế hoạch thành công',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
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
