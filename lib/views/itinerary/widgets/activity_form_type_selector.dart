import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/enums/activity_type.dart';
import 'package:flutter/material.dart';

class ActivityFormTypeSelector extends StatelessWidget {
  final ActivityType selectedType;
  final ValueChanged<ActivityType> onSelected;
  final Color Function(ActivityType) resolveColor;

  const ActivityFormTypeSelector({
    super.key,
    required this.selectedType,
    required this.onSelected,
    required this.resolveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ActivityType.values.map((type) {
        final isSelected = type == selectedType;
        final typeColor = resolveColor(type);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelected(type),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? typeColor.withValues(alpha: 0.1)
                    : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? typeColor.withValues(alpha: 0.5)
                      : AppColors.divider.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.icon,
                    size: 18,
                    color: isSelected ? typeColor : AppColors.textMedium,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    type.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected ? typeColor : AppColors.textMedium,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
