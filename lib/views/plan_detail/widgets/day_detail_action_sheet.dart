import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

class DayDetailActionSheet extends StatelessWidget {
  final VoidCallback? onAddActivity;
  final VoidCallback? onAddExpense;

  const DayDetailActionSheet({
    super.key,
    this.onAddActivity,
    this.onAddExpense,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onAddActivity,
    VoidCallback? onAddExpense,
  }) {
    if (onAddActivity == null && onAddExpense == null) {
      return Future.value();
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DayDetailActionSheet(
        onAddActivity: onAddActivity,
        onAddExpense: onAddExpense,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (onAddActivity != null)
        _ActionTile(
          label: 'Thêm hoạt động',
          subtitle: 'Bổ sung lịch trình cho ngày này',
          icon: Icons.event_note_rounded,
          accentColor: AppColors.primary,
          onTap: () {
            Navigator.pop(context);
            onAddActivity!();
          },
        ),
      if (onAddExpense != null)
        _ActionTile(
          label: 'Thêm chi tiêu',
          subtitle: 'Ghi nhanh một khoản chi thực tế',
          icon: Icons.receipt_long_rounded,
          accentColor: AppColors.goldDeep,
          onTap: () {
            Navigator.pop(context);
            onAddExpense!();
          },
        ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
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
              const SizedBox(height: 14),
              Text(
                'Thao tác nhanh',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Chọn thao tác bạn muốn thực hiện cho ngày này.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < actions.length; i++) ...[
                actions[i],
                if (i < actions.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accentColor.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
