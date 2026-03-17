import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/domain/entities/activity.dart';
import 'package:flutter/material.dart';

class DayDetailActivityNode extends StatelessWidget {
  final Activity activity;
  final bool isDone;
  final bool isViewMode;
  final bool isLast;
  final Color typeColor;
  final bool hasLocation;
  final String costLabel;
  final VoidCallback onOpenDetail;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final VoidCallback onOpenLocation;

  const DayDetailActivityNode({
    super.key,
    required this.activity,
    required this.isDone,
    required this.isViewMode,
    required this.isLast,
    required this.typeColor,
    required this.hasLocation,
    required this.costLabel,
    required this.onOpenDetail,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onOpenLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(activity.id),
      direction: isViewMode
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: AppColors.error,
          size: 28,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.whiteSoft.withValues(alpha: 0.9)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: AppColors.divider.withValues(alpha: 0.8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        activity.startTime ?? '--:--',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDone
                              ? AppColors.textMedium
                              : AppColors.textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      if (activity.endTime != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          activity.endTime!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.textLight.withValues(alpha: 0.5)
                        : typeColor,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isDone
                                    ? AppColors.textLight.withValues(alpha: 0.5)
                                    : typeColor)
                                .withValues(alpha: 0.32),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 2,
                    height: 108,
                    decoration: BoxDecoration(
                      color: (isDone ? AppColors.textLight : typeColor)
                          .withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: isDone ? 0.74 : 1,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onOpenDetail,
                  child: Ink(
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.whiteSoft.withValues(alpha: 0.92)
                          : AppColors.white.withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color:
                            (isDone
                                    ? AppColors.divider
                                    : typeColor.withValues(alpha: 0.12))
                                .withValues(alpha: 0.78),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity.title,
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: isDone
                                            ? AppColors.textMedium
                                            : AppColors.textDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16.5,
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (hasLocation) ...[
                                      const SizedBox(height: 7),
                                      GestureDetector(
                                        onTap: onOpenLocation,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.whiteSoft
                                                .withValues(alpha: 0.95),
                                            borderRadius: BorderRadius.circular(
                                              11,
                                            ),
                                            border: Border.all(
                                              color: AppColors.divider
                                                  .withValues(alpha: 0.8),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.place_rounded,
                                                size: 14,
                                                color: isDone
                                                    ? AppColors.textMedium
                                                    : typeColor,
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  activity.locationText!,
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                        color: AppColors
                                                            .textMedium,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 9),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _DetailBadge(
                                          icon: activity.activityType.icon,
                                          label: activity.activityType.label,
                                          color: isDone
                                              ? AppColors.textMedium
                                              : typeColor,
                                        ),
                                        if (activity.estimatedCost != null &&
                                            activity.estimatedCost! > 0)
                                          _DetailBadge(
                                            icon: Icons
                                                .account_balance_wallet_rounded,
                                            label: costLabel,
                                            color: isDone
                                                ? AppColors.textMedium
                                                : AppColors.goldDeep,
                                            bgColor: isDone
                                                ? AppColors.bgCream
                                                : AppColors.gold.withValues(
                                                    alpha: 0.15,
                                                  ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _StatusButton(
                                  isDone: isDone,
                                  isViewMode: isViewMode,
                                  onTap: onToggleStatus,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final bool isDone;
  final bool isViewMode;
  final VoidCallback onTap;

  const _StatusButton({
    required this.isDone,
    required this.isViewMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDone ? 'Hoan thanh' : 'Chua xong';
    final bgColor = isDone
        ? AppColors.success.withValues(alpha: 0.14)
        : AppColors.bgWarm.withValues(alpha: 0.96);
    final textColor = isDone ? AppColors.success : AppColors.primaryDeep;
    final borderColor = isDone
        ? AppColors.success.withValues(alpha: 0.32)
        : AppColors.primary.withValues(alpha: 0.18);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: isDone
                ? AppColors.success.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextButton(
        onPressed: isViewMode ? null : onTap,
        style: TextButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(0, 34),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          foregroundColor: textColor,
          disabledForegroundColor: textColor,
          backgroundColor: bgColor,
          disabledBackgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: borderColor, width: 1.15),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Row(
            key: ValueKey(text),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDone ? Icons.check_circle_rounded : Icons.timelapse_rounded,
                size: 14,
                color: textColor,
              ),
              const SizedBox(width: 5),
              Text(
                isDone ? 'Hoàn thành' : 'Chưa xong',
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: AppTextStyles.bodySmall.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? bgColor;

  const _DetailBadge({
    required this.icon,
    required this.label,
    required this.color,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor ?? color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
