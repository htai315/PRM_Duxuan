import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/routes/app_routes.dart';
import 'package:du_xuan/viewmodels/login/login_viewmodel.dart';
import 'package:du_xuan/views/auth/widgets/auth_ui.dart';

class LoginPage extends StatefulWidget {
  final LoginViewModel viewModel;
  const LoginPage({super.key, required this.viewModel});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
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
    _passCtrl.dispose();
    _formAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
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
            icon: Icons.temple_buddhist_rounded,
            title: 'Du Xuân',
            subtitle: 'Chào mừng trở lại, lên kế hoạch chuyến đi của bạn',
            caption: 'PLANNER',
          ),
          const SizedBox(height: 24),
          AuthInputField(
            controller: _userCtrl,
            hint: 'Tên đăng nhập',
            icon: Icons.person_rounded,
            textInputAction: TextInputAction.next,
            onChanged: (_) => widget.viewModel.clearError(),
          ),
          const SizedBox(height: 12),
          AuthInputField(
            controller: _passCtrl,
            hint: 'Mật khẩu',
            icon: Icons.lock_rounded,
            obscureText: widget.viewModel.obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _doLogin(),
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
          if (widget.viewModel.errorMessage != null) ...[
            const SizedBox(height: 14),
            AuthErrorBanner(message: widget.viewModel.errorMessage!),
          ],
          const SizedBox(height: 20),
          AuthPrimaryButton(
            text: 'Đăng nhập',
            isLoading: widget.viewModel.isLoading,
            onTap: _doLogin,
          ),
          const SizedBox(height: 16),
          AuthLinkRow(
            leadingText: 'Chưa có tài khoản? ',
            linkText: 'Đăng ký',
            onTap: () => Navigator.pushNamed(context, AppRoutes.register),
          ),
        ],
      ),
    );
  }

  Future<void> _doLogin() async {
    final session = await widget.viewModel.login(
      _userCtrl.text,
      _passCtrl.text,
    );
    if (session != null && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }
}
