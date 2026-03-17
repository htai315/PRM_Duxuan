import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/utils/app_form_validators.dart';
import 'package:du_xuan/core/utils/date_ui.dart';
import 'package:du_xuan/viewmodels/plan/plan_form_viewmodel.dart';
import 'package:du_xuan/views/plan/widgets/plan_form_app_bar.dart';
import 'package:du_xuan/views/plan/widgets/plan_form_bottom_action.dart';
import 'package:du_xuan/views/plan/widgets/plan_form_input.dart';
import 'package:du_xuan/views/plan/widgets/plan_form_section_card.dart';
import 'package:du_xuan/views/plan/widgets/plan_form_summary_card.dart';
import 'package:du_xuan/views/shared/widgets/app_loading_state.dart';

class PlanFormPage extends StatefulWidget {
  final PlanFormViewModel viewModel;
  final int userId;
  final int? editPlanId;

  const PlanFormPage({
    super.key,
    required this.viewModel,
    required this.userId,
    this.editPlanId,
  });

  @override
  State<PlanFormPage> createState() => _PlanFormPageState();
}

class _PlanFormPageState extends State<PlanFormPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _participantsCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  // Real-time validation state
  String? _dateErrorMessage;

  // Scroll tracking
  final ScrollController _scrollCtrl = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final scrolled = _scrollCtrl.offset > 10;
      if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
    });
    if (widget.editPlanId != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    await widget.viewModel.loadPlan(widget.editPlanId!);
    final plan = widget.viewModel.existingPlan;
    if (plan != null) {
      _nameCtrl.text = plan.name;
      _descCtrl.text = plan.description ?? '';
      _participantsCtrl.text = plan.participants ?? '';
      _noteCtrl.text = plan.note ?? '';
      setState(() {
        _startDate = plan.startDate;
        _endDate = plan.endDate;
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _participantsCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editPlanId != null;

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgWarm, AppColors.bgCream],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              PlanFormAppBar(
                title: isEdit ? 'Sửa kế hoạch' : 'Tạo kế hoạch mới',
                isScrolled: _isScrolled,
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: widget.viewModel,
                  builder: (context, child) {
                    if (widget.viewModel.isLoading &&
                        widget.editPlanId != null &&
                        widget.viewModel.existingPlan == null) {
                      return const AppLoadingState(
                        title: 'Đang tải kế hoạch',
                        subtitle: 'Chuẩn bị dữ liệu để bạn chỉnh sửa kế hoạch.',
                        icon: Icons.edit_note_rounded,
                      );
                    }
                    return _buildForm();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PlanFormBottomAction(
        isDisabled: !_isFormValid || widget.viewModel.isLoading,
        isLoading: widget.viewModel.isLoading,
        isEdit: isEdit,
        onSave: !_isFormValid || widget.viewModel.isLoading
            ? null
            : _handleSave,
      ),
    );
  }

  // ─── Form Body ─────────────────────────────────────────
  Widget _buildForm() {
    final isEdit = widget.editPlanId != null;
    final dayCount =
        _startDate != null &&
            _endDate != null &&
            !_endDate!.isBefore(_startDate!)
        ? _endDate!.difference(_startDate!).inDays + 1
        : 0;

    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        PlanFormSummaryCard(
          isEdit: isEdit,
          dayCount: dayCount,
          isFormValid: _isFormValid,
          subtitle: dayCount > 0
              ? '${DateUi.dayCountLabel(dayCount)} • ${DateUi.fullDateRange(_startDate!, _endDate!)}'
              : 'Điền thông tin bắt buộc trước để tạo lịch trình',
        ),
        const SizedBox(height: 18),

        PlanFormSectionCard(
          title: 'Thông tin bắt buộc',
          subtitle: 'Tên kế hoạch và thời gian chuyến đi',
          icon: Icons.flag_circle_rounded,
          accentColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Tên kế hoạch *'),
              const SizedBox(height: 8),
              PlanFormInput(
                controller: _nameCtrl,
                hint: 'Ví dụ: Đà Lạt 3N2Đ cùng gia đình',
                icon: Icons.flag_rounded,
                iconColor: AppColors.primary,
                onChanged: _handleTextChanged,
              ),
              const SizedBox(height: 14),
              _buildFieldLabel('Thời gian'),
              const SizedBox(height: 8),
              _buildDateRangeBlock(dayCount),
            ],
          ),
        ),
        const SizedBox(height: 16),

        PlanFormSectionCard(
          title: 'Thông tin bổ sung',
          subtitle: 'Giúp kế hoạch rõ ràng và dễ theo dõi hơn',
          icon: Icons.notes_rounded,
          accentColor: AppColors.goldDeep,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Người tham gia'),
              const SizedBox(height: 8),
              PlanFormInput(
                controller: _participantsCtrl,
                hint: 'Gia đình, bạn bè...',
                icon: Icons.group_rounded,
                iconColor: AppColors.blossomDeep,
                onChanged: _handleTextChanged,
              ),
              const SizedBox(height: 14),
              _buildFieldLabel('Mô tả'),
              const SizedBox(height: 8),
              PlanFormInput(
                controller: _descCtrl,
                hint: 'Mô tả ngắn về mục tiêu chuyến đi...',
                icon: Icons.description_rounded,
                maxLines: 3,
                iconColor: AppColors.goldDeep,
                onChanged: _handleTextChanged,
              ),
              const SizedBox(height: 14),
              _buildFieldLabel('Ghi chú'),
              const SizedBox(height: 8),
              PlanFormInput(
                controller: _noteCtrl,
                hint: 'Những điều cần lưu ý thêm',
                icon: Icons.sticky_note_2_rounded,
                maxLines: 2,
                iconColor: AppColors.textMedium,
                onChanged: _handleTextChanged,
              ),
            ],
          ),
        ),

        // Error message
        if (widget.viewModel.errorMessage != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_rounded,
                  color: AppColors.error,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.viewModel.errorMessage!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // COMPONENTS
  // ═══════════════════════════════════════════════════════

  void _validateDateRange() {
    setState(() {
      if (_startDate == null || _endDate == null) {
        _dateErrorMessage = null;
        return;
      }
      _dateErrorMessage = AppFormValidators.validatePlanDateRange(
        _startDate,
        _endDate,
      );
    });
  }

  bool get _isFormValid {
    return AppFormValidators.validatePlanName(_nameCtrl.text) == null &&
        AppFormValidators.validatePlanDateRange(_startDate, _endDate) == null;
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textMedium,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 0.2,
      ),
    );
  }

  void _handleTextChanged(String _) {
    widget.viewModel.clearError();
    setState(() {});
  }

  Widget _buildDateRangeBlock(int dayCount) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgCream.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _datePicker('Ngày bắt đầu', _startDate, (d) {
                  widget.viewModel.clearError();
                  setState(() => _startDate = d);
                  _validateDateRange();
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _datePicker('Ngày kết thúc', _endDate, (d) {
                  widget.viewModel.clearError();
                  setState(() => _endDate = d);
                  _validateDateRange();
                }),
              ),
            ],
          ),
          if (_dateErrorMessage != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _dateErrorMessage!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (dayCount > 0 && _dateErrorMessage == null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.goldDeep.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 14,
                      color: AppColors.goldDeep,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      DateUi.dayCountLabel(dayCount),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.goldDeep,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _datePicker(
    String label,
    DateTime? value,
    ValueChanged<DateTime> onPicked,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2024),
            lastDate: DateTime(2030),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) onPicked(picked);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 14,
                    color: value != null
                        ? AppColors.primary
                        : AppColors.textLight,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      value != null ? DateUi.fullDate(value) : 'Chọn ngày',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: value != null
                            ? AppColors.textDark
                            : AppColors.textLight,
                        fontWeight: value != null
                            ? FontWeight.w700
                            : FontWeight.w600,
                        fontSize: 11.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final result = await widget.viewModel.savePlan(
      userId: widget.userId,
      name: _nameCtrl.text,
      description: _descCtrl.text,
      startDate: _startDate,
      endDate: _endDate,
      participants: _participantsCtrl.text,
      note: _noteCtrl.text,
    );
    if (result != null && mounted) {
      Navigator.pop(context, widget.editPlanId != null ? true : result.id);
    }
  }
}
