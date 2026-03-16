import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/enums/notification_type.dart';
import 'package:du_xuan/core/utils/notification_service.dart';
import 'package:du_xuan/domain/entities/app_notification.dart';
import 'package:du_xuan/viewmodels/notification/notification_viewmodel.dart';

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
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadNotifications(widget.userId, refresh: true);
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context, true),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.divider.withValues(alpha: 0.8),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông báo',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                Text(
                  '${widget.viewModel.unreadCount} chưa đọc',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: widget.viewModel.unreadCount == 0
                ? null
                : () => widget.viewModel.markAllAsRead(widget.userId),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Đọc tất cả'),
          ),
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
      ),
    );
  }

  Widget _buildContent() {
    final vm = widget.viewModel;

    if (vm.isLoading && vm.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có thông báo',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hệ thống sẽ nhắc bạn khi kế hoạch sắp diễn ra.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => vm.loadNotifications(widget.userId, refresh: true),
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
        onTap: () => _openNotification(item),
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
                  color: _typeColor(item.type).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  _typeIcon(item.type),
                  size: 19,
                  color: _typeColor(item.type),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _typeColor(item.type).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.type.label,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: _typeColor(item.type),
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatWhen(item),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openNotification(AppNotification item) async {
    if (!item.isRead) {
      await widget.viewModel.markAsRead(item);
    }
    if (!mounted || item.planId == null) return;
    await Navigator.pushNamed(context, '/itinerary', arguments: item.planId);
  }

  Color _typeColor(NotificationType type) {
    switch (type) {
      case NotificationType.reminder:
        return AppColors.primary;
      case NotificationType.system:
        return AppColors.goldDeep;
    }
  }

  IconData _typeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.reminder:
        return Icons.notifications_active_rounded;
      case NotificationType.system:
        return Icons.info_outline_rounded;
    }
  }

  String _formatWhen(AppNotification item) {
    final date = item.scheduledAt ?? item.createdAt;
    return DateFormat('HH:mm • dd/MM/yyyy').format(date);
  }

  Future<void> _scheduleTestNotification() async {
    var enabled = await widget.notificationService.areNotificationsEnabled();
    if (!enabled) {
      await widget.notificationService.requestPermissions();
      enabled = await widget.notificationService.areNotificationsEnabled();
    }
    if (!enabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hệ thống đang tắt quyền thông báo cho ứng dụng'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          canExact
              ? 'Đã gửi 1 thông báo ngay lập tức + 1 thông báo sau 10 giây'
              : 'Đã gửi test, nhưng máy chưa cho phép exact alarm nên thông báo hẹn giờ có thể trễ',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: canExact ? AppColors.success : AppColors.goldDeep,
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 11), () {
      if (!mounted) return;
      widget.viewModel.loadNotifications(widget.userId, refresh: true);
    });
  }
}
