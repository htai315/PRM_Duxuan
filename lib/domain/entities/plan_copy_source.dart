class PlanCopySource {
  final int id;
  final int sourcePlanId;
  final int sourceUserId;
  final int targetPlanId;
  final int targetUserId;
  final String sourceUserName;
  final String sourceUserFullName;
  final DateTime createdAt;

  const PlanCopySource({
    required this.id,
    required this.sourcePlanId,
    required this.sourceUserId,
    required this.targetPlanId,
    required this.targetUserId,
    required this.sourceUserName,
    required this.sourceUserFullName,
    required this.createdAt,
  });

  String get sourceDisplayName {
    final fullName = sourceUserFullName.trim();
    if (fullName.isNotEmpty) return fullName;
    return sourceUserName.trim();
  }
}
