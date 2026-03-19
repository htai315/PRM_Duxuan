import 'package:du_xuan/domain/entities/plan_copy_request.dart';

abstract class IPlanCopyRepository {
  Future<int> createCopyRequest({
    required int sourcePlanId,
    required int sourceUserId,
    required int targetUserId,
  });

  Future<PlanCopyRequest?> getRequestById(int requestId);

  Future<List<PlanCopyRequest>> getRequestsByIds(List<int> requestIds);

  Future<int> acceptCopyRequest({
    required int requestId,
    required int targetUserId,
  });

  Future<void> rejectCopyRequest({
    required int requestId,
    required int targetUserId,
  });
}
