import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/enums/plan_status.dart';
import 'package:du_xuan/di.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/viewmodels/home/home_viewmodel.dart';
import 'package:du_xuan/viewmodels/plan/plan_list_viewmodel.dart';
import 'package:du_xuan/views/plan/plan_list_page.dart';
import 'package:du_xuan/views/home/map_tab.dart';

class HomePage extends StatefulWidget {
  final HomeViewModel viewModel;
  const HomePage({super.key, required this.viewModel});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final _planListVM = buildPlanListVM();
  late final _mapVM = buildMapVM();
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  /// Load session + plans — gọi từ initState và khi cần refresh
  Future<void> _loadAllData() async {
    await widget.viewModel.loadSession();
    final userId = widget.viewModel.session?.user.id;
    if (userId != null) {
      await _planListVM.loadPlans(userId, refresh: true);
    }
    // Ép rebuild toàn bộ UI sau khi data load xong
    if (mounted) setState(() {});
  }

  void _onTabChanged(int index) {
    setState(() => _currentTabIndex = index);
    widget.viewModel.switchTab(index);

    // Refresh plans khi chọn tab Dashboard hoặc Kế hoạch
    if (index == 0 || index == 1) {
      final userId = widget.viewModel.session?.user.id;
      if (userId != null && userId > 0) {
        _planListVM.loadPlans(userId, refresh: true);
      }
    }
    // Refresh map khi chọn tab Bản đồ
    if (index == 2) {
      final userId = widget.viewModel.session?.user.id;
      if (userId != null && userId > 0) {
        _mapVM.loadMarkers(userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        return Scaffold(
          body: IndexedStack(
            index: _currentTabIndex,
            children: [
              _DashboardTab(
                viewModel: widget.viewModel,
                planListVM: _planListVM,
                onCreatePlan: _navigateToCreatePlan,
                onOpenPlans: () => _onTabChanged(1),
                onOpenMap: () => _onTabChanged(2),
                onLogout: _handleLogout,
              ),
              PlanListPage(
                viewModel: _planListVM,
                userId: widget.viewModel.session?.user.id ?? 0,
                onCreatePlan: _navigateToCreatePlan,
              ),
              MapTab(
                viewModel: _mapVM,
                userId: widget.viewModel.session?.user.id ?? 0,
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.65),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _navItem(0, Icons.home_rounded, 'Khám phá')),
              Expanded(child: _navItem(1, Icons.luggage_rounded, 'Chuyến đi')),
              Expanded(child: _navItem(2, Icons.map_rounded, 'Bản đồ')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _currentTabIndex == index;
    final activeColor = isActive ? AppColors.primary : AppColors.textLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTabChanged(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isActive ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Icon(icon, size: 22, color: activeColor),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: activeColor,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Đăng xuất', style: AppTextStyles.titleMedium),
        content: Text('Bạn muốn đăng xuất?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Hủy',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Đăng xuất',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await widget.viewModel.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _navigateToCreatePlan() async {
    final userId = widget.viewModel.session?.user.id;
    if (userId == null) return;
    final result = await Navigator.pushNamed(
      context,
      '/plan/create',
      arguments: userId,
    );
    if (result == true && mounted) {
      await _planListVM.loadPlans(userId, refresh: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tạo kế hoạch thành công'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// ═════════════════════════════════════════════════════════
// TAB 1: DASHBOARD
// ═════════════════════════════════════════════════════════

class _DashboardTab extends StatelessWidget {
  final HomeViewModel viewModel;
  final PlanListViewModel planListVM;
  final VoidCallback onCreatePlan;
  final VoidCallback onOpenPlans;
  final VoidCallback onOpenMap;
  final VoidCallback onLogout;

  const _DashboardTab({
    required this.viewModel,
    required this.planListVM,
    required this.onCreatePlan,
    required this.onOpenPlans,
    required this.onOpenMap,
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
          listenable: planListVM,
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
          colors: [AppColors.primaryDeep, AppColors.primary, AppColors.primarySoft],
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
                    child: _heroStat(
                      value: '$totalPlans',
                      label: 'Kế hoạch',
                    ),
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

  Widget _heroStat({
    required String value,
    required String label,
  }) {
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return planListVM.plans.where((plan) {
      if (plan.status == PlanStatus.completed) return false;
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
      return !today.isBefore(start) && !today.isAfter(end);
    }).length;
  }

  int _countUpcomingPlans() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return planListVM.plans.where((plan) {
      if (plan.status == PlanStatus.completed) return false;
      final start = DateTime(
        plan.startDate.year,
        plan.startDate.month,
        plan.startDate.day,
      );
      return today.isBefore(start);
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Plan? upcomingPlan;
    for (final p in plans) {
      if (p.status == PlanStatus.completed) continue;
      final end = DateTime(p.endDate.year, p.endDate.month, p.endDate.day);
      if (end.isBefore(today)) continue;
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
    final bool isOngoing = !today.isBefore(start) && !today.isAfter(end);
    final int daysLeft = start.difference(today).inDays;
    final int totalDays = (end.difference(start).inDays + 1).clamp(1, 9999);
    final int currentDay = (today.difference(start).inDays + 1)
        .clamp(1, totalDays)
        .toInt();
    final double progress = isOngoing ? currentDay / totalDays : 0;
    final dateFmt = DateFormat('dd/MM');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            Navigator.pushNamed(context, '/itinerary', arguments: plan.id),
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
                      isOngoing ? 'Đang diễn ra' : 'Sắp diễn ra',
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
                    '${dateFmt.format(plan.startDate)} - ${dateFmt.format(plan.endDate)}',
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
                    '${plan.totalDays} ngày',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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

// ═════════════════════════════════════════════════════════
// TAB 3: TÀI KHOẢN
// ═════════════════════════════════════════════════════════

// ═════════════════════════════════════════════════════════
// PROFILE BOTTOM SHEET
// ═════════════════════════════════════════════════════════

class ProfileBottomSheet extends StatelessWidget {
  final HomeViewModel viewModel;
  final VoidCallback onLogout;

  const ProfileBottomSheet({
    super.key,
    required this.viewModel,
    required this.onLogout,
  });

  static Future<void> show(
    BuildContext context,
    HomeViewModel viewModel,
    VoidCallback onLogout,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          ProfileBottomSheet(viewModel: viewModel, onLogout: onLogout),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = viewModel.session?.user;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDeep],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user != null ? user.fullName[0].toUpperCase() : '?',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? '...',
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '@${user?.userName ?? '...'}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryDeep,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Menu Items
          _menuItem(
            icon: Icons.lock_outline_rounded,
            title: 'Đổi mật khẩu',
            onTap: () {
              Navigator.pop(context); // Close sheet
              final userId = viewModel.session?.user.id;
              if (userId != null) {
                Navigator.pushNamed(
                  context,
                  '/change-password',
                  arguments: userId,
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _menuItem(
            icon: Icons.logout_rounded,
            title: 'Đăng xuất',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context); // Close sheet
              onLogout();
            },
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.error.withValues(alpha: 0.05)
              : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDestructive
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isDestructive ? AppColors.error : AppColors.textMedium,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isDestructive ? AppColors.error : AppColors.textDark,
                ),
              ),
            ),
            if (!isDestructive)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textLight,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
