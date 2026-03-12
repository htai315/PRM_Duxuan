import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/enums/checklist_category.dart';
import 'package:du_xuan/di.dart';
import 'package:du_xuan/domain/entities/checklist_item.dart';
import 'package:du_xuan/viewmodels/checklist/checklist_viewmodel.dart';
import 'package:du_xuan/views/checklist/suggestion_bottom_sheet.dart';

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
    widget.viewModel.loadItems(widget.planId);
  }

  @override
  Widget build(BuildContext context) {
    // Trong embeddedMode, không cần Scaffold hay gradient riêng
    final content = ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        if (widget.viewModel.isLoading && widget.viewModel.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            if (!widget.embeddedMode) _buildAppBar(),
            if (widget.embeddedMode) _buildEmbeddedToolbar(),
            _buildProgressBar(),
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

  // ═══════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.divider.withValues(alpha: 0.75),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checklist',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  widget.planName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          // AI Suggestion button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.readOnly ? null : () => _openAiSuggestion(),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppColors.goldDeep,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // EMBEDDED TOOLBAR (hiện trong tab khi AppBar bị ẩn)
  // ═══════════════════════════════════════════════════════

  Widget _buildEmbeddedToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gold, AppColors.goldDeep],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.checklist_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đồ cần mang',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.planName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // AI Suggestion button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.readOnly ? null : () => _openAiSuggestion(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.15),
                      AppColors.goldDeep.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: AppColors.goldDeep,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI Gợi ý',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // PROGRESS BAR
  // ═══════════════════════════════════════════════════════

  Widget _buildProgressBar() {
    final vm = widget.viewModel;
    if (vm.totalCount == 0) return const SizedBox.shrink();

    final percent = vm.progressPercent;
    final isDone = percent == 1.0;
    final progressColor = isDone ? AppColors.success : AppColors.gold;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            progressColor.withValues(alpha: 0.06),
            progressColor.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: progressColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 5,
                  backgroundColor: progressColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
                Text(
                  '${(percent * 100).toInt()}%',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: progressColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDone ? 'Đã chuẩn bị xong' : 'Đang chuẩn bị...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDone ? AppColors.success : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${vm.packedCount}/${vm.totalCount} vật dụng đã sẵn sàng',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // GROUPED LIST
  // ═══════════════════════════════════════════════════════

  Widget _buildGroupedList() {
    final vm = widget.viewModel;

    if (vm.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.checklist_rounded,
                size: 30,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 16),
            Text('Chưa có vật dụng nào', style: AppTextStyles.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Thêm đồ cần mang cho chuyến đi',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),
            if (widget.readOnly)
              Text(
                'Kế hoạch đã hoàn thành, checklist ở chế độ chỉ xem.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                ),
              )
            else
              TextButton.icon(
                onPressed: _showAddSheet,
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
          ],
        ),
      );
    }

    final grouped = vm.groupedByCategory;
    final categories = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        final items = grouped[cat]!;
        return _categorySection(cat, items);
      },
    );
  }

  Widget _categorySection(
    ChecklistCategory category,
    List<ChecklistItem> items,
  ) {
    final catColor = category.color;
    final packedInCat = items.where((i) => i.isPacked).length;
    final allPacked = packedInCat == items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Container(
          margin: const EdgeInsets.only(top: 14, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                catColor.withValues(alpha: 0.08),
                catColor.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(category.icon, size: 16, color: catColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: catColor,
                  ),
                ),
              ),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: allPacked
                      ? AppColors.success.withValues(alpha: 0.12)
                      : catColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  allPacked
                      ? '✓ $packedInCat/$packedInCat'
                      : '$packedInCat/${items.length}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: allPacked ? AppColors.success : catColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Items
        ...items.map((item) => _itemCard(item, catColor)),
      ],
    );
  }

  Widget _itemCard(ChecklistItem item, Color catColor) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: widget.readOnly
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      confirmDismiss: (_) =>
          widget.readOnly ? Future.value(false) : _confirmDelete(item),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.readOnly ? null : () => _showEditSheet(item),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: item.isPacked
                  ? AppColors.white.withValues(alpha: 0.5)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.72),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Checkbox with category color
                GestureDetector(
                  onTap: widget.readOnly
                      ? null
                      : () => widget.viewModel.togglePacked(item.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: item.isPacked
                          ? catColor.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: item.isPacked ? catColor : AppColors.divider,
                        width: 2,
                      ),
                    ),
                    child: item.isPacked
                        ? Icon(Icons.check_rounded, size: 16, color: catColor)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Name + note
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: item.isPacked
                              ? FontWeight.w400
                              : FontWeight.w600,
                          color: item.isPacked
                              ? AppColors.textLight
                              : AppColors.textDark,
                        ),
                      ),
                      if (item.note != null && item.note!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item.note!,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                // Quantity badge
                if (item.quantity > 1) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'x${item.quantity}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: catColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // BOTTOM SHEETS
  // ═══════════════════════════════════════════════════════

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
        builder: (ctx, setSheetState) => _buildFormSheet(
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
        builder: (ctx, setSheetState) => _buildFormSheet(
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

  Widget _buildFormSheet({
    required String title,
    required TextEditingController nameCtrl,
    required TextEditingController noteCtrl,
    required int quantity,
    required ChecklistCategory category,
    required ValueChanged<ChecklistCategory> onCategoryChanged,
    required ValueChanged<int> onQuantityChanged,
    required VoidCallback onSave,
  }) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),

            // Tên
            Container(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.divider),
              ),
              child: TextField(
                controller: nameCtrl,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Tên vật dụng *',
                  hintStyle: AppTextStyles.bodySmall,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 16, right: 10),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ChecklistCategory.values.map((cat) {
                final isActive = cat == category;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onCategoryChanged(cat),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat.icon,
                            size: 14,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cat.label,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.textMedium,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Quantity stepper
            Row(
              children: [
                Text(
                  'Số lượng',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (quantity > 1) onQuantityChanged(quantity - 1);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.bgPeach,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.remove_rounded,
                        size: 20,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('$quantity', style: AppTextStyles.titleMedium),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onQuantityChanged(quantity + 1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Note
            Container(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: TextField(
                controller: noteCtrl,
                style: AppTextStyles.bodyLarge,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ghi chú (tùy chọn)',
                  hintStyle: AppTextStyles.bodySmall,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 16, right: 10, top: 14),
                    child: Icon(
                      Icons.note_rounded,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save button
            Material(
              color: Colors.transparent,
              child: Ink(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDeep],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: onSave,
                  borderRadius: BorderRadius.circular(50),
                  child: Center(
                    child: Text(
                      'Lưu',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════

  void _showSuccessSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _confirmDelete(ChecklistItem item) async {
    if (widget.readOnly) {
      return false;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xóa vật dụng?', style: AppTextStyles.titleMedium),
        content: Text(
          'Bạn muốn xóa "${item.name}"?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy', style: TextStyle(color: AppColors.textLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
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

  // ─── FAB ──────────────────────────────────────────────
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
