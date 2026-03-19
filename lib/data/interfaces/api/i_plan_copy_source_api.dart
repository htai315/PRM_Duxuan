import 'package:du_xuan/data/dtos/share/plan_copy_source_dto.dart';

abstract class IPlanCopySourceApi {
  Future<PlanCopySourceDto?> getByTargetPlanId(int targetPlanId);
}
