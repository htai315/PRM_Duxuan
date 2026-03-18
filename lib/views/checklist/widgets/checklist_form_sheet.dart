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
    final minHeight = MediaQuery.of(context).size.height * 0.58;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        decoration: const BoxDecoration(
          color: AppColors.bgCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Chuẩn bị vật dụng gọn gàng để chuyến đi dễ theo dõi hơn.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
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
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildCategoryDropdown(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Số lượng',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (quantity > 1) onQuantityChanged(quantity - 1);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.bgPeach,
                            borderRadius: BorderRadius.circular(12),
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
                      child: Text(
                        '$quantity',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onQuantityChanged(quantity + 1),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
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
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
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
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Material(
                  color: Colors.transparent,
                  child: Ink(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
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
                      borderRadius: BorderRadius.circular(18),
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
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(category.icon, color: category.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ChecklistCategory>(
                key: ValueKey(category),
                value: category,
                isExpanded: true,
                borderRadius: BorderRadius.circular(18),
                dropdownColor: AppColors.white,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: category.color,
                  size: 22,
                ),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
                selectedItemBuilder: (context) {
                  return ChecklistCategory.values.map((cat) {
                    return _DropdownSelectedLabel(
                      title: 'Phân loại',
                      value: cat.label,
                    );
                  }).toList();
                },
                items: ChecklistCategory.values.map((cat) {
                  return DropdownMenuItem<ChecklistCategory>(
                    value: cat,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(cat.icon, size: 16, color: cat.color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cat.label,
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
                    onCategoryChanged(value);
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

class _DropdownSelectedLabel extends StatelessWidget {
  final String title;
  final String value;

  const _DropdownSelectedLabel({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
