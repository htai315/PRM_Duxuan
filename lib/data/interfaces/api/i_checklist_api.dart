import 'package:du_xuan/data/dtos/checklist/checklist_item_dto.dart';
import 'package:du_xuan/data/dtos/checklist/create_checklist_request_dto.dart';
import 'package:du_xuan/data/dtos/checklist/update_checklist_request_dto.dart';

abstract class IChecklistApi {
  Future<List<ChecklistItemDto>> getByPlanId(int planId);
  Future<ChecklistItemDto?> getById(int id);
  Future<int> create(CreateChecklistRequestDto req);
  Future<void> update(UpdateChecklistRequestDto req);
  Future<void> delete(int id);
  Future<void> togglePacked(int id);
}
