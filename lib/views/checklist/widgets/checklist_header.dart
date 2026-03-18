import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/views/shared/widgets/app_action_chip.dart';
import 'package:du_xuan/views/shared/widgets/app_badge_chip.dart';
import 'package:du_xuan/views/shared/widgets/app_circle_icon.dart';
import 'package:du_xuan/views/shared/widgets/app_header_text_group.dart';
import 'package:flutter/material.dart';

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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.82),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.gold, AppColors.goldDeep],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.checklist_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppHeaderTextGroup(
                      title: 'Checklist',
                      subtitle: planName,
                      titleStyle: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
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
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.82)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
            if (readOnly)
              AppBadgeChip(
                label: 'Chỉ xem',
                icon: Icons.visibility_rounded,
                textColor: AppColors.textMedium,
                backgroundColor: AppColors.bgCream,
                borderColor: AppColors.divider.withValues(alpha: 0.8),
                fontWeight: FontWeight.w700,
              )
            else
              AppActionChip(
                label: 'AI Gợi ý',
                icon: Icons.auto_awesome_rounded,
                onTap: onOpenAiSuggestion,
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
      ),
    );
  }
}
