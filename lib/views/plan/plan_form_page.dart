  import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/viewmodels/plan/plan_form_viewmodel.dart';
import 'dart:ui';

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
  bool _hasDateError = false;
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
              _buildAppBar(isEdit ? 'Sửa kế hoạch' : 'Tạo kế hoạch mới'),
              Expanded(
                child: ListenableBuilder(
                  listenable: widget.viewModel,
                  builder: (context, child) {
                    if (widget.viewModel.isLoading &&
                        widget.editPlanId != null &&
                        widget.viewModel.existingPlan == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _buildForm();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  // ─── AppBar ────────────────────────────────────────────
  Widget _buildAppBar(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isScrolled
            ? AppColors.white.withValues(alpha: 0.9)
            : Colors.transparent,
        boxShadow: _isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.divider.withValues(alpha: 0.75),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kế hoạch chuyến đi',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        _buildSummaryCard(dayCount, isEdit: isEdit),
        const SizedBox(height: 18),

        _buildSectionCard(
          title: 'Thông tin bắt buộc',
          subtitle: 'Tên kế hoạch và thời gian chuyến đi',
          icon: Icons.flag_circle_rounded,
          accentColor: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Tên kế hoạch *'),
              const SizedBox(height: 8),
              _textInput(
                controller: _nameCtrl,
                hint: 'Ví dụ: Đà Lạt 3N2Đ cùng gia đình',
                icon: Icons.flag_rounded,
                iconColor: AppColors.primary,
              ),
              const SizedBox(height: 14),
              _buildFieldLabel('Thời gian'),
              const SizedBox(height: 8),
              _buildDateRangeBlock(dayCount),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionCard(
          title: 'Thông tin bổ sung',
          subtitle: 'Giúp kế hoạch rõ ràng và dễ theo dõi hơn',
          icon: Icons.notes_rounded,
          accentColor: AppColors.goldDeep,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Người tham gia'),
              const SizedBox(height: 8),
              _textInput(
                controller: _participantsCtrl,
                hint: 'Gia đình, bạn bè...',
                icon: Icons.group_rounded,
                iconColor: AppColors.blossomDeep,
              ),
              const SizedBox(height: 14),
              _buildFieldLabel('Mô tả'),
              const SizedBox(height: 8),
              _textInput(
                controller: _descCtrl,
                hint: 'Mô tả ngắn về mục tiêu chuyến đi...',
                icon: Icons.description_rounded,
                maxLines: 3,
                iconColor: AppColors.goldDeep,
              ),
              const SizedBox(height: 14),
              _buildFieldLabel('Ghi chú'),
              const SizedBox(height: 8),
              _textInput(
                controller: _noteCtrl,
                hint: 'Những điều cần lưu ý thêm',
                icon: Icons.sticky_note_2_rounded,
                maxLines: 2,
                iconColor: AppColors.textMedium,
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

  // ─── Glassmorphism Bottom Action ───────────────────────
  Widget _buildBottomAction() {
    final bool isDisabled = !_isFormValid || widget.viewModel.isLoading;
    final isEdit = widget.editPlanId != null;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).padding.bottom + 14,
          ),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: AppColors.divider.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isDisabled ? 0.52 : 1,
            child: Material(
              color: Colors.transparent,
              child: Ink(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDeep],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: isDisabled ? null : _handleSave,
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: widget.viewModel.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isEdit
                                    ? Icons.check_rounded
                                    : Icons.add_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isEdit ? 'Cập nhật kế hoạch' : 'Tạo kế hoạch',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // COMPONENTS
  // ═══════════════════════════════════════════════════════

  void _validateDateRange() {
    setState(() {
      if (_startDate != null && _endDate != null) {
        if (_endDate!.isBefore(_startDate!)) {
          _hasDateError = true;
          _dateErrorMessage = 'Ngày kết thúc phải sau ngày bắt đầu';
        } else {
          _hasDateError = false;
          _dateErrorMessage = null;
        }
      } else {
        _hasDateError = false;
        _dateErrorMessage = null;
      }
    });
  }

  bool get _isFormValid {
    return _nameCtrl.text.trim().isNotEmpty &&
        _startDate != null &&
        _endDate != null &&
        !_hasDateError;
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 19, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
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
                  setState(() => _startDate = d);
                  _validateDateRange();
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _datePicker('Ngày kết thúc', _endDate, (d) {
                  setState(() => _endDate = d);
                  _validateDateRange();
                }),
              ),
            ],
          ),
          if (_hasDateError && _dateErrorMessage != null) ...[
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
          if (dayCount > 0 && !_hasDateError) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      '$dayCount ngày',
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

  Widget _textInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    Color iconColor = AppColors.textMedium,
  }) {
    final inputField = TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: (_) {
        widget.viewModel.clearError();
        setState(() {}); // Trigger rebuild for _isFormValid
      },
      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textLight,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 12,
            top: maxLines > 1 ? 14 : 0,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: inputField,
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
                    color: value != null ? AppColors.primary : AppColors.textLight,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      value != null ? _formatDate(value) : 'Chọn ngày',
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

  Widget _buildSummaryCard(int dayCount, {required bool isEdit}) {
    final title = isEdit ? 'Cập nhật kế hoạch' : 'Tạo kế hoạch mới';
    final subtitle = dayCount > 0
        ? '$dayCount ngày • ${_formatDate(_startDate)} - ${_formatDate(_endDate)}'
        : 'Điền thông tin bắt buộc trước để tạo lịch trình';
    final completion = _isFormValid ? 'Đủ thông tin bắt buộc' : 'Thiếu thông tin bắt buộc';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDeep, AppColors.primary, AppColors.primarySoft],
          stops: [0, 0.62, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.26),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEdit ? Icons.edit_calendar_rounded : Icons.auto_awesome_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isFormValid ? Icons.check_circle_rounded : Icons.pending_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  completion,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--/--/----';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
      Navigator.pop(context, true);
    }
  }
}
