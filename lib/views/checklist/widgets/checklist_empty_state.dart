import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:du_xuan/views/shared/widgets/app_empty_state.dart';

class ChecklistEmptyState extends StatelessWidget {
  final bool readOnly;
  final VoidCallback onAdd;

  const ChecklistEmptyState({
    super.key,
    required this.readOnly,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.checklist_rounded,
      title: 'Chưa có vật dụng nào',
      subtitle: readOnly
          ? 'Kế hoạch đã hoàn thành, checklist đang ở chế độ chỉ xem.'
          : 'Thêm đồ cần mang cho chuyến đi.',
      accentColor: AppColors.gold,
      action: readOnly
          ? null
          : TextButton.icon(
              onPressed: onAdd,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Thêm vật dụng',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}
