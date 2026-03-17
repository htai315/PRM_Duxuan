import 'package:flutter/material.dart';
import 'package:du_xuan/viewmodels/register/register_viewmodel.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/routes/app_routes.dart';
import 'package:du_xuan/views/auth/widgets/auth_ui.dart';

class RegisterPage extends StatefulWidget {
  final RegisterViewModel viewModel;
  const RegisterPage({super.key, required this.viewModel});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  late AnimationController _formAnim;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    _formAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _formFade = CurvedAnimation(parent: _formAnim, curve: Curves.easeOutCubic);
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_formFade);
    _formAnim.forward();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _nameCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _formAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBackButton: true,
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: SlideTransition(
        position: _formSlide,
        child: FadeTransition(
          opacity: _formFade,
          child: ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, child) => _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return AuthPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AuthHeader(
            icon: Icons.person_add_rounded,
            title: 'Tạo tài khoản',
            subtitle: 'Đăng ký để bắt đầu hành trình du xuân',
            iconGradient: [AppColors.gold, AppColors.goldDeep],
            iconShadowColor: AppColors.gold,
          ),
          const SizedBox(height: 24),
          AuthInputField(
            controller: _userCtrl,
            hint: 'Tên đăng nhập',
            icon: Icons.alternate_email_rounded,
            textInputAction: TextInputAction.next,
            onChanged: (_) => widget.viewModel.clearError(),
          ),
          const SizedBox(height: 12),
          AuthInputField(
            controller: _nameCtrl,
            hint: 'Họ và tên',
            icon: Icons.badge_rounded,
            textInputAction: TextInputAction.next,
            onChanged: (_) => widget.viewModel.clearError(),
          ),
          const SizedBox(height: 12),
          AuthInputField(
            controller: _passCtrl,
            hint: 'Mật khẩu (tối thiểu 6 ký tự)',
            icon: Icons.lock_rounded,
            obscureText: widget.viewModel.obscurePassword,
            textInputAction: TextInputAction.next,
            onChanged: (_) => widget.viewModel.clearError(),
            suffixIcon: GestureDetector(
              onTap: widget.viewModel.toggleObscurePassword,
              child: Icon(
                widget.viewModel.obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.textLight,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AuthInputField(
            controller: _confirmCtrl,
            hint: 'Nhập lại mật khẩu',
            icon: Icons.lock_rounded,
            obscureText: widget.viewModel.obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _doRegister(),
            onChanged: (_) => widget.viewModel.clearError(),
            suffixIcon: GestureDetector(
              onTap: widget.viewModel.toggleObscureConfirmPassword,
              child: Icon(
                widget.viewModel.obscureConfirmPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.textLight,
                size: 20,
              ),
            ),
          ),
          if (widget.viewModel.errorMessage != null) ...[
            const SizedBox(height: 14),
            AuthErrorBanner(message: widget.viewModel.errorMessage!),
          ],
          const SizedBox(height: 20),
          AuthPrimaryButton(
            text: 'Đăng ký',
            isLoading: widget.viewModel.isLoading,
            onTap: _doRegister,
            gradientColors: const [AppColors.gold, AppColors.goldDeep],
            shadowColor: AppColors.gold,
          ),
          const SizedBox(height: 16),
          AuthLinkRow(
            leadingText: 'Đã có tài khoản? ',
            linkText: 'Đăng nhập',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _doRegister() async {
    final session = await widget.viewModel.register(
      _userCtrl.text,
      _nameCtrl.text,
      _passCtrl.text,
      _confirmCtrl.text,
    );
    if (session != null && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }
}
