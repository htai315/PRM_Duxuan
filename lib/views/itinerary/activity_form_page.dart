import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/enums/activity_type.dart';
import 'package:du_xuan/core/utils/app_currency_input_formatter.dart';
import 'package:du_xuan/core/utils/app_feedback.dart';
import 'package:du_xuan/core/utils/app_form_validators.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/viewmodels/itinerary/activity_form_viewmodel.dart';
import 'package:du_xuan/views/itinerary/widgets/activity_form_app_bar.dart';
import 'package:du_xuan/views/itinerary/widgets/activity_form_bottom_action.dart';
import 'package:du_xuan/views/itinerary/widgets/activity_form_input.dart';
import 'package:du_xuan/views/itinerary/widgets/activity_form_type_selector.dart';
import 'package:du_xuan/views/shared/widgets/app_form_section_card.dart';

class ActivityFormPage extends StatefulWidget {
  final ActivityFormViewModel viewModel;
  final int planDayId;
  final Activity? existingActivity;

  const ActivityFormPage({
    super.key,
    required this.viewModel,
    required this.planDayId,
    this.existingActivity,
  });

  @override
  State<ActivityFormPage> createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends State<ActivityFormPage> {
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  ActivityType _selectedType = ActivityType.travel;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // Real-time validation state
  String? _timeErrorMessage;
  String? _costErrorMessage;

  // Track scroll for header shadow
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  bool _allowPop = false;
  String _initialTitle = '';
  String _initialLocation = '';
  String _initialCost = '';
  String _initialNote = '';
  ActivityType _initialType = ActivityType.travel;
  TimeOfDay? _initialStartTime;
  TimeOfDay? _initialEndTime;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 10 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 10 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });

    final existing = widget.existingActivity;
    if (existing != null) {
      widget.viewModel.setExisting(existing);
      _titleCtrl.text = existing.title;
      _locationCtrl.text = existing.locationText ?? '';
      _costCtrl.text = AppCurrencyInputFormatter.formatStoredAmount(
        existing.estimatedCost,
      );
      _noteCtrl.text = existing.note ?? '';
      _selectedType = existing.activityType;
      _startTime = _parseTime(existing.startTime);
      _endTime = _parseTime(existing.endTime);
    }
    _captureInitialState();
  }

  TimeOfDay? _parseTime(String? time) {
    if (time == null || time.isEmpty) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _costCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingActivity != null;

    return PopScope(
      canPop: !_shouldGuardExit,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _attemptClose();
      },
      child: Scaffold(
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
                ActivityFormAppBar(
                  title: isEdit ? 'Sửa hoạt động' : 'Thêm hoạt động',
                  isScrolled: _isScrolled,
                  onBack: _attemptClose,
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: widget.viewModel,
                    builder: (context, child) => _buildForm(),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: ActivityFormBottomAction(
          isDisabled: _isSaveDisabled,
          isLoading: widget.viewModel.isLoading,
          isEdit: isEdit,
          onSave: _isSaveDisabled ? null : _handleSave,
        ),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        AppFormSectionCard(
          title: 'Thông tin chính',
          subtitle: 'Tên và mô tả ngắn cho hoạt động của bạn',
          icon: Icons.edit_note_rounded,
          accentColor: AppColors.primary,
          child: Column(
            children: [
              ActivityFormInput(
                controller: _titleCtrl,
                hint: 'Tên hoạt động *',
                icon: Icons.edit_rounded,
                iconColor: AppColors.primary,
                isBorderless: true,
                onChanged: _handleTextChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        AppFormSectionCard(
          title: 'Phân loại',
          subtitle: 'Chọn loại hoạt động để nhóm và hiển thị phù hợp',
          icon: Icons.category_rounded,
          accentColor: AppColors.blossomDeep,
          child: ActivityFormTypeSelector(
            selectedType: _selectedType,
            onSelected: (type) => setState(() => _selectedType = type),
            resolveColor: (type) => type.color,
          ),
        ),
        const SizedBox(height: 24),

        AppFormSectionCard(
          title: 'Hành trình',
          subtitle: 'Thiết lập thời gian và địa điểm cho hoạt động',
          icon: Icons.route_rounded,
          accentColor: AppColors.primary,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_filled_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _timePicker('Bắt đầu', _startTime, (t) {
                              widget.viewModel.clearError();
                              setState(() => _startTime = t);
                              _validateTimeRange();
                            }),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: AppColors.textLight,
                            ),
                          ),
                          Expanded(
                            child: _timePicker('Kết thúc', _endTime, (t) {
                              widget.viewModel.clearError();
                              setState(() => _endTime = t);
                              _validateTimeRange();
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_timeErrorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    left: 48,
                    right: 16,
                    bottom: 8,
                  ),
                  child: Text(
                    _timeErrorMessage!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
              Divider(
                color: AppColors.divider.withValues(alpha: 0.5),
                height: 1,
                indent: 48,
                endIndent: 16,
              ),
              ActivityFormInput(
                controller: _locationCtrl,
                hint: 'Địa điểm',
                icon: Icons.place_rounded,
                iconColor: AppColors.blossomDeep,
                isBorderless: true,
                onChanged: _handleTextChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        AppFormSectionCard(
          title: 'Chi tiết khác',
          subtitle: 'Chi phí dự kiến và ghi chú bổ sung',
          icon: Icons.sticky_note_2_rounded,
          accentColor: AppColors.goldDeep,
          child: Column(
            children: [
              ActivityFormInput(
                controller: _costCtrl,
                hint: 'Chi phí ước tính (VNĐ)',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.goldDeep,
                keyboardType: TextInputType.number,
                inputFormatters: [AppCurrencyInputFormatter()],
                suffixText: 'đ',
                isBorderless: true,
                onChanged: (value) {
                  widget.viewModel.clearError();
                  _validateCostInput(value);
                },
              ),
              if (_costErrorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    left: 48,
                    right: 16,
                    top: 8,
                    bottom: 4,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _costErrorMessage!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
              Divider(
                color: AppColors.divider.withValues(alpha: 0.5),
                height: 1,
                indent: 48,
                endIndent: 16,
              ),
              ActivityFormInput(
                controller: _noteCtrl,
                hint: 'Ghi chú thêm...',
                icon: Icons.sticky_note_2_rounded,
                iconColor: AppColors.textMedium,
                maxLines: 2,
                isBorderless: true,
                onChanged: _handleTextChanged,
              ),
            ],
          ),
        ),

        // Error message overall
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

  void _validateTimeRange() {
    setState(() {
      _timeErrorMessage = AppFormValidators.validateActivityTimeRange(
        _formatTime(_startTime),
        _formatTime(_endTime),
      );
    });
  }

  void _validateCostInput(String value) {
    setState(() {
      _costErrorMessage = AppFormValidators.parseEstimatedCost(
        value,
      ).errorMessage;
    });
  }

  void _handleTextChanged(String value) {
    widget.viewModel.clearError();
    setState(() {});
  }

  void _captureInitialState() {
    _initialTitle = _titleCtrl.text.trim();
    _initialLocation = _locationCtrl.text.trim();
    _initialCost = _costCtrl.text.trim();
    _initialNote = _noteCtrl.text.trim();
    _initialType = _selectedType;
    _initialStartTime = _startTime;
    _initialEndTime = _endTime;
  }

  bool get _hasUnsavedChanges {
    return _titleCtrl.text.trim() != _initialTitle ||
        _locationCtrl.text.trim() != _initialLocation ||
        _costCtrl.text.trim() != _initialCost ||
        _noteCtrl.text.trim() != _initialNote ||
        _selectedType != _initialType ||
        _startTime != _initialStartTime ||
        _endTime != _initialEndTime;
  }

  bool get _shouldGuardExit =>
      !_allowPop && !widget.viewModel.isLoading && _hasUnsavedChanges;

  Future<void> _attemptClose() async {
    if (_allowPop) {
      if (mounted) Navigator.pop(context);
      return;
    }
    if (widget.viewModel.isLoading) {
      return;
    }
    if (!_hasUnsavedChanges) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final discard = await AppFeedback.showDiscardChangesDialog(
      context: context,
      message: 'Nếu thoát bây giờ, hoạt động bạn đang nhập sẽ bị mất.',
    );
    if (!discard || !mounted) return;
    setState(() => _allowPop = true);
    Navigator.pop(context);
  }

  Widget _timePicker(
    String label,
    TimeOfDay? value,
    ValueChanged<TimeOfDay> onPicked,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: value ?? TimeOfDay.now(),
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.bgCream.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
          ),
          child: Center(
            child: Text(
              value != null ? _formatTime(value)! : label,
              style: value != null
                  ? AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    )
                  : AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _isSaveDisabled {
    final isTitleEmpty = _titleCtrl.text.trim().isEmpty;
    return isTitleEmpty ||
        _timeErrorMessage != null ||
        _costErrorMessage != null ||
        widget.viewModel.isLoading;
  }

  Future<void> _handleSave() async {
    final result = await widget.viewModel.saveActivity(
      planDayId: widget.planDayId,
      title: _titleCtrl.text,
      activityType: _selectedType,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      locationText: _locationCtrl.text,
      note: _noteCtrl.text,
      estimatedCostText: _costCtrl.text,
    );
    if (result != null && mounted) {
      setState(() => _allowPop = true);
      Navigator.pop(context, true);
    }
  }
}
