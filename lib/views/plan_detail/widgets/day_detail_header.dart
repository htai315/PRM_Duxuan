import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:du_xuan/views/shared/widgets/app_badge_chip.dart';
import 'package:du_xuan/views/shared/widgets/app_circle_icon.dart';
import 'package:du_xuan/views/shared/widgets/app_header_text_group.dart';

class DayDetailHeader extends StatelessWidget {
  final int dayNumber;
  final String dateLabel;
  final int activityCount;
  final VoidCallback onBack;

  const DayDetailHeader({
    super.key,
    required this.dayNumber,
    required this.dateLabel,
    required this.activityCount,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppCircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
            boxSize: 44,
            iconSize: 20,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.93),
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
              child: Row(
                children: [
                  Expanded(
                    child: AppHeaderTextGroup(
                      title: 'NGÀY $dayNumber',
                      subtitle: dateLabel,
                      titleStyle: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 1.1,
                        fontSize: 12.5,
                      ),
                      subtitleStyle: AppTextStyles.titleLarge.copyWith(
                        fontSize: 17,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  AppBadgeChip(
                    label: '$activityCount hoạt động',
                    textColor: AppColors.primaryDeep,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    fontSize: 11,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
