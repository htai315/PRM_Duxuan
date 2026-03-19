import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/utils/app_feedback.dart';
import 'package:du_xuan/core/utils/notification_service.dart';
import 'package:du_xuan/di.dart';
import 'package:du_xuan/routes/app_routes.dart';
import 'package:du_xuan/routes/route_args.dart';
import 'package:du_xuan/viewmodels/home/home_viewmodel.dart';
import 'package:du_xuan/views/home/map_tab.dart';
import 'package:du_xuan/views/home/widgets/dashboard_tab.dart';
import 'package:du_xuan/views/plan/plan_list_page.dart';

class HomePage extends StatefulWidget {
  final HomeViewModel viewModel;
  const HomePage({super.key, required this.viewModel});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final _planListVM = buildPlanListVM();
  late final _notificationVM = buildNotificationVM();
  late final NotificationService _notificationService =
      buildNotificationService();
  late final _mapVM = buildMapVM();

  int? get _currentUserId => widget.viewModel.session?.user.id;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  /// Load session + plans — gọi từ initState và khi cần refresh
  Future<void> _loadAllData() async {
    await widget.viewModel.loadSession();
    await _refreshHomeData(refreshNotifications: true, syncReminders: true);
  }

  Future<void> _refreshHomeData({
    bool refreshNotifications = false,
    bool syncReminders = false,
    bool refreshMapIfVisible = false,
    bool forceMapReload = false,
  }) async {
    final userId = _currentUserId;
    if (userId == null || userId <= 0) return;

    await _planListVM.loadPlans(userId, refresh: true);
    if (syncReminders) {
      await _notificationService.syncPlanReminders(_planListVM.plans);
    }
    if (refreshNotifications) {
      await _notificationVM.loadUnreadCount(userId);
    }
    if (refreshMapIfVisible && widget.viewModel.currentTab == 2) {
      await _mapVM.loadMarkers(userId, force: forceMapReload);
    }
  }

  Future<void> _handlePlanMutation() async {
    _mapVM.invalidateCache();
    await _refreshHomeData(
      refreshNotifications: true,
      syncReminders: true,
      refreshMapIfVisible: true,
      forceMapReload: true,
    );
  }

  Future<void> _handlePlanDeletion() async {
    final userId = _currentUserId;
    if (userId == null || userId <= 0) return;

    _mapVM.invalidateCache();
    await _notificationVM.loadUnreadCount(userId);
    if (widget.viewModel.currentTab == 2) {
      await _mapVM.loadMarkers(userId, force: true);
    }
  }

  Future<void> _openPlanDetail(int planId) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.itinerary,
      arguments: ItineraryRouteArgs(planId: planId),
    );
    if (!mounted) return;

    // Plan detail hiện chưa trả về dirty flag chính xác cho mọi nhánh mutate.
    await _handlePlanMutation();
  }

  void _onTabChanged(int index) {
    if (widget.viewModel.currentTab == index) return;
    widget.viewModel.switchTab(index);

    if (index == 2) {
      final userId = _currentUserId;
      if (userId != null && userId > 0) {
        _mapVM.loadMarkers(userId);
      }
    }
  }

  @override
  void dispose() {
    _planListVM.dispose();
    _notificationVM.dispose();
    _mapVM.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        final currentTabIndex = widget.viewModel.currentTab;
        return Scaffold(
          body: IndexedStack(
            index: currentTabIndex,
            children: [
              DashboardTab(
                viewModel: widget.viewModel,
                planListVM: _planListVM,
                notificationVM: _notificationVM,
                onCreatePlan: _navigateToCreatePlan,
                onOpenPlanDetail: _openPlanDetail,
                onOpenPlans: () => _onTabChanged(1),
                onOpenMap: () => _onTabChanged(2),
                onOpenNotifications: _navigateToNotifications,
                onLogout: _handleLogout,
              ),
              PlanListPage(
                viewModel: _planListVM,
                userId: _currentUserId ?? 0,
                onCreatePlan: _navigateToCreatePlan,
                onOpenPlanDetail: _openPlanDetail,
                onPlanDeleted: _handlePlanDeletion,
              ),
              MapTab(
                viewModel: _mapVM,
                userId: _currentUserId ?? 0,
                onOpenPlanDetail: _openPlanDetail,
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
    final isActive = widget.viewModel.currentTab == index;
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
    final confirm = await AppFeedback.showConfirmDialog(
      context: context,
      title: 'Đăng xuất',
      message: 'Bạn muốn đăng xuất?',
      confirmText: 'Đăng xuất',
    );

    if (confirm == true && mounted) {
      await widget.viewModel.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  Future<void> _navigateToCreatePlan() async {
    final userId = _currentUserId;
    if (userId == null) return;
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.planCreate,
      arguments: PlanCreateRouteArgs(userId: userId),
    );
    if (!mounted) return;

    if (result is int && result > 0) {
      await _openPlanDetail(result);
      return;
    }

    if (result == true) {
      await _handlePlanMutation();
      if (!mounted) return;
      AppFeedback.showSuccessSnack(context, 'Tạo kế hoạch thành công');
    }
  }

  Future<void> _navigateToNotifications() async {
    final userId = _currentUserId;
    if (userId == null) return;

    await Navigator.pushNamed(
      context,
      AppRoutes.notifications,
      arguments: NotificationsRouteArgs(userId: userId),
    );

    if (!mounted) return;
    await _refreshHomeData(
      refreshNotifications: true,
      syncReminders: true,
      refreshMapIfVisible: true,
      forceMapReload: true,
    );
  }
}
