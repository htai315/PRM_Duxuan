import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class DayDetailFab extends StatelessWidget {
  final VoidCallback onTap;
  final bool isExpenseOnly;

  const DayDetailFab({
    super.key,
    required this.onTap,
    this.isExpenseOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isExpenseOnly ? AppColors.goldDeep : AppColors.primary;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isExpenseOnly
                ? const [AppColors.gold, AppColors.goldDeep]
                : const [AppColors.primary, AppColors.primaryDeep],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: Center(
            child: Icon(
              isExpenseOnly ? Icons.receipt_long_rounded : Icons.add_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
