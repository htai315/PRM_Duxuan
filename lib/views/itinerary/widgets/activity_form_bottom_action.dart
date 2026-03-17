import 'package:flutter/material.dart';
import 'package:du_xuan/views/shared/widgets/app_form_bottom_action.dart';

class ActivityFormBottomAction extends StatelessWidget {
  final bool isDisabled;
  final bool isLoading;
  final bool isEdit;
  final VoidCallback? onSave;

  const ActivityFormBottomAction({
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
      label: isEdit ? 'Cập nhật hoạt động' : 'Tạo mới hoạt động',
      onTap: onSave,
    );
  }
}
