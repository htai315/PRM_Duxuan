import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/enums/checklist_category.dart';
import 'package:du_xuan/core/utils/app_feedback.dart';
import 'package:du_xuan/di.dart';
import 'package:du_xuan/domain/entities/checklist_item.dart';
import 'package:du_xuan/viewmodels/checklist/checklist_viewmodel.dart';
import 'package:du_xuan/views/checklist/suggestion_bottom_sheet.dart';
import 'package:du_xuan/views/checklist/widgets/checklist_category_section.dart';
import 'package:du_xuan/views/checklist/widgets/checklist_empty_state.dart';
import 'package:du_xuan/views/checklist/widgets/checklist_form_sheet.dart';
import 'package:du_xuan/views/checklist/widgets/checklist_header.dart';
import 'package:du_xuan/views/checklist/widgets/checklist_progress_card.dart';
import 'package:du_xuan/views/shared/widgets/app_loading_state.dart';
import 'package:flutter/material.dart';

class ChecklistPage extends StatefulWidget {
  final ChecklistViewModel viewModel;
  final int planId;
  final String planName;
  final bool embeddedMode;
  final bool readOnly;

  const ChecklistPage({
    super.key,
    required this.viewModel,
    required this.planId,
    required this.planName,
    this.embeddedMode = false,
    this.readOnly = false,
  });

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  @override
  void initState() {
    super.initState();
    if (!widget.embeddedMode) {
      widget.viewModel.loadItems(widget.planId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        if (widget.viewModel.isLoading && widget.viewModel.items.isEmpty) {
          return AppLoadingState(
            title: 'Đang tải checklist',
            subtitle: 'Chuẩn bị danh sách vật dụng cho chuyến đi của bạn.',
            icon: Icons.checklist_rounded,
            compact: widget.embeddedMode,
          );
        }
        return Column(
          children: [
            ChecklistHeader(
              planName: widget.planName,
              embeddedMode: widget.embeddedMode,
              readOnly: widget.readOnly,
              onBack: widget.embeddedMode ? null : () => Navigator.pop(context),
              onOpenAiSuggestion: _openAiSuggestion,
            ),
            ChecklistProgressCard(
              packedCount: widget.viewModel.packedCount,
              totalCount: widget.viewModel.totalCount,
              progressPercent: widget.viewModel.progressPercent,
            ),
            Expanded(child: _buildGroupedList()),
          ],
        );
      },
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: widget.readOnly ? null : _buildFab(),
      body: widget.embeddedMode
          ? content
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.bgWarm, AppColors.bgCream],
                ),
              ),
              child: SafeArea(child: content),
            ),
    );
  }

  Widget _buildGroupedList() {
    final vm = widget.viewModel;

    if (vm.items.isEmpty) {
      return ChecklistEmptyState(
        readOnly: widget.readOnly,
        onAdd: _showAddSheet,
      );
    }

    final grouped = vm.groupedByCategory;
    final categories = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        final items = grouped[cat]!;
        return ChecklistCategorySection(
          category: cat,
          items: items,
          readOnly: widget.readOnly,
          onEdit: _showEditSheet,
          onTogglePacked: (itemId) => widget.viewModel.togglePacked(itemId),
          onConfirmDelete: _confirmDelete,
        );
      },
    );
  }

  void _showAddSheet() {
    if (widget.readOnly) {
      return;
    }

    final nameCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var quantity = 1;
    var category = ChecklistCategory.other;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => ChecklistFormSheet(
          title: 'Thêm vật dụng',
          nameCtrl: nameCtrl,
          noteCtrl: noteCtrl,
          quantity: quantity,
          category: category,
          onCategoryChanged: (c) => setSheetState(() => category = c),
          onQuantityChanged: (q) => setSheetState(() => quantity = q),
          onSave: () async {
            final result = await widget.viewModel.addItem(
              planId: widget.planId,
              name: nameCtrl.text,
              quantity: quantity,
              category: category,
              note: noteCtrl.text,
            );
            if (result != null) {
              if (ctx.mounted) Navigator.pop(ctx);
              _showSuccessSnack('Đã thêm "${result.name}"');
              return;
            }
            _showErrorSnack(
              widget.viewModel.errorMessage ?? 'Thêm vật dụng thất bại',
            );
          },
        ),
      ),
    );
  }

  void _showEditSheet(ChecklistItem item) {
    if (widget.readOnly) {
      return;
    }

    final nameCtrl = TextEditingController(text: item.name);
    final noteCtrl = TextEditingController(text: item.note ?? '');
    var quantity = item.quantity;
    var category = item.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => ChecklistFormSheet(
          title: 'Sửa vật dụng',
          nameCtrl: nameCtrl,
          noteCtrl: noteCtrl,
          quantity: quantity,
          category: category,
          onCategoryChanged: (c) => setSheetState(() => category = c),
          onQuantityChanged: (q) => setSheetState(() => quantity = q),
          onSave: () async {
            if (nameCtrl.text.trim().isEmpty) {
              _showErrorSnack('Vui lòng nhập tên vật dụng');
              return;
            }
            final updated = item.copyWith(
              name: nameCtrl.text.trim(),
              quantity: quantity,
              category: category,
              note: noteCtrl.text.trim(),
            );
            final success = await widget.viewModel.updateItem(updated);
            if (!ctx.mounted) return;
            if (success) {
              Navigator.pop(ctx);
              _showSuccessSnack('Đã cập nhật "${updated.name}"');
              return;
            }
            _showErrorSnack(
              widget.viewModel.errorMessage ?? 'Cập nhật vật dụng thất bại',
            );
          },
        ),
      ),
    );
  }

  void _showSuccessSnack(String message) {
    if (!mounted) return;
    AppFeedback.showSuccessSnack(context, message);
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    AppFeedback.showErrorSnack(context, message);
  }

  Future<bool> _confirmDelete(ChecklistItem item) async {
    if (widget.readOnly) {
      return false;
    }

    final result = await AppFeedback.showConfirmDialog(
      context: context,
      title: 'Xóa vật dụng?',
      message: 'Bạn muốn xóa "${item.name}"?',
      confirmText: 'Xóa',
      destructive: true,
    );
    if (result == true) {
      final deleted = await widget.viewModel.deleteItem(item.id);
      if (deleted) {
        _showSuccessSnack('Đã xóa "${item.name}"');
      } else {
        _showErrorSnack(
          widget.viewModel.errorMessage ?? 'Xóa vật dụng thất bại',
        );
      }
      return deleted;
    }
    return false;
  }

  Future<void> _openAiSuggestion() async {
    if (widget.readOnly) {
      return;
    }

    if (!mounted) return;
    final suggestionVM = buildSuggestionVM();
    SuggestionBottomSheet.show(
      context: context,
      viewModel: suggestionVM,
      planId: widget.planId,
      onItemsAdded: () {
        widget.viewModel.loadItems(widget.planId);
      },
    );
  }

  Widget _buildFab() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDeep],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
