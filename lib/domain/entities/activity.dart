import 'package:du_xuan/core/enums/activity_status.dart';
import 'package:du_xuan/core/enums/activity_type.dart';

class Activity {
  final int id;
  final int planDayId;
  final String title;
  final ActivityType activityType;
  final String? startTime;
  final String? endTime;
  final int? destinationId;
  final String? locationText;
  final String? note;
  final double? estimatedCost;
  final int priority;
  final int orderIndex;
  final ActivityStatus status;

  const Activity({
    required this.id,
    required this.planDayId,
    required this.title,
    required this.activityType,
    this.startTime,
    this.endTime,
    this.destinationId,
    this.locationText,
    this.note,
    this.estimatedCost,
    this.priority = 0,
    this.orderIndex = 0,
    required this.status,
  });

  Activity copyWith({
    int? id,
    int? planDayId,
    String? title,
    ActivityType? activityType,
    String? startTime,
    String? endTime,
    int? destinationId,
    String? locationText,
    String? note,
    double? estimatedCost,
    int? priority,
    int? orderIndex,
    ActivityStatus? status,
  }) {
    return Activity(
      id: id ?? this.id,
      planDayId: planDayId ?? this.planDayId,
      title: title ?? this.title,
      activityType: activityType ?? this.activityType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      destinationId: destinationId ?? this.destinationId,
      locationText: locationText ?? this.locationText,
      note: note ?? this.note,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      priority: priority ?? this.priority,
      orderIndex: orderIndex ?? this.orderIndex,
      status: status ?? this.status,
    );
  }
}
