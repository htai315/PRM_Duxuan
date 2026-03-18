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
    final selectedColor = resolveColor(selectedType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCream.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.85)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selectedColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(selectedType.icon, color: selectedColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ActivityType>(
                value: selectedType,
                isExpanded: true,
                borderRadius: BorderRadius.circular(18),
                dropdownColor: AppColors.white,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: selectedColor,
                  size: 22,
                ),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
                selectedItemBuilder: (context) {
                  return ActivityType.values.map((type) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        type.label,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }).toList();
                },
                items: ActivityType.values.map((type) {
                  final typeColor = resolveColor(type);
                  return DropdownMenuItem<ActivityType>(
                    value: type,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(type.icon, size: 16, color: typeColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            type.label,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onSelected(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
