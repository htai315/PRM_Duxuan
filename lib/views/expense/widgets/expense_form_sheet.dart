import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/enums/expense_category.dart';
import 'package:du_xuan/core/utils/app_currency_input_formatter.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExpenseFormSheet extends StatelessWidget {
  final String title;
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  final TextEditingController noteCtrl;
  final String? nameError;
  final String? amountError;
  final ExpenseCategory category;
  final int? selectedPlanDayId;
  final int? selectedActivityId;
  final List<PlanDay> days;
  final List<Activity> availableActivities;
  final ValueChanged<ExpenseCategory> onCategoryChanged;
  final ValueChanged<int?> onPlanDayChanged;
  final ValueChanged<int?> onActivityChanged;
  final VoidCallback onSave;
  final String saveLabel;

  const ExpenseFormSheet({
    super.key,
    required this.title,
    required this.nameCtrl,
    required this.amountCtrl,
    required this.noteCtrl,
    this.nameError,
    this.amountError,
    required this.category,
    required this.selectedPlanDayId,
    required this.selectedActivityId,
    required this.days,
    required this.availableActivities,
    required this.onCategoryChanged,
    required this.onPlanDayChanged,
    required this.onActivityChanged,
    required this.onSave,
    this.saveLabel = 'Lưu khoản chi',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Ghi lại khoản chi thực tế để theo dõi chi tiêu trong suốt chuyến đi.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: nameCtrl,
                  label: 'Tên khoản chi',
                  hint: 'Ví dụ: Vé cáp treo',
                  icon: Icons.receipt_long_rounded,
                  errorText: nameError,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: amountCtrl,
                  label: 'Số tiền (VNĐ)',
                  hint: 'Ví dụ: 150.000 đ',
                  icon: Icons.account_balance_wallet_rounded,
                  errorText: amountError,
                  keyboardType: TextInputType.number,
                  inputFormatters: [AppCurrencyInputFormatter()],
                ),
                const SizedBox(height: 12),
                _buildCategorySelector(),
                const SizedBox(height: 12),
                _buildDayDropdown(),
                if (availableActivities.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildActivityDropdown(),
                ],
                const SizedBox(height: 12),
                _buildTextField(
                  controller: noteCtrl,
                  label: 'Ghi chú',
                  hint: 'Thông tin thêm nếu cần',
                  icon: Icons.sticky_note_2_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.goldDeep,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: Text(
                      saveLabel,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? errorText,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textDark,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        filled: true,
        fillColor: AppColors.white,
        prefixIcon: Icon(icon, color: AppColors.goldDeep),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.9),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.9),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.goldDeep),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return _buildDropdownContainer(
      icon: category.icon,
      iconColor: category.color,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ExpenseCategory>(
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
            return ExpenseCategory.values.map((item) {
              return _DropdownSelectedLabel(
                title: 'Phân loại',
                value: item.label,
              );
            }).toList();
          },
          items: ExpenseCategory.values.map((item) {
            return DropdownMenuItem<ExpenseCategory>(
              value: item,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, size: 16, color: item.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
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
    );
  }

  Widget _buildDayDropdown() {
    const iconColor = AppColors.goldDeep;

    return _buildDropdownContainer(
      icon: Icons.calendar_month_rounded,
      iconColor: iconColor,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          key: ValueKey(selectedPlanDayId),
          value: selectedPlanDayId,
          isExpanded: true,
          borderRadius: BorderRadius.circular(18),
          dropdownColor: AppColors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: iconColor,
            size: 22,
          ),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
          hint: Text(
            'Ngày phát sinh',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Không gắn ngày cụ thể'),
            ),
            ...days.map(
              (day) => DropdownMenuItem<int?>(
                value: day.id,
                child: Text('Ngày ${day.dayNumber}'),
              ),
            ),
          ],
          selectedItemBuilder: (context) {
            return [
              const _DropdownSelectedLabel(
                title: 'Ngày phát sinh',
                value: 'Không gắn ngày cụ thể',
              ),
              ...days.map(
                (day) => _DropdownSelectedLabel(
                  title: 'Ngày phát sinh',
                  value: 'Ngày ${day.dayNumber}',
                ),
              ),
            ];
          },
          onChanged: onPlanDayChanged,
        ),
      ),
    );
  }

  Widget _buildActivityDropdown() {
    const iconColor = AppColors.goldDeep;

    return _buildDropdownContainer(
      icon: Icons.link_rounded,
      iconColor: iconColor,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          key: ValueKey(selectedActivityId),
          value: selectedActivityId,
          isExpanded: true,
          borderRadius: BorderRadius.circular(18),
          dropdownColor: AppColors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: iconColor,
            size: 22,
          ),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Không gắn hoạt động'),
            ),
            ...availableActivities.map(
              (activity) => DropdownMenuItem<int?>(
                value: activity.id,
                child: Text(activity.title, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          selectedItemBuilder: (context) {
            return [
              const _DropdownSelectedLabel(
                title: 'Liên kết hoạt động',
                value: 'Không gắn hoạt động',
              ),
              ...availableActivities.map(
                (activity) => _DropdownSelectedLabel(
                  title: 'Liên kết hoạt động',
                  value: activity.title,
                ),
              ),
            ];
          },
          onChanged: onActivityChanged,
        ),
      ),
    );
  }

  Widget _buildDropdownContainer({
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
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
