import 'package:du_xuan/core/enums/plan_copy_request_status.dart';
import 'package:du_xuan/data/dtos/share/plan_copy_request_dto.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/domain/entities/plan_copy_request.dart';

class PlanCopyRequestMapper
    implements IMapper<PlanCopyRequestDto, PlanCopyRequest> {
  @override
  PlanCopyRequest map(PlanCopyRequestDto input) {
    return PlanCopyRequest(
      id: input.id,
      sourcePlanId: input.sourcePlanId,
      sourceUserId: input.sourceUserId,
      targetUserId: input.targetUserId,
      targetPlanId: input.targetPlanId,
      status: PlanCopyRequestStatus.fromString(input.status),
      createdAt: DateTime.parse(input.createdAt),
      respondedAt: input.respondedAt == null
          ? null
          : DateTime.tryParse(input.respondedAt!),
    );
  }
}
