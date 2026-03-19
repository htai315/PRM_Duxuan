class PlanCopySourceDto {
  final int id;
  final int sourcePlanId;
  final int sourceUserId;
  final int targetPlanId;
  final int targetUserId;
  final String sourceUserName;
  final String sourceUserFullName;
  final String createdAt;

  const PlanCopySourceDto({
    required this.id,
    required this.sourcePlanId,
    required this.sourceUserId,
    required this.targetPlanId,
    required this.targetUserId,
    required this.sourceUserName,
    required this.sourceUserFullName,
    required this.createdAt,
  });

  factory PlanCopySourceDto.fromMap(Map<String, dynamic> map) {
    return PlanCopySourceDto(
      id: map['id'] as int,
      sourcePlanId: map['source_plan_id'] as int,
      sourceUserId: map['source_user_id'] as int,
      targetPlanId: map['target_plan_id'] as int,
      targetUserId: map['target_user_id'] as int,
      sourceUserName: (map['source_user_name'] ?? '').toString(),
      sourceUserFullName: (map['source_user_full_name'] ?? '').toString(),
      createdAt: (map['created_at'] ?? '').toString(),
    );
  }
}
