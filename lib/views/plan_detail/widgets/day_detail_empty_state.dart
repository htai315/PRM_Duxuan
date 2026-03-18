import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:du_xuan/views/shared/widgets/app_empty_state.dart';

class DayDetailEmptyState extends StatelessWidget {
  final bool canAddActivity;
  final bool canAddExpense;

  const DayDetailEmptyState({
    super.key,
    required this.canAddActivity,
    required this.canAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    String subtitle;
    if (canAddActivity && canAddExpense) {
      subtitle =
          'Ngày này chưa có lịch trình nào. Bấm + để thêm hoạt động đầu tiên hoặc ghi khoản chi.';
    } else if (canAddExpense) {
      subtitle =
          'Ngày này chưa có lịch trình nào. Bạn vẫn có thể bấm + để ghi khoản chi cho ngày này.';
    } else {
      subtitle =
          'Ngày này chưa có lịch trình nào. Kế hoạch lưu trữ chỉ còn ở chế độ xem.';
    }

    return AppEmptyState(
      icon: Icons.luggage_rounded,
      title: 'Một ngày trống rỗng...',
      subtitle: subtitle,
      accentColor: AppColors.primary,
      iconBoxSize: 100,
      iconSize: 50,
      circular: true,
      padding: const EdgeInsets.symmetric(horizontal: 40),
    );
  }
}
