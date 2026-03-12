import 'package:flutter/material.dart';
import 'package:du_xuan/viewmodels/checklist/checklist_viewmodel.dart';
import 'package:du_xuan/views/checklist/checklist_page.dart';

/// Tab 2: Wrapper that embeds ChecklistPage directly as a tab.
class ChecklistTab extends StatelessWidget {
  final ChecklistViewModel checklistVM;
  final int planId;
  final String planName;

  const ChecklistTab({
    super.key,
    required this.checklistVM,
    required this.planId,
    required this.planName,
  });

  @override
  Widget build(BuildContext context) {
    return ChecklistPage(
      viewModel: checklistVM,
      planId: planId,
      planName: planName,
      embeddedMode: true,  // không hiện AppBar riêng
    );
  }
}
