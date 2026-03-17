import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/enums/checklist_category.dart';
import 'package:du_xuan/core/utils/app_feedback.dart';
import 'package:du_xuan/data/implementations/api/openai_service.dart';
import 'package:du_xuan/viewmodels/checklist/suggestion_viewmodel.dart';

class SuggestionBottomSheet extends StatelessWidget {
  final SuggestionViewModel viewModel;
  final int planId;
  final VoidCallback onItemsAdded;

  const SuggestionBottomSheet({
    super.key,
    required this.viewModel,
    required this.planId,
    required this.onItemsAdded,
  });

  static Future<void> show({
    required BuildContext context,
    required SuggestionViewModel viewModel,
    required int planId,
    required VoidCallback onItemsAdded,
  }) {
    // Bắt đầu fetch ngay khi mở
    viewModel.fetchSuggestions(planId);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SuggestionBottomSheet(
        viewModel: viewModel,
        planId: planId,
        onItemsAdded: onItemsAdded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              if (viewModel.isLoading) _buildLoading(),
              if (viewModel.errorMessage != null) _buildError(),
              if (!viewModel.isLoading &&
                  viewModel.errorMessage == null &&
                  viewModel.suggestions.isNotEmpty)
                Flexible(child: _buildSuggestionList()),
              if (!viewModel.isLoading && viewModel.suggestions.isNotEmpty)
                _buildFooter(context),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.gold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Gợi ý từ AI', style: AppTextStyles.titleMedium),
              ),
              if (viewModel.suggestions.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    if (viewModel.selectedCount ==
                        viewModel.suggestions.length) {
                      viewModel.deselectAll();
                    } else {
                      viewModel.selectAll();
                    }
                  },
                  child: Text(
                    viewModel.selectedCount == viewModel.suggestions.length
                        ? 'Bỏ hết'
                        : 'Chọn hết',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // LOADING
  // ═══════════════════════════════════════════════════════

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'AI đang phân tích lịch trình...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text('Vui lòng chờ vài giây', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ERROR
  // ═══════════════════════════════════════════════════════

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            viewModel.errorMessage ?? 'Có lỗi xảy ra',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // SUGGESTION LIST (grouped by category)
  // ═══════════════════════════════════════════════════════

  Widget _buildSuggestionList() {
    final grouped = viewModel.groupedSuggestions;
    final categories = grouped.keys.toList();

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        final entries = grouped[cat]!;
        return _categorySection(cat, entries);
      },
    );
  }

  Widget _categorySection(
    ChecklistCategory category,
    List<MapEntry<int, SuggestedItem>> entries,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(category.icon, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                category.label.toUpperCase(),
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMedium,
                  letterSpacing: 1,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 1, color: AppColors.divider)),
            ],
          ),
        ),
        ...entries.map((e) => _suggestionCard(e.key, e.value)),
      ],
    );
  }

  Widget _suggestionCard(int index, SuggestedItem item) {
    final isSelected = viewModel.selectedIndices.contains(index);

    return GestureDetector(
      onTap: () => viewModel.toggleSelect(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.bgPeach,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.primary,
                    )
                  : null,
            ),
            const SizedBox(width: 10),

            // Name + reason
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.reason.isNotEmpty)
                    Text(
                      item.reason,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                ],
              ),
            ),

            // Quantity badge
            if (item.quantity > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'x${item.quantity}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.goldDeep,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════════════════

  Widget _buildFooter(BuildContext context) {
    final count = viewModel.selectedCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: GestureDetector(
        onTap: count == 0
            ? null
            : () async {
                final added = await viewModel.addSelectedToChecklist(planId);
                if (context.mounted) {
                  Navigator.pop(context);
                  onItemsAdded();
                  AppFeedback.showSuccessSnack(
                    context,
                    'Đã thêm $added vật dụng từ AI',
                  );
                }
              },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            gradient: count > 0
                ? const LinearGradient(
                    colors: [AppColors.gold, AppColors.goldDeep],
                  )
                : null,
            color: count == 0 ? AppColors.divider : null,
            boxShadow: count > 0
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              count > 0 ? '✨ Thêm $count items đã chọn' : 'Chọn items để thêm',
              style: AppTextStyles.labelLarge.copyWith(
                color: count > 0 ? Colors.white : AppColors.textLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
