import 'package:flutter/material.dart';
import 'package:du_xuan/views/shared/widgets/app_form_section_card.dart';

class PlanFormSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  const PlanFormSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppFormSectionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      accentColor: accentColor,
      child: child,
    );
  }
}
