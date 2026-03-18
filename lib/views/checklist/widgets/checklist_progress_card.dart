import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/views/shared/widgets/app_badge_chip.dart';
import 'package:flutter/material.dart';

class ChecklistProgressCard extends StatelessWidget {
  final int packedCount;
  final int totalCount;
  final double progressPercent;

  const ChecklistProgressCard({
    super.key,
    required this.packedCount,
    required this.totalCount,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) return const SizedBox.shrink();

    final percent = progressPercent;
    final isDone = percent == 1.0;
    final progressColor = isDone ? AppColors.success : AppColors.goldDeep;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: progressColor.withValues(alpha: 0.16),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDone
                      ? Icons.checklist_rtl_rounded
                      : Icons.checklist_rounded,
                  size: 19,
                  color: progressColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDone ? 'Đã chuẩn bị xong' : 'Tiến độ chuẩn bị',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$packedCount/$totalCount vật dụng đã sẵn sàng',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AppBadgeChip(
                label: '${(percent * 100).toInt()}%',
                icon: isDone
                    ? Icons.check_circle_rounded
                    : Icons.inventory_2_rounded,
                textColor: progressColor,
                backgroundColor: progressColor.withValues(alpha: 0.12),
                borderColor: progressColor.withValues(alpha: 0.18),
                fontWeight: FontWeight.w800,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: progressColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}
