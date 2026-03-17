class PlanActivityProgressDto {
  final int planId;
  final int totalActivities;
  final int completedActivities;

  const PlanActivityProgressDto({
    required this.planId,
    required this.totalActivities,
    required this.completedActivities,
  });

  factory PlanActivityProgressDto.fromMap(Map<String, dynamic> map) {
    return PlanActivityProgressDto(
      planId: map['plan_id'] as int,
      totalActivities: (map['total_activities'] as int?) ?? 0,
      completedActivities: (map['completed_activities'] as int?) ?? 0,
    );
  }
}
