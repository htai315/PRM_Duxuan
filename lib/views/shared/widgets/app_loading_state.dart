import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';

class AppLoadingState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool compact;

  const AppLoadingState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.hourglass_top_rounded,
    this.accentColor = AppColors.primary,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalMargin = compact ? 28.0 : 36.0;
    final iconSize = compact ? 22.0 : 26.0;
    final cardPadding = compact
        ? const EdgeInsets.fromLTRB(18, 18, 18, 16)
        : const EdgeInsets.fromLTRB(20, 20, 20, 18);

    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
        padding: cardPadding,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.85)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 46 : 50,
              height: compact ? 46 : 50,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: compact ? 28 : 32,
                    height: compact ? 28 : 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: accentColor,
                    ),
                  ),
                  Icon(icon, size: iconSize, color: accentColor),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textLight,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
