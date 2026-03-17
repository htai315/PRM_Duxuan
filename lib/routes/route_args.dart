import 'package:du_xuan/domain/entities/activity.dart';

class PlanCreateRouteArgs {
  final int userId;

  const PlanCreateRouteArgs({required this.userId});
}

class PlanEditRouteArgs {
  final int planId;

  const PlanEditRouteArgs({required this.planId});
}

class ItineraryRouteArgs {
  final int planId;

  const ItineraryRouteArgs({required this.planId});
}

class ActivityCreateRouteArgs {
  final int planDayId;

  const ActivityCreateRouteArgs({required this.planDayId});
}

class ActivityEditRouteArgs {
  final Activity activity;

  const ActivityEditRouteArgs({required this.activity});
}

class ChecklistRouteArgs {
  final int planId;
  final String planName;

  const ChecklistRouteArgs({required this.planId, required this.planName});
}

class ChangePasswordRouteArgs {
  final int userId;

  const ChangePasswordRouteArgs({required this.userId});
}

class NotificationsRouteArgs {
  final int userId;

  const NotificationsRouteArgs({required this.userId});
}
