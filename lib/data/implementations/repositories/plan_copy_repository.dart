import 'package:du_xuan/data/dtos/share/plan_copy_request_dto.dart';
import 'package:du_xuan/data/interfaces/api/i_plan_copy_api.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_copy_repository.dart';
import 'package:du_xuan/domain/entities/plan_copy_request.dart';

class PlanCopyRepository implements IPlanCopyRepository {
  final IPlanCopyApi _api;
  final IMapper<PlanCopyRequestDto, PlanCopyRequest> _mapper;

  PlanCopyRepository({
    required IPlanCopyApi api,
    required IMapper<PlanCopyRequestDto, PlanCopyRequest> mapper,
  }) : _api = api,
       _mapper = mapper;

  @override
  Future<int> createCopyRequest({
    required int sourcePlanId,
    required int sourceUserId,
    required int targetUserId,
  }) {
    return _api.createCopyRequest(
      sourcePlanId: sourcePlanId,
      sourceUserId: sourceUserId,
      targetUserId: targetUserId,
    );
  }

  @override
  Future<PlanCopyRequest?> getRequestById(int requestId) async {
    final dto = await _api.getRequestById(requestId);
    if (dto == null) return null;
    return _mapper.map(dto);
  }

  @override
  Future<List<PlanCopyRequest>> getRequestsByIds(List<int> requestIds) async {
    final dtos = await _api.getRequestsByIds(requestIds);
    return dtos.map(_mapper.map).toList();
  }

  @override
  Future<int> acceptCopyRequest({
    required int requestId,
    required int targetUserId,
  }) {
    return _api.acceptCopyRequest(
      requestId: requestId,
      targetUserId: targetUserId,
    );
  }

  @override
  Future<void> rejectCopyRequest({
    required int requestId,
    required int targetUserId,
  }) {
    return _api.rejectCopyRequest(
      requestId: requestId,
      targetUserId: targetUserId,
    );
  }
}
