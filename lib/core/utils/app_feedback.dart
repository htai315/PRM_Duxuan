import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';

enum AppFeedbackType { success, error, info, warning }

class AppFeedback {
  AppFeedback._();

  static void showSuccessSnack(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    showSnack(
      context,
      message: message,
      type: AppFeedbackType.success,
      duration: duration,
    );
  }

  static void showErrorSnack(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    showSnack(
      context,
      message: message,
      type: AppFeedbackType.error,
      duration: duration,
    );
  }

  static void showInfoSnack(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    showSnack(
      context,
      message: message,
      type: AppFeedbackType.info,
      duration: duration,
    );
  }

  static void showWarningSnack(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    showSnack(
      context,
      message: message,
      type: AppFeedbackType.warning,
      duration: duration,
    );
  }

  static void showSnack(
    BuildContext context, {
    required String message,
    required AppFeedbackType type,
    Duration duration = const Duration(seconds: 2),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_icon(type), color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _backgroundColor(type),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: duration,
      ),
    );
  }

  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Xác nhận',
    String cancelText = 'Hủy',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: AppTextStyles.titleMedium),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              cancelText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: destructive ? AppColors.error : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  static Future<bool> showDiscardChangesDialog({
    required BuildContext context,
    String title = 'Bỏ thay đổi chưa lưu?',
    String message = 'Nếu thoát bây giờ, dữ liệu bạn vừa nhập sẽ bị mất.',
    String confirmText = 'Thoát',
    String cancelText = 'Ở lại',
  }) {
    return showConfirmDialog(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      destructive: true,
    );
  }

  static Color _backgroundColor(AppFeedbackType type) {
    switch (type) {
      case AppFeedbackType.success:
        return AppColors.success;
      case AppFeedbackType.error:
        return AppColors.error;
      case AppFeedbackType.info:
        return AppColors.primary;
      case AppFeedbackType.warning:
        return AppColors.goldDeep;
    }
  }

  static IconData _icon(AppFeedbackType type) {
    switch (type) {
      case AppFeedbackType.success:
        return Icons.check_circle_rounded;
      case AppFeedbackType.error:
        return Icons.error_outline_rounded;
      case AppFeedbackType.info:
        return Icons.info_outline_rounded;
      case AppFeedbackType.warning:
        return Icons.warning_amber_rounded;
    }
  }
}
