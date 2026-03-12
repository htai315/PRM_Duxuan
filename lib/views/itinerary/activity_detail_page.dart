import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/enums/activity_type.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/views/itinerary/location_action_sheet.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

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
    final typeColor = _getTypeColor(activity.activityType);
    final isDone = activity.status.name == 'done';
    final costFmt = NumberFormat('#,###', 'vi');

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
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header Premium Card ──
                      IntrinsicHeight(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: isDone ? 0.84 : 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: typeColor.withValues(alpha: 0.12),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Dải màu phân loại bên trái
                                  Container(
                                    width: 8,
                                    color: isDone ? AppColors.divider : typeColor,
                                  ),
                                  // Nội dung Header Card
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              _buildBadge(
                                                icon: activity.activityType.icon,
                                                label: activity.activityType.label,
                                                color: isDone ? AppColors.textMedium : typeColor,
                                              ),
                                              const Spacer(),
                                              _buildStatusChip(isDone),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            activity.title,
                                            style: AppTextStyles.titleLarge.copyWith(
                                              color: isDone ? AppColors.textMedium : AppColors.textDark,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 20, // Thu nhỏ tiêu đề xuống 20
                                              height: 1.3,
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
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Chi tiết (Detail Items) ──
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
                            // Thời gian
                            if (activity.startTime != null)
                              _buildDetailItem(
                                icon: Icons.access_time_filled_rounded,
                                iconColor: AppColors.primary,
                                label: 'Thời gian',
                                value: activity.endTime != null
                                    ? '${activity.startTime} - ${activity.endTime}'
                                    : activity.startTime!,
                              ),
                            
                            // Chi phí ước tính
                            if (activity.estimatedCost != null &&
                                activity.estimatedCost! > 0)
                              _buildDetailItem(
                                icon: Icons.account_balance_wallet_rounded,
                                iconColor: AppColors.goldDeep,
                                label: 'Chi phí ước tính',
                                value: '${costFmt.format(activity.estimatedCost!)} ₫',
                                isHighlight: true,
                              ),
                            
                            // Địa điểm
                            if (activity.locationText != null &&
                                activity.locationText!.isNotEmpty)
                              _buildDetailItem(
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

                            // Ghi chú
                            if (activity.note != null &&
                                activity.note!.isNotEmpty)
                              _buildDetailItem(
                                icon: Icons.sticky_note_2_rounded,
                                iconColor: AppColors.textMedium,
                                label: 'Ghi chú',
                                value: activity.note!,
                                isLast: true,
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
      bottomNavigationBar: isViewMode ? null : _buildBottomActions(context),
    );
  }

  // ─── Header Tùy Biến ──────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: AppColors.textDark),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Chi tiết hoạt động',
              style: AppTextStyles.titleLarge.copyWith(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    Color? bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isDone) {
    final label = isDone ? 'Hoàn thành' : 'Chưa hoàn thành';
    final color = isDone ? AppColors.white : AppColors.textMedium;
    final bg = isDone
        ? AppColors.success
        : AppColors.whiteSoft;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDone
              ? AppColors.success.withValues(alpha: 0.82)
              : AppColors.divider,
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: isDone
                ? AppColors.success.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isTappable = false,
    bool isHighlight = false,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    final item = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Thu gọn padding detail
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10), // Giảm padding icon
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor), // Giảm size icon
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isHighlight ? iconColor : AppColors.textDark,
                          fontSize: isHighlight ? 16 : 15, // Thu nhỏ text detail
                          fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                          decoration: isTappable ? TextDecoration.underline : null,
                        ),
                      ),
                    ),
                    if (isTappable)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: iconColor),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [
        if (onTap != null)
          InkWell(
            onTap: onTap,
            borderRadius: isLast
                ? const BorderRadius.vertical(bottom: Radius.circular(24))
                : BorderRadius.zero,
            child: item,
          )
        else
          item,
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 70, right: 20),
            child: Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          ),
      ],
    );
  }

  // ─── Glassmorphism Bottom Action Bar ─────────────────
  Widget _buildBottomActions(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).padding.bottom + 14,
          ),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: AppColors.divider.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Delete Button
              GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Text(
                        'Xóa hoạt động',
                        style: AppTextStyles.titleMedium,
                      ),
                      content: Text(
                        'Bạn có chắc chắn muốn xóa hoạt động này khỏi lịch trình không?',
                        style: AppTextStyles.bodyMedium,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Hủy',
                            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textMedium),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    Navigator.pop(context, 'deleted');
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 22, color: AppColors.error),
                ),
              ),
              const SizedBox(width: 12),
              // Edit Button
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, 'edited'),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDeep],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Sửa hoạt động',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(ActivityType activityType) {
    switch (activityType.name) {
      case 'travel':
        return AppColors.primary;
      case 'dining':
        return AppColors.gold;
      case 'sightseeing':
        return AppColors.blossom;
      case 'shopping':
        return AppColors.goldDeep;
      case 'worship':
        return AppColors.primaryDeep;
      case 'rest':
        return AppColors.blossomDeep;
      default:
        return AppColors.textMedium;
    }
  }
}
