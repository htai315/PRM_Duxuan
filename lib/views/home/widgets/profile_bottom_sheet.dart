import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/routes/app_routes.dart';
import 'package:du_xuan/routes/route_args.dart';
import 'package:du_xuan/viewmodels/home/home_viewmodel.dart';

class ProfileBottomSheet extends StatelessWidget {
  final HomeViewModel viewModel;
  final VoidCallback onLogout;

  const ProfileBottomSheet({
    super.key,
    required this.viewModel,
    required this.onLogout,
  });

  static Future<void> show(
    BuildContext context,
    HomeViewModel viewModel,
    VoidCallback onLogout,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          ProfileBottomSheet(viewModel: viewModel, onLogout: onLogout),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = viewModel.session?.user;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDeep],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user != null ? user.fullName[0].toUpperCase() : '?',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? '...',
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '@${user?.userName ?? '...'}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryDeep,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _menuItem(
            icon: Icons.lock_outline_rounded,
            title: 'Đổi mật khẩu',
            onTap: () {
              Navigator.pop(context);
              final userId = viewModel.session?.user.id;
              if (userId != null) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.changePassword,
                  arguments: ChangePasswordRouteArgs(userId: userId),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _menuItem(
            icon: Icons.logout_rounded,
            title: 'Đăng xuất',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.error.withValues(alpha: 0.05)
              : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDestructive
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isDestructive ? AppColors.error : AppColors.textMedium,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isDestructive ? AppColors.error : AppColors.textDark,
                ),
              ),
            ),
            if (!isDestructive)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textLight,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
