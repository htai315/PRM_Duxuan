import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/constants/app_colors.dart';

class AppHeaderTextGroup extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final double spacing;
  final TextOverflow? subtitleOverflow;

  const AppHeaderTextGroup({
    super.key,
    required this.title,
    this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    this.spacing = 2,
    this.subtitleOverflow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              titleStyle ??
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          SizedBox(height: spacing),
          Text(
            subtitle!,
            style:
                subtitleStyle ??
                AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
            overflow: subtitleOverflow,
          ),
        ],
      ],
    );
  }
}
