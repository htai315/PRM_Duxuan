import 'package:flutter/material.dart';
import 'package:du_xuan/views/shared/widgets/app_form_bottom_action.dart';

class PlanFormBottomAction extends StatelessWidget {
  final bool isDisabled;
  final bool isLoading;
  final bool isEdit;
  final VoidCallback? onSave;

  const PlanFormBottomAction({
    super.key,
    required this.isDisabled,
    required this.isLoading,
    required this.isEdit,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AppFormBottomAction(
      isDisabled: isDisabled,
      isLoading: isLoading,
      icon: isEdit ? Icons.check_rounded : Icons.add_rounded,
      label: isEdit ? 'Cập nhật kế hoạch' : 'Tạo kế hoạch',
      onTap: onSave,
    );
  }
}
