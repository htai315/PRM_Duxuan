import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/domain/entities/user.dart';
import 'package:du_xuan/viewmodels/share/plan_copy_share_viewmodel.dart';
import 'package:du_xuan/views/shared/widgets/app_action_chip.dart';
import 'package:du_xuan/views/shared/widgets/app_badge_chip.dart';
import 'package:du_xuan/views/shared/widgets/app_loading_state.dart';

class PlanCopyShareResult {
  final User recipient;
  final int requestId;

  const PlanCopyShareResult({required this.recipient, required this.requestId});
}

class PlanCopyShareSheet extends StatefulWidget {
  final PlanCopyShareViewModel viewModel;
  final int sourcePlanId;
  final int sourceUserId;
  final String planName;

  const PlanCopyShareSheet({
    super.key,
    required this.viewModel,
    required this.sourcePlanId,
    required this.sourceUserId,
    required this.planName,
  });

  static Future<PlanCopyShareResult?> show(
    BuildContext context, {
    required PlanCopyShareViewModel viewModel,
    required int sourcePlanId,
    required int sourceUserId,
    required String planName,
  }) {
    return showModalBottomSheet<PlanCopyShareResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlanCopyShareSheet(
        viewModel: viewModel,
        sourcePlanId: sourcePlanId,
        sourceUserId: sourceUserId,
        planName: planName,
      ),
    );
  }

  @override
  State<PlanCopyShareSheet> createState() => _PlanCopyShareSheetState();
}

class _PlanCopyShareSheetState extends State<PlanCopyShareSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  User? _selectedUser;

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadRecipients(excludeUserId: widget.sourceUserId);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxAvailableHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : MediaQuery.sizeOf(context).height;
            final computedHeight = maxAvailableHeight * 0.88;
            final sheetHeight = computedHeight > 560
                ? 560.0
                : (computedHeight < 280 ? maxAvailableHeight : computedHeight);

            return Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: sheetHeight,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.bgWarm,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: ListenableBuilder(
                    listenable: widget.viewModel,
                    builder: (context, _) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 42,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.divider,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Gửi lời mời nhận mẫu kế hoạch',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nhập tên hoặc tài khoản rồi bấm tìm. Khi chấp nhận, người nhận sẽ chọn ngày bắt đầu mới và hệ thống sẽ tạo một kế hoạch nháp từ "${widget.planName}".',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMedium,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildSearchField(),
                            const SizedBox(height: 12),
                            Expanded(child: _buildBody()),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: AppActionChip(
                                    label: 'Đóng',
                                    onTap: widget.viewModel.isSubmitting
                                        ? null
                                        : () => Navigator.pop(context),
                                    textColor: AppColors.textMedium,
                                    backgroundColor: AppColors.white,
                                    borderColor: AppColors.divider.withValues(
                                      alpha: 0.85,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: AppActionChip(
                                    label: widget.viewModel.isSubmitting
                                        ? 'Đang gửi...'
                                        : 'Gửi template',
                                    icon: Icons.outbox_rounded,
                                    onTap:
                                        _selectedUser == null ||
                                            widget.viewModel.isLoading ||
                                            widget.viewModel.isSubmitting
                                        ? null
                                        : _handleSubmit,
                                    textColor: Colors.white,
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primaryDeep,
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.85)),
      ),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        onChanged: _handleSearchChanged,
        onSubmitted: (_) => _performSearch(),
        decoration: InputDecoration(
          hintText: 'Tìm theo tên hoặc tài khoản',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textLight,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          suffixIcon: IconButton(
            tooltip: 'Tìm',
            onPressed: _performSearch,
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (widget.viewModel.isLoading) {
      return const AppLoadingState(
        title: 'Đang tìm tài khoản',
        subtitle: 'Đang tìm người nhận phù hợp cho lời mời này.',
        icon: Icons.people_alt_rounded,
        compact: true,
      );
    }

    if (!widget.viewModel.hasSearched) {
      return Center(
        child: Text(
          'Nhập tên hoặc tài khoản rồi bấm tìm để hiển thị kết quả.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (widget.viewModel.errorMessage != null &&
        widget.viewModel.users.isEmpty) {
      return Center(
        child: Text(
          widget.viewModel.errorMessage!,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (widget.viewModel.users.isEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy tài khoản phù hợp với từ khóa này.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedUser != null) ...[
          AppBadgeChip(
            label: 'Đã chọn: ${_selectedUser!.fullName}',
            icon: Icons.person_rounded,
            textColor: AppColors.primaryDeep,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            borderColor: AppColors.primary.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 10),
        ],
        if (widget.viewModel.errorMessage != null) ...[
          Text(
            widget.viewModel.errorMessage!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: widget.viewModel.users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = widget.viewModel.users[index];
              final isSelected = _selectedUser?.id == user.id;
              return _buildUserTile(user, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserTile(User user, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          widget.viewModel.clearError();
          setState(() => _selectedUser = user);
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.24)
                  : AppColors.divider.withValues(alpha: 0.82),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.14)
                      : AppColors.bgCream,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: isSelected ? AppColors.primary : AppColors.textMedium,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '@${user.userName}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.primary : AppColors.textLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final recipient = _selectedUser;
    if (recipient == null) return;

    final requestId = await widget.viewModel.sendRequest(
      sourcePlanId: widget.sourcePlanId,
      sourceUserId: widget.sourceUserId,
      targetUserId: recipient.id,
    );

    if (!mounted || requestId == null) return;
    Navigator.pop(
      context,
      PlanCopyShareResult(recipient: recipient, requestId: requestId),
    );
  }

  void _handleSearchChanged(String value) {
    widget.viewModel.updateQuery(value);
    if (_selectedUser != null) {
      setState(() => _selectedUser = null);
    }
  }

  Future<void> _performSearch() async {
    FocusScope.of(context).unfocus();
    await widget.viewModel.searchRecipients();
    if (!mounted) return;

    final currentSelection = _selectedUser;
    if (currentSelection == null) return;

    final stillExists = widget.viewModel.users.any(
      (user) => user.id == currentSelection.id,
    );
    if (!stillExists) {
      setState(() => _selectedUser = null);
    }
  }
}
