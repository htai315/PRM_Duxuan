import 'package:du_xuan/data/dtos/share/plan_copy_source_dto.dart';
import 'package:du_xuan/data/interfaces/api/i_plan_copy_source_api.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/data/interfaces/repositories/i_plan_copy_source_repository.dart';
import 'package:du_xuan/domain/entities/plan_copy_source.dart';

class PlanCopySourceRepository implements IPlanCopySourceRepository {
  final IPlanCopySourceApi _api;
  final IMapper<PlanCopySourceDto, PlanCopySource> _mapper;

  PlanCopySourceRepository({
    required IPlanCopySourceApi api,
    required IMapper<PlanCopySourceDto, PlanCopySource> mapper,
  }) : _api = api,
       _mapper = mapper;

  @override
  Future<PlanCopySource?> getByTargetPlanId(int targetPlanId) async {
    final dto = await _api.getByTargetPlanId(targetPlanId);
    if (dto == null) return null;
    return _mapper.map(dto);
  }
}
