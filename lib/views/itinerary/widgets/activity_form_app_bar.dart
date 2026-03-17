import 'package:flutter/material.dart';
import 'package:du_xuan/views/shared/widgets/app_form_app_bar.dart';

class ActivityFormAppBar extends StatelessWidget {
  final String title;
  final bool isScrolled;
  final VoidCallback onBack;

  const ActivityFormAppBar({
    super.key,
    required this.title,
    required this.isScrolled,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppFormAppBar(
      eyebrow: 'Lịch trình trong ngày',
      title: title,
      isScrolled: isScrolled,
      onBack: onBack,
    );
  }
}
