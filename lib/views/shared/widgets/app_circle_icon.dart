import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';

class AppCircleIconSurface extends StatelessWidget {
  final IconData icon;
  final double boxSize;
  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final double borderWidth;

  const AppCircleIconSurface({
    super.key,
    required this.icon,
    this.boxSize = 42,
    this.iconSize = 18,
    this.backgroundColor = AppColors.white,
    this.iconColor = AppColors.textDark,
    this.borderColor,
    this.boxShadow,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
        boxShadow: boxShadow,
      ),
      child: Icon(icon, size: iconSize, color: iconColor),
    );
  }
}

class AppCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double boxSize;
  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final double borderWidth;

  const AppCircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.boxSize = 42,
    this.iconSize = 18,
    this.backgroundColor = AppColors.white,
    this.iconColor = AppColors.textDark,
    this.borderColor,
    this.boxShadow,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AppCircleIconSurface(
          icon: icon,
          boxSize: boxSize,
          iconSize: iconSize,
          backgroundColor: backgroundColor,
          iconColor: iconColor,
          borderColor: borderColor,
          boxShadow: boxShadow,
          borderWidth: borderWidth,
        ),
      ),
    );
  }
}
