import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

class ActivityDetailItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isTappable;
  final bool isHighlight;
  final bool isLast;
  final VoidCallback? onTap;

  const ActivityDetailItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isTappable = false,
    this.isHighlight = false,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final item = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
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
                          fontSize: isHighlight ? 16 : 15,
                          fontWeight: isHighlight
                              ? FontWeight.w700
                              : FontWeight.w500,
                          decoration: isTappable
                              ? TextDecoration.underline
                              : null,
                        ),
                      ),
                    ),
                    if (isTappable)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: iconColor,
                        ),
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
            child: Divider(
              color: AppColors.divider.withValues(alpha: 0.5),
              height: 1,
            ),
          ),
      ],
    );
  }
}
