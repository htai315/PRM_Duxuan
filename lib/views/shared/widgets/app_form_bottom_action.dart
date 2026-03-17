import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';

class AppFormBottomAction extends StatelessWidget {
  final bool isDisabled;
  final bool isLoading;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const AppFormBottomAction({
    super.key,
    required this.isDisabled,
    required this.isLoading,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                  onTap: isDisabled ? null : onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: isLoading
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
                              Icon(icon, size: 20, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                label,
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
}
