import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/enums/checklist_category.dart';
import 'package:flutter/material.dart';

class ChecklistFormSheet extends StatelessWidget {
  final String title;
  final TextEditingController nameCtrl;
  final TextEditingController noteCtrl;
  final int quantity;
  final ChecklistCategory category;
  final ValueChanged<ChecklistCategory> onCategoryChanged;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onSave;

  const ChecklistFormSheet({
    super.key,
    required this.title,
    required this.nameCtrl,
    required this.noteCtrl,
    required this.quantity,
    required this.category,
    required this.onCategoryChanged,
    required this.onQuantityChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.divider),
              ),
              child: TextField(
                controller: nameCtrl,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Tên vật dụng *',
                  hintStyle: AppTextStyles.bodySmall,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 16, right: 10),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ChecklistCategory.values.map((cat) {
                final isActive = cat == category;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onCategoryChanged(cat),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat.icon,
                            size: 14,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cat.label,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.textMedium,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Số lượng',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (quantity > 1) onQuantityChanged(quantity - 1);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.bgPeach,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.remove_rounded,
                        size: 20,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('$quantity', style: AppTextStyles.titleMedium),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onQuantityChanged(quantity + 1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: TextField(
                controller: noteCtrl,
                style: AppTextStyles.bodyLarge,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ghi chú (tùy chọn)',
                  hintStyle: AppTextStyles.bodySmall,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 16, right: 10, top: 14),
                    child: Icon(
                      Icons.note_rounded,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Material(
              color: Colors.transparent,
              child: Ink(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDeep],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: onSave,
                  borderRadius: BorderRadius.circular(50),
                  child: Center(
                    child: Text(
                      'Lưu',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
