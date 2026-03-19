import 'package:du_xuan/data/dtos/share/plan_copy_source_dto.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/domain/entities/plan_copy_source.dart';

class PlanCopySourceMapper
    implements IMapper<PlanCopySourceDto, PlanCopySource> {
  @override
  PlanCopySource map(PlanCopySourceDto input) {
    return PlanCopySource(
      id: input.id,
      sourcePlanId: input.sourcePlanId,
      sourceUserId: input.sourceUserId,
      targetPlanId: input.targetPlanId,
      targetUserId: input.targetUserId,
      sourceUserName: input.sourceUserName,
      sourceUserFullName: input.sourceUserFullName,
      createdAt: DateTime.tryParse(input.createdAt) ?? DateTime.now(),
    );
  }
}
