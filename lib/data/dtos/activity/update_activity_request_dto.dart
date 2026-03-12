/// DTO ghi — dùng khi cập nhật Activity.
class UpdateActivityRequestDto {
  final int id;
  final int planDayId;
  final String title;
  final String activityType;
  final String? startTime;
  final String? endTime;
  final int? destinationId;
  final String? locationText;
  final String? note;
  final double? estimatedCost;
  final int priority;
  final int orderIndex;
  final String status;

  const UpdateActivityRequestDto({
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

  Map<String, dynamic> toMap() => {
    'plan_day_id': planDayId,
    'title': title,
    'activity_type': activityType,
    'start_time': startTime,
    'end_time': endTime,
    'destination_id': destinationId,
    'location_text': locationText,
    'note': note,
    'estimated_cost': estimatedCost,
    'priority': priority,
    'order_index': orderIndex,
    'status': status,
  };
}
