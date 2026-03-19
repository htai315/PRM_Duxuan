import 'package:du_xuan/data/dtos/share/plan_copy_request_dto.dart';

abstract class IPlanCopyApi {
  Future<int> createCopyRequest({
    required int sourcePlanId,
    required int sourceUserId,
    required int targetUserId,
  });

  Future<PlanCopyRequestDto?> getRequestById(int requestId);

  Future<List<PlanCopyRequestDto>> getRequestsByIds(List<int> requestIds);

  Future<int> acceptCopyRequest({
    required int requestId,
    required int targetUserId,
  });

  Future<void> rejectCopyRequest({
    required int requestId,
    required int targetUserId,
  });
}
