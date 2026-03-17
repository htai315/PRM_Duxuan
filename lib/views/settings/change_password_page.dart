import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/utils/app_feedback.dart';
import 'package:du_xuan/viewmodels/settings/change_password_viewmodel.dart';
import 'package:du_xuan/views/auth/widgets/auth_ui.dart';
import 'package:du_xuan/views/shared/widgets/app_form_app_bar.dart';
import 'package:du_xuan/views/shared/widgets/app_form_bottom_action.dart';
import 'package:du_xuan/views/shared/widgets/app_form_section_card.dart';

class ChangePasswordPage extends StatefulWidget {
  final ChangePasswordViewModel viewModel;
  final int userId;

  const ChangePasswordPage({
    super.key,
    required this.viewModel,
    required this.userId,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with SingleTickerProviderStateMixin {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _pageAnim;
  late Animation<double> _pageFade;
  late Animation<Offset> _pageSlide;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pageFade = CurvedAnimation(parent: _pageAnim, curve: Curves.easeOutCubic);
    _pageSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(_pageFade);
    _scrollController.addListener(_handleScroll);
    _pageAnim.forward();
  }

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _pageAnim.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final nextScrolled =
        _scrollController.hasClients && _scrollController.offset > 6;
    if (nextScrolled != _isScrolled) {
      setState(() => _isScrolled = nextScrolled);
    }
  }

  Future<void> _doChangePassword() async {
    final success = await widget.viewModel.changePassword(
      userId: widget.userId,
      oldPassword: _oldCtrl.text,
      newPassword: _newCtrl.text,
      confirmPassword: _confirmCtrl.text,
    );

    if (success && mounted) {
      AppFeedback.showSuccessSnack(context, 'Đổi mật khẩu thành công!');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgWarm, AppColors.bgCream],
          ),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, _) {
              return Column(
                children: [
                  AppFormAppBar(
                    eyebrow: 'Bảo mật tài khoản',
                    title: 'Đổi mật khẩu',
                    isScrolled: _isScrolled,
                    onBack: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: SlideTransition(
                        position: _pageSlide,
                        child: FadeTransition(
                          opacity: _pageFade,
                          child: _buildBody(),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) => AppFormBottomAction(
          isDisabled: widget.viewModel.isLoading,
          isLoading: widget.viewModel.isLoading,
          icon: Icons.lock_reset_rounded,
          label: 'Đổi mật khẩu',
          onTap: _doChangePassword,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeroCard(),
        const SizedBox(height: 16),
        AppFormSectionCard(
          title: 'Xác thực hiện tại',
          subtitle: 'Nhập mật khẩu đang dùng của bạn',
          icon: Icons.lock_outline_rounded,
          accentColor: AppColors.primary,
          child: _passwordField(
            controller: _oldCtrl,
            label: 'Mật khẩu cũ',
            icon: Icons.lock_outline_rounded,
            obscure: widget.viewModel.obscureOld,
            onToggle: widget.viewModel.toggleObscureOld,
          ),
        ),
        const SizedBox(height: 14),
        AppFormSectionCard(
          title: 'Mật khẩu mới',
          subtitle: 'Tối thiểu 6 ký tự và khác mật khẩu hiện tại',
          icon: Icons.shield_rounded,
          accentColor: AppColors.goldDeep,
          child: Column(
            children: [
              _passwordField(
                controller: _newCtrl,
                label: 'Mật khẩu mới',
                icon: Icons.lock_rounded,
                obscure: widget.viewModel.obscureNew,
                onToggle: widget.viewModel.toggleObscureNew,
              ),
              const SizedBox(height: 16),
              _passwordField(
                controller: _confirmCtrl,
                label: 'Xác nhận mật khẩu mới',
                icon: Icons.lock_rounded,
                obscure: widget.viewModel.obscureConfirm,
                onToggle: widget.viewModel.toggleObscureConfirm,
              ),
            ],
          ),
        ),
        if (widget.viewModel.errorMessage != null) ...[
          const SizedBox(height: 14),
          AuthErrorBanner(message: widget.viewModel.errorMessage!),
        ],
        const SizedBox(height: 96),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cập nhật mật khẩu',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Giữ tài khoản an toàn bằng mật khẩu mới và không trùng mật khẩu cũ.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 8),
        AuthInputField(
          controller: controller,
          hint: label,
          icon: icon,
          obscureText: obscure,
          onChanged: (_) => widget.viewModel.clearError(),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: AppColors.textLight,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
