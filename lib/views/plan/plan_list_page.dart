import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/enums/plan_status.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/viewmodels/plan/plan_list_viewmodel.dart';

class PlanListPage extends StatefulWidget {
  final PlanListViewModel viewModel;
  final int userId;
  final VoidCallback onCreatePlan;

  const PlanListPage({
    super.key,
    required this.viewModel,
    required this.userId,
    required this.onCreatePlan,
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
      if (_selectedFilter != _allFilter &&
          plan.displayStatus != _selectedFilter) {
        return false;
      }

      if (query.isEmpty) return true;

      final name = plan.name.toLowerCase();
      final dateText = '${_fmtDate(plan.startDate)} ${_fmtDate(plan.endDate)}';
      return name.contains(query) || dateText.contains(query);
    }).toList();
  }

  bool get _canPaginate {
    return _searchCtrl.text.trim().isEmpty && _selectedFilter == _allFilter;
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
                return const Center(child: CircularProgressIndicator());
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
          child: _buildHeaderPanel(visiblePlans.length),
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
                        return _planCard(context, visiblePlans[index]);
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHeaderPanel(int visibleCount) {
    final total = widget.viewModel.plans.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.86)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kế hoạch của tôi',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 23,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Hiển thị $visibleCount/$total kế hoạch',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$total',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSearchBar(),
          const SizedBox(height: 10),
          _buildFilterBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCream.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.92),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: 'Tìm theo tên kế hoạch...',
          hintStyle: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textLight,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 17,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textLight,
                    size: 18,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = _filters[index];
          final isActive = label == _selectedFilter;
          final icon = _filterIcon(label);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = label;
                });
              },
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isActive
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDeep],
                        )
                      : null,
                  color: isActive
                      ? null
                      : AppColors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : AppColors.divider,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 13,
                      color: isActive ? Colors.white : AppColors.textMedium,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color:
                            isActive ? Colors.white : AppColors.textMedium,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
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

  Widget _planCard(BuildContext context, Plan plan) {
    final dateRange = '${_fmtDate(plan.startDate)} - ${_fmtDate(plan.endDate)}';
    final statusColor = _statusColor(plan.displayStatus);
    final progress = _planProgress(plan);
    final progressPercent = (progress * 100).round();
    final statusIcon = _statusIcon(plan.displayStatus);

    return Dismissible(
      key: ValueKey(plan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      confirmDismiss: (_) => _confirmDelete(context, plan),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              Navigator.pushNamed(context, '/itinerary', arguments: plan.id),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.84),
                ),
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
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withValues(alpha: 0.9),
                          statusColor.withValues(alpha: 0.35),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(statusIcon, size: 18, color: statusColor),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan.name,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _statusHint(plan.displayStatus),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textLight,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildStatusBadge(plan.displayStatus, statusColor),
                                const SizedBox(height: 6),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textLight,
                                  size: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildMetaItem(
                              Icons.calendar_today_rounded,
                              dateRange,
                            ),
                            _buildMetaItem(
                              Icons.timelapse_rounded,
                              '${plan.totalDays} ngày',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _progressCaption(plan.displayStatus, progress),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMedium,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '$progressPercent%',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: AppColors.divider.withValues(
                              alpha: 0.7,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              statusColor,
                            ),
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
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgWarm.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textLight),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMedium,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        status,
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Đang diễn ra':
        return Icons.play_circle_fill_rounded;
      case 'Sắp diễn ra':
        return Icons.schedule_rounded;
      case 'Hoàn thành':
        return Icons.check_circle_rounded;
      case 'Đã qua ngày':
        return Icons.history_toggle_off_rounded;
      default:
        return Icons.luggage_rounded;
    }
  }

  String _statusHint(String status) {
    switch (status) {
      case 'Đang diễn ra':
        return 'Lịch trình đang hoạt động';
      case 'Sắp diễn ra':
        return 'Chuẩn bị khởi hành';
      case 'Hoàn thành':
        return 'Hành trình đã kết thúc';
      case 'Đã qua ngày':
        return 'Bạn có thể cập nhật lại ngày đi';
      default:
        return 'Kế hoạch chuyến đi';
    }
  }

  String _progressCaption(String status, double progress) {
    if (status == 'Hoàn thành') return 'Tiến độ đã hoàn tất';
    if (status == 'Sắp diễn ra') return 'Chuyến đi chưa bắt đầu';
    if (status == 'Đã qua ngày') return 'Chuyến đi đã qua mốc dự kiến';
    return 'Đã hoàn thành ${(progress * 100).round()}% lịch trình';
  }

  double _planProgress(Plan plan) {
    if (plan.status == PlanStatus.completed) return 1;

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

    if (today.isBefore(start)) return 0;
    if (today.isAfter(end)) return 1;

    final totalDays = end.difference(start).inDays + 1;
    if (totalDays <= 0) return 0;

    final currentDay = today.difference(start).inDays + 1;
    return (currentDay / totalDays).clamp(0.0, 1.0);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Hoàn thành':
        return AppColors.success;
      case 'Đang diễn ra':
        return AppColors.primary;
      case 'Sắp diễn ra':
        return AppColors.goldDeep;
      case 'Đã qua ngày':
        return AppColors.textLight;
      default:
        return AppColors.textMedium;
    }
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

  void _showErrorSnack(String message) {
    if (!mounted) return;
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

  Future<bool> _confirmDelete(BuildContext context, Plan plan) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xóa kế hoạch?', style: AppTextStyles.titleMedium),
        content: Text(
          'Bạn muốn xóa "${plan.name}"?\nTất cả dữ liệu sẽ bị mất.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (result == true) {
      final deleted = await widget.viewModel.deletePlan(plan.id);
      if (deleted) {
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

  String _fmtDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
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

