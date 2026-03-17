import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/enums/notification_type.dart';
import 'package:du_xuan/domain/entities/app_notification.dart';

class NotificationUi {
  NotificationUi._();

  static Color typeColor(NotificationType type) {
    switch (type) {
      case NotificationType.reminder:
        return AppColors.primary;
      case NotificationType.system:
        return AppColors.goldDeep;
    }
  }

  static IconData typeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.reminder:
        return Icons.notifications_active_rounded;
      case NotificationType.system:
        return Icons.info_outline_rounded;
    }
  }

  static String formatWhen(AppNotification item) {
    final date = item.scheduledAt ?? item.createdAt;
    return DateFormat('HH:mm • dd/MM/yyyy').format(date);
  }
}
