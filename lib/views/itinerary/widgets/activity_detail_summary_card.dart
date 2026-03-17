import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:flutter/material.dart';

class ActivityDetailSummaryCard extends StatelessWidget {
  final Activity activity;
  final Color typeColor;
  final bool isDone;

  const ActivityDetailSummaryCard({
    super.key,
    required this.activity,
    required this.typeColor,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
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
                Container(
                  width: 8,
                  color: isDone ? AppColors.divider : typeColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _DetailBadge(
                              icon: activity.activityType.icon,
                              label: activity.activityType.label,
                              color: isDone ? AppColors.textMedium : typeColor,
                            ),
                            const Spacer(),
                            _StatusChip(isDone: isDone),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          activity.title,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: isDone
                                ? AppColors.textMedium
                                : AppColors.textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
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
    );
  }
}

class _DetailBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DetailBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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
}

class _StatusChip extends StatelessWidget {
  final bool isDone;

  const _StatusChip({required this.isDone});

  @override
  Widget build(BuildContext context) {
    final label = isDone ? 'Hoàn thành' : 'Chưa hoàn thành';
    final color = isDone ? AppColors.white : AppColors.textMedium;
    final bg = isDone ? AppColors.success : AppColors.whiteSoft;

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
}
