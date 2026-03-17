import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/enums/plan_status.dart';
import 'package:du_xuan/core/enums/plan_timeline_state.dart';
import 'package:du_xuan/core/utils/app_feedback.dart';
import 'package:du_xuan/core/utils/date_ui.dart';
import 'package:du_xuan/core/utils/plan_ui.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/routes/app_routes.dart';
import 'package:du_xuan/routes/route_args.dart';
import 'package:du_xuan/viewmodels/plan/plan_list_viewmodel.dart';
import 'package:du_xuan/views/plan/widgets/plan_list_card.dart';
import 'package:du_xuan/views/plan/widgets/plan_list_header_panel.dart';
import 'package:du_xuan/views/shared/widgets/app_loading_state.dart';

class PlanListPage extends StatefulWidget {
  final PlanListViewModel viewModel;
  final int userId;
  final VoidCallback onCreatePlan;
  final Future<void> Function(int planId)? onOpenPlanDetail;
  final Future<void> Function()? onPlanDeleted;

  const PlanListPage({
    super.key,
    required this.viewModel,
    required this.userId,
    required this.onCreatePlan,
    this.onOpenPlanDetail,
    this.onPlanDeleted,
  });

  @override
  State<PlanListPage> createState() => _PlanListPageState();
}

class _PlanListPageState extends State<PlanListPage> {
  static const String _allFilter = 'Tất cả';
  static const List<String> _filters = [
    _allFilter,
    'Đang diễn ra',
    'Sắp diễn ra',
    'Hoàn thành',
    'Đã qua ngày',
    'Nháp',
    'Lưu trữ',
  ];

  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = _allFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Plan> get _visiblePlans {
    final query = _searchCtrl.text.trim().toLowerCase();

    return widget.viewModel.plans.where((plan) {
      if (!_matchesFilter(plan)) {
        return false;
      }

      if (query.isEmpty) return true;

      final name = plan.name.toLowerCase();
      final dateText =
          '${DateUi.shortDate(plan.startDate)} ${DateUi.shortDate(plan.endDate)}';
      return name.contains(query) || dateText.contains(query);
    }).toList();
  }

  bool get _canPaginate {
    return _searchCtrl.text.trim().isEmpty && _selectedFilter == _allFilter;
  }

  bool _matchesFilter(Plan plan) {
    switch (_selectedFilter) {
      case _allFilter:
        return true;
      case 'Đang diễn ra':
        return plan.status == PlanStatus.active &&
            plan.timelineState == PlanTimelineState.ongoing;
      case 'Sắp diễn ra':
        return plan.status == PlanStatus.active &&
            plan.timelineState == PlanTimelineState.upcoming;
      case 'Đã qua ngày':
        return plan.status == PlanStatus.active &&
            plan.timelineState == PlanTimelineState.pastDue;
      case 'Hoàn thành':
        return plan.status == PlanStatus.completed;
      case 'Nháp':
        return plan.status == PlanStatus.draft;
      case 'Lưu trữ':
        return plan.status == PlanStatus.archived;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _buildFab(),
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
            builder: (context, child) {
              if (widget.viewModel.isLoading &&
                  widget.viewModel.plans.isEmpty) {
                return const AppLoadingState(
                  title: 'Đang tải kế hoạch',
                  subtitle:
                      'Hệ thống đang đồng bộ danh sách chuyến đi của bạn.',
                  icon: Icons.luggage_rounded,
                );
              }
              if (widget.viewModel.plans.isEmpty) {
                return _buildEmptyState();
              }
              return _buildList(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.map_rounded,
                size: 40,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 20),
            Text('Chưa có kế hoạch nào', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Tạo kế hoạch đầu tiên để bắt đầu hành trình của bạn.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _createButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final visiblePlans = _visiblePlans;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: PlanListHeaderPanel(
            visibleCount: visiblePlans.length,
            totalCount: widget.viewModel.plans.length,
            searchController: _searchCtrl,
            filters: _filters,
            selectedFilter: _selectedFilter,
            onSearchChanged: (_) => setState(() {}),
            onClearSearch: () {
              _searchCtrl.clear();
              setState(() {});
            },
            onFilterSelected: (label) {
              setState(() {
                _selectedFilter = label;
              });
            },
            filterIconBuilder: _filterIcon,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: visiblePlans.isEmpty
              ? _buildNoResult()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      widget.viewModel.loadPlans(widget.userId, refresh: true),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (_canPaginate &&
                          scrollInfo.metrics.pixels >=
                              scrollInfo.metrics.maxScrollExtent - 200) {
                        widget.viewModel.loadMore(widget.userId);
                      }
                      return false;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
                      itemCount:
                          visiblePlans.length +
                          ((_canPaginate && widget.viewModel.hasMore) ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == visiblePlans.length &&
                            _canPaginate &&
                            widget.viewModel.hasMore) {
                          return _buildLoadMoreIndicator();
                        }
                        return _planCard(visiblePlans[index]);
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  IconData _filterIcon(String label) {
    switch (label) {
      case _allFilter:
        return Icons.grid_view_rounded;
      case 'Đang diễn ra':
        return Icons.play_circle_fill_rounded;
      case 'Sắp diễn ra':
        return Icons.schedule_rounded;
      case 'Hoàn thành':
        return Icons.check_circle_rounded;
      case 'Đã qua ngày':
        return Icons.history_toggle_off_rounded;
      default:
        return Icons.filter_alt_rounded;
    }
  }

  Widget _buildNoResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppColors.primary,
                size: 29,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Không có kế hoạch phù hợp',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Hãy đổi bộ lọc hoặc từ khóa để thử lại.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                setState(() {
                  _selectedFilter = _allFilter;
                });
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Đặt lại bộ lọc'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: widget.viewModel.isLoadingMore
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: () => widget.viewModel.loadMore(widget.userId),
                child: const Text('Tải thêm...'),
              ),
      ),
    );
  }

  Widget _planCard(Plan plan) {
    final dateRange = DateUi.shortDateRange(plan.startDate, plan.endDate);
    final badgeLabel = plan.statusBadgeLabel;
    final statusColor = PlanUi.statusColor(plan);
    final activityProgress = widget.viewModel.activityProgressForPlan(plan.id);
    final progress = widget.viewModel.progressForPlan(plan);
    final progressPercent = (progress * 100).round();
    return PlanListCard(
      plan: plan,
      dateRange: dateRange,
      badgeLabel: badgeLabel,
      statusHint: PlanUi.statusHint(plan),
      progressCaption: PlanUi.progressCaption(plan, activityProgress),
      statusColor: statusColor,
      statusIcon: PlanUi.statusIcon(plan),
      progress: progress,
      progressPercent: progressPercent,
      onTap: () async {
        if (widget.onOpenPlanDetail != null) {
          await widget.onOpenPlanDetail!(plan.id);
          return;
        }
        await Navigator.pushNamed(
          context,
          AppRoutes.itinerary,
          arguments: ItineraryRouteArgs(planId: plan.id),
        );
      },
      onConfirmDismiss: (_) => _confirmDelete(context, plan),
    );
  }

  Widget _createButton() {
    return TextButton.icon(
      onPressed: widget.onCreatePlan,
      style: TextButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(
        'Tạo kế hoạch',
        style: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showSuccessSnack(String message) {
    if (!mounted) return;
    AppFeedback.showSuccessSnack(context, message);
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    AppFeedback.showErrorSnack(context, message);
  }

  Future<bool> _confirmDelete(BuildContext context, Plan plan) async {
    final result = await AppFeedback.showConfirmDialog(
      context: context,
      title: 'Xóa kế hoạch?',
      message: 'Bạn muốn xóa "${plan.name}"?\nTất cả dữ liệu sẽ bị mất.',
      confirmText: 'Xóa',
      destructive: true,
    );

    if (result == true) {
      final deleted = await widget.viewModel.deletePlan(plan.id);
      if (deleted) {
        await widget.onPlanDeleted?.call();
        _showSuccessSnack('Đã xóa kế hoạch "${plan.name}"');
      } else {
        _showErrorSnack(
          widget.viewModel.errorMessage ?? 'Xóa kế hoạch thất bại',
        );
      }
      return deleted;
    }
    return false;
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: widget.onCreatePlan,
      backgroundColor: Colors.transparent,
      elevation: 0,
      highlightElevation: 0,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDeep],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
