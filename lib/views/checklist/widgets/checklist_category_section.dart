import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/enums/checklist_category.dart';
import 'package:du_xuan/domain/entities/checklist_item.dart';
import 'package:du_xuan/views/checklist/widgets/checklist_item_card.dart';
import 'package:flutter/material.dart';

class ChecklistCategorySection extends StatelessWidget {
  final ChecklistCategory category;
  final List<ChecklistItem> items;
  final bool readOnly;
  final ValueChanged<ChecklistItem> onEdit;
  final ValueChanged<int> onTogglePacked;
  final Future<bool> Function(ChecklistItem item) onConfirmDelete;

  const ChecklistCategorySection({
    super.key,
    required this.category,
    required this.items,
    required this.readOnly,
    required this.onEdit,
    required this.onTogglePacked,
    required this.onConfirmDelete,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = category.color;
    final packedInCat = items.where((item) => item.isPacked).length;
    final allPacked = packedInCat == items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 14, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                catColor.withValues(alpha: 0.08),
                catColor.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(category.icon, size: 16, color: catColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: catColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: allPacked
                      ? AppColors.success.withValues(alpha: 0.12)
                      : catColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  allPacked
                      ? '✓ $packedInCat/$packedInCat'
                      : '$packedInCat/${items.length}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: allPacked ? AppColors.success : catColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.map(
          (item) => ChecklistItemCard(
            item: item,
            categoryColor: catColor,
            readOnly: readOnly,
            onEdit: () => onEdit(item),
            onTogglePacked: () => onTogglePacked(item.id),
            onConfirmDelete: () => onConfirmDelete(item),
          ),
        ),
      ],
    );
  }
}
