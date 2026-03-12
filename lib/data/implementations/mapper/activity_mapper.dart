import 'package:du_xuan/core/enums/activity_status.dart';
import 'package:du_xuan/core/enums/activity_type.dart';
import 'package:du_xuan/data/dtos/activity/activity_dto.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/domain/entities/activity.dart';

class ActivityMapper implements IMapper<ActivityDto, Activity> {
  @override
  Activity map(ActivityDto input) {
    return Activity(
      id: input.id ?? 0,
      planDayId: input.planDayId,
      title: input.title,
      activityType: ActivityType.fromString(input.activityType),
      startTime: input.startTime,
      endTime: input.endTime,
      destinationId: input.destinationId,
      locationText: input.locationText,
      note: input.note,
      estimatedCost: input.estimatedCost,
      priority: input.priority,
      orderIndex: input.orderIndex,
      status: ActivityStatus.fromString(input.status),
    );
  }
}
