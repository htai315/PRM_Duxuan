import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

class PlanFormInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final Color iconColor;

  const PlanFormInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.maxLines = 1,
    this.iconColor = AppColors.textMedium,
  });

  @override
  Widget build(BuildContext context) {
    final inputField = TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textLight,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 12,
            top: maxLines > 1 ? 14 : 0,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: inputField,
    );
  }
}
