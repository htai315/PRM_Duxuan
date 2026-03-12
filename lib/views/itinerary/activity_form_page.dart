import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/enums/activity_type.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/viewmodels/itinerary/activity_form_viewmodel.dart';
import 'dart:ui';

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
  bool _hasTimeError = false;
  String? _timeErrorMessage;

  // Track scroll for header shadow
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

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
      _costCtrl.text = existing.estimatedCost?.toStringAsFixed(0) ?? '';
      _noteCtrl.text = existing.note ?? '';
      _selectedType = existing.activityType;
      _startTime = _parseTime(existing.startTime);
      _endTime = _parseTime(existing.endTime);
    }
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
              _buildAppBar(isEdit ? 'Sửa hoạt động' : 'Thêm hoạt động'),
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
      bottomNavigationBar: _buildBottomActions(),
    );
  }

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
        crossAxisAlignment: CrossAxisAlignment.center,
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
                  'Lịch trình trong ngày',
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

  Widget _buildForm() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 20),

        // Tiêu đề *
        _buildSectionTitle('Thông tin chính'),
        _buildCard(
          child: Column(
            children: [
              _textInput(
                controller: _titleCtrl,
                hint: 'Tên hoạt động *',
                icon: Icons.edit_rounded,
                isBorderless: true,
                onChanged: (_) {
                  widget.viewModel.clearError();
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Phân loại
        _buildSectionTitle('Phân loại'),
        _buildTypeSelector(),
        const SizedBox(height: 24),

        // Thời gian & Địa điểm
        _buildSectionTitle('Hành trình'),
        _buildCard(
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
              if (_hasTimeError && _timeErrorMessage != null) ...[
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
              _textInput(
                controller: _locationCtrl,
                hint: 'Địa điểm',
                icon: Icons.place_rounded,
                isBorderless: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Chi phí & Ghi chú
        _buildSectionTitle('Chi tiết khác'),
        _buildCard(
          child: Column(
            children: [
              _textInput(
                controller: _costCtrl,
                hint: 'Chi phí ước tính (VNĐ)',
                icon: Icons.account_balance_wallet_rounded,
                keyboardType: TextInputType.number,
                isBorderless: true,
              ),
              Divider(
                color: AppColors.divider.withValues(alpha: 0.5),
                height: 1,
                indent: 48,
                endIndent: 16,
              ),
              _textInput(
                controller: _noteCtrl,
                hint: 'Ghi chú thêm...',
                icon: Icons.sticky_note_2_rounded,
                maxLines: 2,
                isBorderless: true,
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
      if (_startTime != null && _endTime != null) {
        final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
        final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

        if (endMinutes <= startMinutes) {
          _hasTimeError = true;
          _timeErrorMessage = 'Giờ kết thúc phải sau giờ bắt đầu';
        } else {
          _hasTimeError = false;
          _timeErrorMessage = null;
        }
      } else {
        _hasTimeError = false;
        _timeErrorMessage = null;
      }
    });
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textMedium,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _textInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isBorderless = false,
    ValueChanged<String>? onChanged,
  }) {
    Color iconColor = AppColors.textMedium;
    if (icon == Icons.account_balance_wallet_rounded) {
      iconColor = AppColors.goldDeep;
    }
    if (icon == Icons.place_rounded) iconColor = AppColors.blossomDeep;
    if (icon == Icons.edit_rounded) iconColor = AppColors.primary;

    final inputField = TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (value) {
        if (onChanged != null) {
          onChanged(value);
          return;
        }
        widget.viewModel.clearError();
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

    if (isBorderless) return inputField;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: inputField,
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ActivityType.values.map((type) {
        final isSelected = type == _selectedType;
        Color typeColor = _getTypeColor(type);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _selectedType = type),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? typeColor.withValues(alpha: 0.1)
                    : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? typeColor.withValues(alpha: 0.5)
                      : AppColors.divider.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.icon,
                    size: 18,
                    color: isSelected ? typeColor : AppColors.textMedium,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    type.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected ? typeColor : AppColors.textMedium,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
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

  Widget _buildSummaryCard() {
    final typeColor = _getTypeColor(_selectedType);
    final start = _startTime != null ? _formatTime(_startTime) : '--:--';
    final end = _endTime != null ? _formatTime(_endTime) : '--:--';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_selectedType.icon, size: 19, color: typeColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedType.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Khung giờ: $start - $end',
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
    );
  }

  Widget _buildBottomActions() {
    final isTitleEmpty = _titleCtrl.text.trim().isEmpty;
    final bool isDisable =
        isTitleEmpty || _hasTimeError || widget.viewModel.isLoading;
    final isEdit = widget.existingActivity != null;

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
            opacity: isDisable ? 0.52 : 1,
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
                  onTap: isDisable ? null : _handleSave,
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
                        : Text(
                            isEdit ? 'Cập nhật hoạt động' : 'Tạo mới hoạt động',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                            ),
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

  Future<void> _handleSave() async {
    final costText = _costCtrl.text.trim();
    double? cost;
    if (costText.isNotEmpty) {
      cost = double.tryParse(costText);
    }

    final result = await widget.viewModel.saveActivity(
      planDayId: widget.planDayId,
      title: _titleCtrl.text,
      activityType: _selectedType,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      locationText: _locationCtrl.text,
      note: _noteCtrl.text,
      estimatedCost: cost,
    );
    if (result != null && mounted) {
      Navigator.pop(context, true);
    }
  }

  Color _getTypeColor(ActivityType activityType) {
    switch (activityType.name) {
      case 'travel':
        return AppColors.primary;
      case 'dining':
        return AppColors.gold;
      case 'sightseeing':
        return AppColors.blossom;
      case 'shopping':
        return AppColors.goldDeep;
      case 'worship':
        return AppColors.primaryDeep;
      case 'rest':
        return AppColors.blossomDeep;
      default:
        return AppColors.textMedium;
    }
  }
}
