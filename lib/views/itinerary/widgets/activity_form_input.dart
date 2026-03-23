import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ActivityFormInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool isBorderless;
  final ValueChanged<String>? onChanged;
  final Color iconColor;
  final List<TextInputFormatter>? inputFormatters;
  final String? suffixText;

  const ActivityFormInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.iconColor,
    this.maxLines = 1,
    this.keyboardType,
    this.isBorderless = false,
    this.onChanged,
    this.inputFormatters,
    this.suffixText,
  });

  @override
  Widget build(BuildContext context) {
    final inputField = TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
        suffixText: suffixText,
        suffixStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textMedium,
          fontWeight: FontWeight.w700,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );

    if (isBorderless) return inputField;

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
