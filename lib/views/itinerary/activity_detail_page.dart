import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/utils/activity_cost_ui.dart';
import 'package:du_xuan/core/utils/app_feedback.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/views/itinerary/location_action_sheet.dart';
import 'package:du_xuan/views/itinerary/widgets/activity_detail_app_bar.dart';
import 'package:du_xuan/views/itinerary/widgets/activity_detail_bottom_actions.dart';
import 'package:du_xuan/views/itinerary/widgets/activity_detail_item.dart';
import 'package:du_xuan/views/itinerary/widgets/activity_detail_summary_card.dart';

/// Trang chi tiết hoạt động (read-only) — UI Premium đồng bộ với DayDetailPage
class ActivityDetailPage extends StatelessWidget {
  final Activity activity;
  final bool isViewMode;

  const ActivityDetailPage({
    super.key,
    required this.activity,
    this.isViewMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = activity.activityType.color;
    final isDone = activity.status.name == 'done';
    final detailItems = <Widget>[];

    void addDetailItem(ActivityDetailItem item) {
      detailItems.add(item);
    }

    if (activity.startTime != null) {
      addDetailItem(
        ActivityDetailItem(
          icon: Icons.access_time_filled_rounded,
          iconColor: AppColors.primary,
          label: 'Thời gian',
          value: activity.endTime != null
              ? '${activity.startTime} - ${activity.endTime}'
              : activity.startTime!,
        ),
      );
    }

    if (activity.estimatedCost != null && activity.estimatedCost! > 0) {
      addDetailItem(
        ActivityDetailItem(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: AppColors.goldDeep,
          label: 'Chi phí ước tính',
          value: ActivityCostUi.formatCurrency(activity.estimatedCost!),
          isHighlight: true,
        ),
      );
    }

    if (activity.locationText != null && activity.locationText!.isNotEmpty) {
      addDetailItem(
        ActivityDetailItem(
          icon: Icons.place_rounded,
          iconColor: AppColors.blossomDeep,
          label: 'Địa điểm',
          value: activity.locationText!,
          isTappable: true,
          onTap: () {
            LocationActionSheet.show(
              context: context,
              locationText: activity.locationText!,
              activityTitle: activity.title,
            );
          },
        ),
      );
    }

    if (activity.note != null && activity.note!.isNotEmpty) {
      addDetailItem(
        ActivityDetailItem(
          icon: Icons.sticky_note_2_rounded,
          iconColor: AppColors.textMedium,
          label: 'Ghi chú',
          value: activity.note!,
        ),
      );
    }

    if (isViewMode) {
      addDetailItem(
        ActivityDetailItem(
          icon: Icons.receipt_long_rounded,
          iconColor: AppColors.success,
          label: 'Chi tiêu thực tế',
          value: 'Ghi và theo dõi trong tab Chi tiêu của kế hoạch',
        ),
      );
    }

    return Scaffold(
      extendBody: true,
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
          child: Column(
            children: [
              ActivityDetailAppBar(onBack: () => Navigator.pop(context)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ActivityDetailSummaryCard(
                        activity: activity,
                        typeColor: typeColor,
                        isDone: isDone,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Thông tin chi tiết',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < detailItems.length; i++)
                              _markAsLast(
                                detailItems[i],
                                i == detailItems.length - 1,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isViewMode
          ? null
          : ActivityDetailBottomActions(
              onDelete: () => _confirmDelete(context),
              onEdit: () => Navigator.pop(context, 'edited'),
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await AppFeedback.showConfirmDialog(
      context: context,
      title: 'Xóa hoạt động',
      message: 'Bạn có chắc chắn muốn xóa hoạt động này khỏi lịch trình không?',
      confirmText: 'Xóa',
      destructive: true,
    );

    if (confirm == true && context.mounted) {
      Navigator.pop(context, 'deleted');
    }
  }

  Widget _markAsLast(Widget widget, bool isLast) {
    if (widget is! ActivityDetailItem) return widget;
    return ActivityDetailItem(
      icon: widget.icon,
      iconColor: widget.iconColor,
      label: widget.label,
      value: widget.value,
      isTappable: widget.isTappable,
      isHighlight: widget.isHighlight,
      isLast: isLast,
      onTap: widget.onTap,
    );
  }
}
