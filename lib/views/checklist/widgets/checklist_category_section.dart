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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(category.icon, size: 16, color: catColor),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  category.label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: catColor,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: allPacked
                      ? AppColors.success.withValues(alpha: 0.12)
                      : catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  allPacked
                      ? '✓ $packedInCat/${items.length}'
                      : '$packedInCat/${items.length}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: allPacked ? AppColors.success : catColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
      ),
    );
  }
}
