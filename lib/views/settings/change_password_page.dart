import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/viewmodels/settings/change_password_viewmodel.dart';
import 'package:du_xuan/views/auth/widgets/auth_ui.dart';

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
  late AnimationController _pageAnim;
  late Animation<double> _pageFade;
  late Animation<Offset> _pageSlide;

  @override
  void initState() {
    super.initState();
    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pageFade = CurvedAnimation(
      parent: _pageAnim,
      curve: Curves.easeOutCubic,
    );
    _pageSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(_pageFade);
    _pageAnim.forward();
  }

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _pageAnim.dispose();
    super.dispose();
  }

  Future<void> _doChangePassword() async {
    final success = await widget.viewModel.changePassword(
      userId: widget.userId,
      oldPassword: _oldCtrl.text,
      newPassword: _newCtrl.text,
      confirmPassword: _confirmCtrl.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đổi mật khẩu thành công! 🎉'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBackButton: true,
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: SlideTransition(
        position: _pageSlide,
        child: FadeTransition(
          opacity: _pageFade,
          child: ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, _) => _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return AuthPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthHeader(
            icon: Icons.lock_reset_rounded,
            title: 'Đổi mật khẩu',
            subtitle: 'Cập nhật mật khẩu để bảo vệ tài khoản của bạn',
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Mật khẩu mới cần từ 6 ký tự và khác mật khẩu cũ.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _passwordField(
            controller: _oldCtrl,
            label: 'Mật khẩu cũ',
            icon: Icons.lock_outline_rounded,
            obscure: widget.viewModel.obscureOld,
            onToggle: widget.viewModel.toggleObscureOld,
          ),
          const SizedBox(height: 16),
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
          if (widget.viewModel.errorMessage != null) ...[
            const SizedBox(height: 16),
            AuthErrorBanner(message: widget.viewModel.errorMessage!),
          ],
          const SizedBox(height: 20),
          AuthPrimaryButton(
            text: 'Đổi mật khẩu',
            isLoading: widget.viewModel.isLoading,
            onTap: _doChangePassword,
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
