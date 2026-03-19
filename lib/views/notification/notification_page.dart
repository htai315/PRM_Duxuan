import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/utils/app_feedback.dart';
import 'package:du_xuan/core/utils/notification_service.dart';
import 'package:du_xuan/core/utils/notification_ui.dart';
import 'package:du_xuan/domain/entities/app_notification.dart';
import 'package:du_xuan/domain/entities/plan_copy_request.dart';
import 'package:du_xuan/routes/app_routes.dart';
import 'package:du_xuan/routes/route_args.dart';
import 'package:du_xuan/viewmodels/notification/notification_viewmodel.dart';
import 'package:du_xuan/viewmodels/share/plan_copy_request_viewmodel.dart';
import 'package:du_xuan/views/shared/widgets/app_action_chip.dart';
import 'package:du_xuan/views/shared/widgets/app_badge_chip.dart';
import 'package:du_xuan/views/shared/widgets/app_circle_icon.dart';
import 'package:du_xuan/views/shared/widgets/app_empty_state.dart';
import 'package:du_xuan/views/shared/widgets/app_header_text_group.dart';
import 'package:du_xuan/views/shared/widgets/app_loading_state.dart';
import 'package:du_xuan/di.dart';

class NotificationPage extends StatefulWidget {
  final NotificationViewModel viewModel;
  final int userId;
  final NotificationService notificationService;

  const NotificationPage({
    super.key,
    required this.viewModel,
    required this.userId,
    required this.notificationService,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late final PlanCopyRequestViewModel _planCopyRequestVM =
      buildPlanCopyRequestVM();

  @override
  void initState() {
    super.initState();
    _loadPageData(refresh: true);
  }

  @override
  void dispose() {
    _planCopyRequestVM.dispose();
    super.dispose();
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
              _planCopyRequestVM,
            ]),
            builder: (context, _) {
              return Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildContent()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          AppCircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context, true),
            borderColor: AppColors.divider.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppHeaderTextGroup(
              title: 'Thông báo',
              subtitle: '${widget.viewModel.unreadCount} chưa đọc',
              titleStyle: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
          ),
          AppActionChip(
            label: 'Đọc tất cả',
            onTap: widget.viewModel.unreadCount == 0
                ? null
                : () => widget.viewModel.markAllAsRead(widget.userId),
            textColor: AppColors.primary,
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            borderColor: AppColors.primary.withValues(alpha: 0.16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            fontSize: 11,
          ),
          if (kDebugMode) ...[
            const SizedBox(width: 2),
            IconButton(
              tooltip: 'Test 10s',
              onPressed: _scheduleTestNotification,
              icon: const Icon(
                Icons.bug_report_outlined,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    final vm = widget.viewModel;

    if (vm.isLoading && vm.notifications.isEmpty) {
      return const AppLoadingState(
        title: 'Đang tải thông báo',
        subtitle: 'Đồng bộ danh sách nhắc lịch và thông báo hệ thống.',
        icon: Icons.notifications_active_rounded,
      );
    }

    if (vm.notifications.isEmpty) {
      return const AppEmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'Chưa có thông báo',
        subtitle: 'Hệ thống sẽ nhắc bạn khi kế hoạch sắp diễn ra.',
        accentColor: AppColors.primary,
        iconBoxSize: 68,
        iconSize: 34,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadPageData(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: vm.notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notification = vm.notifications[index];
          return _notificationCard(notification);
        },
      ),
    );
  }

  Widget _notificationCard(AppNotification item) {
    final requestId = _extractPlanCopyRequestId(item.payload);
    final request = requestId == null
        ? null
        : _planCopyRequestVM.requestFor(requestId);
    final isUnread = !item.isRead;
    final cardColor = isUnread
        ? AppColors.primary.withValues(alpha: 0.08)
        : AppColors.white.withValues(alpha: 0.94);
    final borderColor = isUnread
        ? AppColors.primary.withValues(alpha: 0.2)
        : AppColors.divider.withValues(alpha: 0.75);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _canOpenNotification(item, request)
            ? () => _openNotification(item, request)
            : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: NotificationUi.typeColor(
                    item.type,
                  ).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  NotificationUi.typeIcon(item.type),
                  size: 19,
                  color: NotificationUi.typeColor(item.type),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textDark,
                              fontWeight: isUnread
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMedium,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AppBadgeChip(
                          label: item.type.label,
                          textColor: NotificationUi.typeColor(item.type),
                          backgroundColor: NotificationUi.typeColor(
                            item.type,
                          ).withValues(alpha: 0.12),
                        ),
                        Text(
                          NotificationUi.formatWhen(item),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                            fontSize: 11,
                          ),
                        ),
                        if (request != null)
                          AppBadgeChip(
                            label: request.status.label,
                            textColor: _requestStatusColor(request),
                            backgroundColor: _requestStatusColor(
                              request,
                            ).withValues(alpha: 0.12),
                            borderColor: _requestStatusColor(
                              request,
                            ).withValues(alpha: 0.18),
                          ),
                      ],
                    ),
                    if (request != null && request.isPending) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: AppActionChip(
                              label: _planCopyRequestVM.isSubmitting(request.id)
                                  ? 'Đang xử lý...'
                                  : 'Từ chối',
                              icon: Icons.close_rounded,
                              onTap: _planCopyRequestVM.isSubmitting(request.id)
                                  ? null
                                  : () => _rejectRequest(item, request),
                              textColor: AppColors.textMedium,
                              backgroundColor: AppColors.white,
                              borderColor: AppColors.divider.withValues(
                                alpha: 0.9,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppActionChip(
                              label: _planCopyRequestVM.isSubmitting(request.id)
                                  ? 'Đang xử lý...'
                                  : 'Chấp nhận',
                              icon: Icons.check_rounded,
                              onTap: _planCopyRequestVM.isSubmitting(request.id)
                                  ? null
                                  : () => _acceptRequest(item, request),
                              textColor: Colors.white,
                              backgroundColor: AppColors.success,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openNotification(
    AppNotification item,
    PlanCopyRequest? request,
  ) async {
    final targetPlanId =
        request?.isAccepted == true && request?.targetPlanId != null
        ? request!.targetPlanId
        : item.planId;
    if (targetPlanId == null) return;

    if (!item.isRead) {
      await widget.viewModel.markAsRead(item);
    }
    if (!mounted) return;
    await Navigator.pushNamed(
      context,
      AppRoutes.itinerary,
      arguments: ItineraryRouteArgs(planId: targetPlanId),
    );
  }

  Future<void> _scheduleTestNotification() async {
    var enabled = await widget.notificationService.areNotificationsEnabled();
    if (!enabled) {
      await widget.notificationService.requestPermissions();
      enabled = await widget.notificationService.areNotificationsEnabled();
    }
    if (!enabled) {
      if (!mounted) return;
      AppFeedback.showErrorSnack(
        context,
        'Hệ thống đang tắt quyền thông báo cho ứng dụng',
      );
      return;
    }

    final canExact = await widget.notificationService.canScheduleExactAlarms();
    await widget.notificationService.showInstantTestNotification(
      userId: widget.userId,
    );
    await widget.notificationService.scheduleTestNotification(
      userId: widget.userId,
      delaySeconds: 10,
    );
    if (!mounted) return;

    AppFeedback.showSnack(
      context,
      message: canExact
          ? 'Đã gửi 1 thông báo ngay lập tức + 1 thông báo sau 10 giây'
          : 'Đã gửi test, nhưng máy chưa cho phép exact alarm nên thông báo hẹn giờ có thể trễ',
      type: canExact ? AppFeedbackType.success : AppFeedbackType.warning,
    );

    Future.delayed(const Duration(seconds: 11), () {
      if (!mounted) return;
      _loadPageData(refresh: true);
    });
  }

  Future<void> _loadPageData({required bool refresh}) async {
    await widget.viewModel.loadNotifications(widget.userId, refresh: refresh);
    if (!mounted) return;
    await _loadPlanCopyRequests();
  }

  Future<void> _loadPlanCopyRequests() async {
    final ids = widget.viewModel.notifications
        .map((item) => _extractPlanCopyRequestId(item.payload))
        .whereType<int>()
        .toList();
    await _planCopyRequestVM.loadRequestsByIds(ids);
  }

  bool _canOpenNotification(AppNotification item, PlanCopyRequest? request) {
    if (request != null) {
      return request.isAccepted && request.targetPlanId != null;
    }
    return item.planId != null;
  }

  int? _extractPlanCopyRequestId(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        final value = decoded['planCopyRequestId'];
        if (value is int) return value;
        return int.tryParse(value?.toString() ?? '');
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Color _requestStatusColor(PlanCopyRequest request) {
    if (request.isAccepted) return AppColors.success;
    if (request.isRejected) return AppColors.error;
    return AppColors.goldDeep;
  }

  Future<void> _acceptRequest(
    AppNotification item,
    PlanCopyRequest request,
  ) async {
    final newPlanId = await _planCopyRequestVM.acceptRequest(
      requestId: request.id,
      targetUserId: widget.userId,
    );
    if (!mounted || newPlanId == null) {
      final message = _planCopyRequestVM.errorMessage;
      if (message != null && mounted) {
        AppFeedback.showErrorSnack(context, message);
      }
      return;
    }

    await widget.viewModel.markAsRead(item);
    if (!mounted) return;
    AppFeedback.showSuccessSnack(
      context,
      'Đã thêm kế hoạch vào tài khoản của bạn',
    );
  }

  Future<void> _rejectRequest(
    AppNotification item,
    PlanCopyRequest request,
  ) async {
    final success = await _planCopyRequestVM.rejectRequest(
      requestId: request.id,
      targetUserId: widget.userId,
    );
    if (!mounted) return;
    if (!success) {
      final message = _planCopyRequestVM.errorMessage;
      if (message != null) {
        AppFeedback.showErrorSnack(context, message);
      }
      return;
    }

    await widget.viewModel.markAsRead(item);
    if (!mounted) return;
    AppFeedback.showSnack(
      context,
      message: 'Bạn đã từ chối lời mời nhận kế hoạch',
      type: AppFeedbackType.info,
    );
  }
}
