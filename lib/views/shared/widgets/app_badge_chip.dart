import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';

class AppBadgeChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color textColor;
  final Color backgroundColor;
  final Color? borderColor;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry padding;
  final double iconSize;

  const AppBadgeChip({
    super.key,
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    this.icon,
    this.borderColor,
    this.fontSize = 10.5,
    this.fontWeight = FontWeight.w700,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    this.iconSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
