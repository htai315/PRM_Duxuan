import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:du_xuan/views/shared/widgets/app_action_chip.dart';
import 'package:du_xuan/views/shared/widgets/app_circle_icon.dart';
import 'package:du_xuan/views/shared/widgets/app_header_text_group.dart';

class ChecklistHeader extends StatelessWidget {
  final String planName;
  final bool embeddedMode;
  final bool readOnly;
  final VoidCallback onOpenAiSuggestion;
  final VoidCallback? onBack;

  const ChecklistHeader({
    super.key,
    required this.planName,
    required this.embeddedMode,
    required this.readOnly,
    required this.onOpenAiSuggestion,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    if (embeddedMode) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gold, AppColors.goldDeep],
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.checklist_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppHeaderTextGroup(
                title: 'Đồ cần mang',
                subtitle: planName,
                titleStyle: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                subtitleStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                  fontSize: 11,
                ),
                subtitleOverflow: TextOverflow.ellipsis,
              ),
            ),
            AppActionChip(
              label: 'AI Gợi ý',
              icon: Icons.auto_awesome_rounded,
              onTap: readOnly ? null : onOpenAiSuggestion,
              textColor: AppColors.goldDeep,
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.15),
                  AppColors.goldDeep.withValues(alpha: 0.08),
                ],
              ),
              borderColor: AppColors.gold.withValues(alpha: 0.3),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          AppCircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
            backgroundColor: AppColors.white.withValues(alpha: 0.9),
            borderColor: AppColors.divider.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppHeaderTextGroup(title: 'Checklist', subtitle: planName),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: readOnly ? null : onOpenAiSuggestion,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppColors.goldDeep,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
