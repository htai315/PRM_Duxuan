class PlanCopyRequestDto {
  final int id;
  final int sourcePlanId;
  final int sourceUserId;
  final int targetUserId;
  final int? targetPlanId;
  final String status;
  final String createdAt;
  final String? respondedAt;

  const PlanCopyRequestDto({
    required this.id,
    required this.sourcePlanId,
    required this.sourceUserId,
    required this.targetUserId,
    this.targetPlanId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory PlanCopyRequestDto.fromMap(Map<String, dynamic> map) {
    return PlanCopyRequestDto(
      id: map['id'] as int? ?? 0,
      sourcePlanId: map['source_plan_id'] as int? ?? 0,
      sourceUserId: map['source_user_id'] as int? ?? 0,
      targetUserId: map['target_user_id'] as int? ?? 0,
      targetPlanId: map['target_plan_id'] as int?,
      status: (map['status'] ?? 'PENDING').toString(),
      createdAt: (map['created_at'] ?? '').toString(),
      respondedAt: map['responded_at']?.toString(),
    );
  }
}
