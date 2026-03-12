import 'package:du_xuan/data/dtos/checklist/checklist_item_dto.dart';
import 'package:du_xuan/data/dtos/checklist/create_checklist_request_dto.dart';
import 'package:du_xuan/data/dtos/checklist/update_checklist_request_dto.dart';
import 'package:du_xuan/data/interfaces/api/i_checklist_api.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/data/interfaces/repositories/i_checklist_repository.dart';
import 'package:du_xuan/domain/entities/checklist_item.dart';

class ChecklistRepository implements IChecklistRepository {
  final IChecklistApi _api;
  final IMapper<ChecklistItemDto, ChecklistItem> _mapper;

  ChecklistRepository({
    required IChecklistApi api,
    required IMapper<ChecklistItemDto, ChecklistItem> mapper,
  })  : _api = api,
        _mapper = mapper;

  @override
  Future<List<ChecklistItem>> getByPlanId(int planId) async {
    final dtos = await _api.getByPlanId(planId);
    return dtos.map(_mapper.map).toList();
  }

  @override
  Future<ChecklistItem> create(ChecklistItem item) async {
    final req = CreateChecklistRequestDto(
      planId: item.planId,
      name: item.name,
      quantity: item.quantity,
      category: item.category.name.toUpperCase(),
      note: item.note,
      priority: item.priority,
      isPacked: item.isPacked ? 1 : 0,
      source: item.source.name.toUpperCase(),
      linkedActivityId: item.linkedActivityId,
      suggestedLevel: item.suggestedLevel,
    );

    final id = await _api.create(req);
    final created = await _api.getById(id);
    return _mapper.map(created!);
  }

  @override
  Future<void> update(ChecklistItem item) async {
    final req = UpdateChecklistRequestDto(
      id: item.id,
      planId: item.planId,
      name: item.name,
      quantity: item.quantity,
      category: item.category.name.toUpperCase(),
      note: item.note,
      priority: item.priority,
      isPacked: item.isPacked ? 1 : 0,
      source: item.source.name.toUpperCase(),
      linkedActivityId: item.linkedActivityId,
      suggestedLevel: item.suggestedLevel,
    );
    await _api.update(req);
  }

  @override
  Future<void> delete(int id) async {
    await _api.delete(id);
  }

  @override
  Future<void> togglePacked(int id) async {
    await _api.togglePacked(id);
  }
}
