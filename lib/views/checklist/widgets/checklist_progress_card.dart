import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
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
    final progressColor = isDone ? AppColors.success : AppColors.gold;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            progressColor.withValues(alpha: 0.06),
            progressColor.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: progressColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 5,
                  backgroundColor: progressColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
                Text(
                  '${(percent * 100).toInt()}%',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: progressColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDone ? 'Đã chuẩn bị xong' : 'Đang chuẩn bị...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDone ? AppColors.success : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$packedCount/$totalCount vật dụng đã sẵn sàng',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
