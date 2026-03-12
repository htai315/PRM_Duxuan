class ActivityDto {
  final int? id;
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

  const ActivityDto({
    this.id,
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

  factory ActivityDto.fromMap(Map<String, dynamic> map) {
    return ActivityDto(
      id: map['id'] as int?,
      planDayId: map['plan_day_id'] as int,
      title: (map['title'] ?? '').toString(),
      activityType: (map['activity_type'] ?? 'OTHER').toString(),
      startTime: map['start_time']?.toString(),
      endTime: map['end_time']?.toString(),
      destinationId: map['destination_id'] as int?,
      locationText: map['location_text']?.toString(),
      note: map['note']?.toString(),
      estimatedCost: map['estimated_cost'] != null
          ? (map['estimated_cost'] as num).toDouble()
          : null,
      priority: (map['priority'] as int?) ?? 0,
      orderIndex: (map['order_index'] as int?) ?? 0,
      status: (map['status'] ?? 'TODO').toString(),
    );
  }

}

