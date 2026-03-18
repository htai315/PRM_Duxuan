import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/domain/entities/checklist_item.dart';
import 'package:flutter/material.dart';

class ChecklistItemCard extends StatelessWidget {
  final ChecklistItem item;
  final Color categoryColor;
  final bool readOnly;
  final VoidCallback? onEdit;
  final VoidCallback? onTogglePacked;
  final Future<bool> Function()? onConfirmDelete;

  const ChecklistItemCard({
    super.key,
    required this.item,
    required this.categoryColor,
    required this.readOnly,
    this.onEdit,
    this.onTogglePacked,
    this.onConfirmDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: readOnly ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      confirmDismiss: (_) => onConfirmDelete?.call() ?? Future.value(false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: readOnly ? null : onEdit,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: item.isPacked
                  ? categoryColor.withValues(alpha: 0.06)
                  : AppColors.bgCream.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: item.isPacked
                    ? categoryColor.withValues(alpha: 0.18)
                    : AppColors.divider.withValues(alpha: 0.72),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: readOnly ? null : onTogglePacked,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: item.isPacked
                          ? categoryColor.withValues(alpha: 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: item.isPacked
                            ? categoryColor
                            : AppColors.divider,
                        width: 2,
                      ),
                    ),
                    child: item.isPacked
                        ? Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: categoryColor,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: item.isPacked
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: item.isPacked
                              ? AppColors.textLight
                              : AppColors.textDark,
                          fontSize: 14,
                        ),
                      ),
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.note!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                            height: 1.3,
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (item.quantity > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'x${item.quantity}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: categoryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    if (!readOnly) ...[
                      const SizedBox(height: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: AppColors.textLight.withValues(alpha: 0.8),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
