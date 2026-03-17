import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:du_xuan/views/shared/widgets/app_empty_state.dart';

class DayDetailEmptyState extends StatelessWidget {
  final bool isViewMode;

  const DayDetailEmptyState({super.key, required this.isViewMode});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.luggage_rounded,
      title: 'Một ngày trống rỗng...',
      subtitle: isViewMode
          ? 'Ngày này chưa có lịch trình nào. Hãy tận hưởng khoảng nghỉ ngơi của bạn.'
          : '"Một cuộc hành trình ngàn dặm bắt đầu từ một bước chân nhỏ". Bấm + để thêm hoạt động đầu tiên.',
      accentColor: AppColors.primary,
      iconBoxSize: 100,
      iconSize: 50,
      circular: true,
      padding: const EdgeInsets.symmetric(horizontal: 40),
    );
  }
}
