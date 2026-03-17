import 'package:flutter/material.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/enums/plan_status.dart';
import 'package:du_xuan/core/enums/plan_timeline_state.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/domain/entities/plan_activity_progress.dart';

class PlanUi {
  PlanUi._();

  static Color statusColor(Plan plan) {
    switch (plan.status) {
      case PlanStatus.completed:
        return AppColors.success;
      case PlanStatus.draft:
        return AppColors.textMedium;
      case PlanStatus.archived:
        return AppColors.textLight;
      case PlanStatus.active:
        switch (plan.timelineState) {
          case PlanTimelineState.upcoming:
            return AppColors.primary;
          case PlanTimelineState.ongoing:
            return AppColors.success;
          case PlanTimelineState.pastDue:
            return AppColors.goldDeep;
        }
    }
  }

  static IconData statusIcon(Plan plan) {
    switch (plan.status) {
      case PlanStatus.active:
        switch (plan.timelineState) {
          case PlanTimelineState.ongoing:
            return Icons.play_circle_fill_rounded;
          case PlanTimelineState.upcoming:
            return Icons.schedule_rounded;
          case PlanTimelineState.pastDue:
            return Icons.history_toggle_off_rounded;
        }
      case PlanStatus.completed:
        return Icons.check_circle_rounded;
      case PlanStatus.draft:
        return Icons.edit_note_rounded;
      case PlanStatus.archived:
        return Icons.archive_rounded;
    }
  }

  static String statusHint(Plan plan) {
    switch (plan.status) {
      case PlanStatus.active:
        switch (plan.timelineState) {
          case PlanTimelineState.ongoing:
            return 'Lịch trình đang hoạt động';
          case PlanTimelineState.upcoming:
            return 'Chuẩn bị khởi hành';
          case PlanTimelineState.pastDue:
            return 'Bạn có thể cập nhật lại ngày đi';
        }
      case PlanStatus.completed:
        return 'Hành trình đã hoàn tất';
      case PlanStatus.draft:
        return 'Kế hoạch đang ở trạng thái nháp';
      case PlanStatus.archived:
        return 'Kế hoạch đã được lưu trữ';
    }
  }

  static String progressCaption(
    Plan plan,
    PlanActivityProgress activityProgress,
  ) {
    switch (plan.status) {
      case PlanStatus.completed:
        return 'Tất cả hoạt động đã hoàn thành';
      case PlanStatus.draft:
        return 'Kế hoạch nháp chưa bắt đầu';
      case PlanStatus.archived:
        return 'Kế hoạch đã lưu trữ';
      case PlanStatus.active:
        if (activityProgress.totalActivities <= 0) {
          return 'Chưa có hoạt động nào';
        }
        if (activityProgress.completedActivities >=
            activityProgress.totalActivities) {
          return 'Tất cả hoạt động đã hoàn thành';
        }
        return 'Hoàn thành ${activityProgress.completedActivities}/${activityProgress.totalActivities} hoạt động';
    }
  }
}
