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
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: item.isPacked
                  ? AppColors.white.withValues(alpha: 0.5)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.72),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: readOnly ? null : onTogglePacked,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: item.isPacked
                          ? categoryColor.withValues(alpha: 0.12)
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
                            size: 16,
                            color: categoryColor,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: item.isPacked
                              ? FontWeight.w400
                              : FontWeight.w600,
                          color: item.isPacked
                              ? AppColors.textLight
                              : AppColors.textDark,
                        ),
                      ),
                      if (item.note != null && item.note!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item.note!,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                if (item.quantity > 1) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'x${item.quantity}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
