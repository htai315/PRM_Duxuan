import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/utils/date_ui.dart';
import 'package:du_xuan/views/shared/widgets/app_action_chip.dart';

class PlanCopyAcceptResult {
  final DateTime startDate;

  const PlanCopyAcceptResult({required this.startDate});
}

class PlanCopyAcceptSheet extends StatefulWidget {
  final String planName;
  final int dayCount;

  const PlanCopyAcceptSheet({
    super.key,
    required this.planName,
    required this.dayCount,
  });

  static Future<PlanCopyAcceptResult?> show(
    BuildContext context, {
    required String planName,
    required int dayCount,
  }) {
    return showModalBottomSheet<PlanCopyAcceptResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          PlanCopyAcceptSheet(planName: planName, dayCount: dayCount),
    );
  }

  @override
  State<PlanCopyAcceptSheet> createState() => _PlanCopyAcceptSheetState();
}

class _PlanCopyAcceptSheetState extends State<PlanCopyAcceptSheet> {
  late DateTime _selectedStartDate;

  @override
  void initState() {
    super.initState();
    _selectedStartDate = _today;
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _computedEndDate {
    return _selectedStartDate.add(Duration(days: widget.dayCount - 1));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.bgWarm,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Nhận mẫu kế hoạch',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn ngày bắt đầu mới cho mẫu kế hoạch "${widget.planName}". Hệ thống sẽ giữ nguyên ${DateUi.dayCountLabel(widget.dayCount)} và tạo kế hoạch ở trạng thái nháp để bạn tự chỉnh sửa tiếp.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMedium,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                _infoCard(
                  icon: Icons.event_available_rounded,
                  label: 'Ngày bắt đầu mới',
                  value: DateUi.weekdayFullDate(_selectedStartDate),
                  onTap: _pickStartDate,
                ),
                const SizedBox(height: 10),
                _infoCard(
                  icon: Icons.timelapse_rounded,
                  label: 'Thời lượng template',
                  value: DateUi.dayCountLabel(widget.dayCount),
                ),
                const SizedBox(height: 10),
                _infoCard(
                  icon: Icons.calendar_month_rounded,
                  label: 'Ngày kết thúc dự kiến',
                  value: DateUi.weekdayFullDate(_computedEndDate),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppActionChip(
                        label: 'Đóng',
                        onTap: () => Navigator.pop(context),
                        textColor: AppColors.textMedium,
                        backgroundColor: AppColors.white,
                        borderColor: AppColors.divider.withValues(alpha: 0.85),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppActionChip(
                        label: 'Nhận template',
                        icon: Icons.check_rounded,
                        onTap: () {
                          Navigator.pop(
                            context,
                            PlanCopyAcceptResult(startDate: _selectedStartDate),
                          );
                        },
                        textColor: Colors.white,
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.82)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.edit_calendar_rounded,
              size: 18,
              color: AppColors.textLight,
            ),
        ],
      ),
    );

    if (onTap == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: child,
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate.isBefore(_today)
          ? _today
          : _selectedStartDate,
      firstDate: _today,
      lastDate: DateTime(_today.year + 5, 12, 31),
      locale: const Locale('vi'),
      helpText: 'Chọn ngày bắt đầu',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (picked == null) return;
    setState(() {
      _selectedStartDate = DateTime(picked.year, picked.month, picked.day);
    });
  }
}
