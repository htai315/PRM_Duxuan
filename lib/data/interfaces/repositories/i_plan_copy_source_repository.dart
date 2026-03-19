import 'package:du_xuan/domain/entities/plan_copy_source.dart';

abstract class IPlanCopySourceRepository {
  Future<PlanCopySource?> getByTargetPlanId(int targetPlanId);
}
