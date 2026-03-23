import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'package:du_xuan/views/plan_detail/widgets/plan_copy_share_sheet.dart';
import 'package:du_xuan/viewmodels/share/plan_copy_source_viewmodel.dart';
import 'package:du_xuan/viewmodels/share/public_share_viewmodel.dart';
import 'package:du_xuan/views/shared/widgets/app_badge_chip.dart';
import 'package:du_xuan/views/shared/widgets/app_circle_icon.dart';
import 'package:du_xuan/views/shared/widgets/app_loading_state.dart';
import 'package:du_xuan/di.dart';

/// Trang chi tiết 1 kế hoạch.
/// TabBar 3 tabs: Lịch trình | Checklist | Điểm đến.
class PlanDetailPage extends StatefulWidget {
  final ItineraryViewModel viewModel;
  final int planId;
  final String? successMessage;
  final int initialTabIndex;

  const PlanDetailPage({
    super.key,
    required this.viewModel,
    required this.planId,
    this.successMessage,
    this.initialTabIndex = 0,
  });

  @override
  State<PlanDetailPage> createState() => _PlanDetailPageState();
}

class _PlanDetailPageState extends State<PlanDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ChecklistViewModel _checklistVM;
  late final ExpenseViewModel _expenseVM;
  late final PublicShareViewModel _publicShareVM;
  late final PlanCopySourceViewModel _planCopySourceVM;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    _checklistVM = buildChecklistVM();
    _expenseVM = buildExpenseVM();
    _publicShareVM = buildPublicShareVM();
    _planCopySourceVM = buildPlanCopySourceVM();
    widget.viewModel.loadPlan(widget.planId);
    _checklistVM.loadItems(widget.planId);
    _expenseVM.loadExpenses(widget.planId);
    _publicShareVM.loadLink(widget.planId);
    _planCopySourceVM.loadSource(widget.planId);
    if (widget.successMessage != null && widget.successMessage!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppFeedback.showSuccessSnack(
          context,
          widget.successMessage!,
          duration: const Duration(seconds: 3),
        );
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _checklistVM.dispose();
    _expenseVM.dispose();
    _publicShareVM.dispose();
    _planCopySourceVM.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload: load lại dữ liệu để tránh state cũ.
    widget.viewModel.loadPlan(widget.planId);
    _checklistVM.loadItems(widget.planId);
    _expenseVM.loadExpenses(widget.planId);
    _publicShareVM.loadLink(widget.planId, refresh: true);
    _planCopySourceVM.loadSource(widget.planId);
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
            listenable: Listenable.merge([
              widget.viewModel,
              _publicShareVM,
              _planCopySourceVM,
            ]),
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
    final publicShareLoaded = _publicShareVM.link != null;
    final hasActivePublicLink = _publicShareVM.hasActiveLink;
    final canCreatePublicLink = !hasActivePublicLink;

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
                if (_planCopySourceVM.source != null) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 15,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Nhận từ ${_planCopySourceVM.source!.sourceDisplayName}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
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
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    SizedBox(width: 10),
                    Text('Xóa kế hoạch'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share_text',
                child: Row(
                  children: [
                    Icon(
                      Icons.share_rounded,
                      size: 18,
                      color: AppColors.textMedium,
                    ),
                    SizedBox(width: 10),
                    Text('Chia sẻ văn bản'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share_copy_to_user',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 18,
                      color: AppColors.textMedium,
                    ),
                    SizedBox(width: 10),
                    Text('Gửi lời mời nhận template'),
                  ],
                ),
              ),
              if (canCreatePublicLink)
                PopupMenuItem(
                  value: 'create_public_link',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.public_rounded,
                        size: 18,
                        color: AppColors.textMedium,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        publicShareLoaded
                            ? 'Tạo link công khai mới'
                            : 'Tạo link công khai',
                      ),
                    ],
                  ),
                ),
              if (hasActivePublicLink) ...[
                const PopupMenuItem(
                  value: 'open_public_link',
                  child: Row(
                    children: [
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 18,
                        color: AppColors.textMedium,
                      ),
                      SizedBox(width: 10),
                      Text('Mở link công khai'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'copy_public_link',
                  child: Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: 18,
                        color: AppColors.textMedium,
                      ),
                      SizedBox(width: 10),
                      Text('Sao chép link'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'update_public_link',
                  child: Row(
                    children: [
                      Icon(
                        Icons.sync_rounded,
                        size: 18,
                        color: AppColors.textMedium,
                      ),
                      SizedBox(width: 10),
                      Text('Cập nhật link'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'revoke_public_link',
                  child: Row(
                    children: [
                      Icon(
                        Icons.link_off_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                      SizedBox(width: 10),
                      Text('Thu hồi link'),
                    ],
                  ),
                ),
              ],
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
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
    if (_publicShareVM.isSubmitting) return;

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
      case 'delete':
        await _deletePlan();
        break;
      case 'share_text':
        final text = await PlanShareBuilder.build(widget.planId);
        final subject = widget.viewModel.plan?.name.trim().isNotEmpty == true
            ? widget.viewModel.plan!.name
            : 'Kế hoạch chuyến đi';
        await Share.share(text, subject: subject);
        break;
      case 'share_copy_to_user':
        await _openPlanCopyShareSheet();
        break;
      case 'create_public_link':
        await _createPublicLink();
        break;
      case 'open_public_link':
        await _openPublicLink();
        break;
      case 'copy_public_link':
        await _copyPublicLink();
        break;
      case 'update_public_link':
        await _updatePublicLink();
        break;
      case 'revoke_public_link':
        await _revokePublicLink();
        break;
    }
  }

  Future<void> _deletePlan() async {
    final plan = widget.viewModel.plan;
    if (plan == null) {
      AppFeedback.showWarningSnack(
        context,
        'Kế hoạch hiện tại không còn khả dụng để xóa.',
      );
      return;
    }

    final confirmed = await AppFeedback.showConfirmDialog(
      context: context,
      title: 'Xóa kế hoạch?',
      message: 'Bạn muốn xóa "${plan.name}"?\nTất cả dữ liệu sẽ bị mất.',
      confirmText: 'Xóa',
      destructive: true,
    );
    if (!confirmed) return;

    final deleted = await widget.viewModel.deletePlan();
    if (!mounted) return;

    if (deleted) {
      Navigator.pop(context, {
        'deleted': true,
        'message': 'Đã xóa kế hoạch "${plan.name}"',
      });
      return;
    }

    AppFeedback.showErrorSnack(
      context,
      widget.viewModel.errorMessage ?? 'Xóa kế hoạch thất bại',
    );
  }

  Future<void> _openPlanCopyShareSheet() async {
    final plan = widget.viewModel.plan;
    if (plan == null) {
      AppFeedback.showWarningSnack(
        context,
        'Kế hoạch hiện tại chưa sẵn sàng để chia sẻ.',
      );
      return;
    }

    final shareCopyVM = buildPlanCopyShareVM();
    final result = await PlanCopyShareSheet.show(
      context,
      viewModel: shareCopyVM,
      sourcePlanId: plan.id,
      sourceUserId: plan.userId,
      planName: plan.name,
    );
    shareCopyVM.dispose();

    if (!mounted || result == null) return;

    AppFeedback.showSuccessSnack(
      context,
      'Đã gửi lời mời nhận template cho ${result.recipient.fullName}',
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _createPublicLink() async {
    final confirmed = await AppFeedback.showConfirmDialog(
      context: context,
      title: 'Tạo link công khai',
      message:
          'Link này sẽ hiển thị công khai kế hoạch, lịch trình, chi tiêu và checklist cho bất kỳ ai có link.',
      confirmText: 'Tạo link',
    );
    if (!confirmed) return;

    final link = await _publicShareVM.createLink(widget.planId);
    if (!mounted) return;

    if (link != null) {
      await Clipboard.setData(ClipboardData(text: link.publicUrl));
      if (!mounted) return;
      AppFeedback.showSuccessSnack(
        context,
        'Đã tạo link công khai và sao chép vào clipboard',
        duration: const Duration(seconds: 3),
      );
    } else {
      AppFeedback.showErrorSnack(
        context,
        _publicShareVM.errorMessage ?? 'Không thể tạo link công khai',
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _copyPublicLink() async {
    final link = _publicShareVM.link;
    if (link == null || link.isRevoked) {
      AppFeedback.showWarningSnack(context, 'Kế hoạch chưa có link công khai.');
      return;
    }

    await Clipboard.setData(ClipboardData(text: link.publicUrl));
    if (!mounted) return;
    AppFeedback.showSuccessSnack(context, 'Đã sao chép link công khai');
  }

  Future<void> _openPublicLink() async {
    final link = _publicShareVM.link;
    if (link == null || link.isRevoked) {
      AppFeedback.showWarningSnack(context, 'Kế hoạch chưa có link công khai.');
      return;
    }

    final uri = Uri.tryParse(link.publicUrl);
    if (uri == null) {
      AppFeedback.showErrorSnack(
        context,
        'Link công khai hiện tại không hợp lệ.',
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!launched) {
      AppFeedback.showErrorSnack(
        context,
        'Không thể mở link công khai trên thiết bị này.',
      );
    }
  }

  Future<void> _updatePublicLink() async {
    final link = await _publicShareVM.updateLink(widget.planId);
    if (!mounted) return;

    if (link != null) {
      AppFeedback.showSuccessSnack(
        context,
        'Đã cập nhật link công khai',
        duration: const Duration(seconds: 3),
      );
    } else {
      AppFeedback.showErrorSnack(
        context,
        _publicShareVM.errorMessage ?? 'Không thể cập nhật link công khai',
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _revokePublicLink() async {
    final confirmed = await AppFeedback.showConfirmDialog(
      context: context,
      title: 'Thu hồi link',
      message:
          'Link công khai hiện tại sẽ không còn truy cập được sau khi thu hồi.',
      confirmText: 'Thu hồi',
      destructive: true,
    );
    if (!confirmed) return;

    final success = await _publicShareVM.revokeLink(widget.planId);
    if (!mounted) return;

    if (success) {
      AppFeedback.showSuccessSnack(
        context,
        'Đã thu hồi link công khai',
        duration: const Duration(seconds: 3),
      );
    } else {
      AppFeedback.showErrorSnack(
        context,
        _publicShareVM.errorMessage ?? 'Không thể thu hồi link công khai',
        duration: const Duration(seconds: 3),
      );
    }
  }
}
