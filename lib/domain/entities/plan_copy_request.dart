import 'package:du_xuan/core/enums/plan_copy_request_status.dart';

class PlanCopyRequest {
  final int id;
  final int sourcePlanId;
  final int sourceUserId;
  final int targetUserId;
  final int? targetPlanId;
  final PlanCopyRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const PlanCopyRequest({
    required this.id,
    required this.sourcePlanId,
    required this.sourceUserId,
    required this.targetUserId,
    this.targetPlanId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  bool get isPending => status == PlanCopyRequestStatus.pending;
  bool get isAccepted => status == PlanCopyRequestStatus.accepted;
  bool get isRejected => status == PlanCopyRequestStatus.rejected;
}
