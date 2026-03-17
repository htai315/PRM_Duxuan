import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';

class AppActionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color textColor;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double iconSize;
  final double fontSize;
  final FontWeight fontWeight;

  const AppActionChip({
    super.key,
    required this.label,
    required this.textColor,
    this.icon,
    this.onTap,
    this.backgroundColor,
    this.gradient,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.borderRadius = 20,
    this.iconSize = 16,
    this.fontSize = 11.5,
    this.fontWeight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: isEnabled ? 1 : 0.48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: gradient == null ? backgroundColor : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(borderRadius),
              border: borderColor != null
                  ? Border.all(color: borderColor!)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: iconSize, color: textColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: fontWeight,
                    color: textColor,
                    fontSize: fontSize,
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
