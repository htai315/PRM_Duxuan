import 'package:du_xuan/domain/entities/checklist_item.dart';

abstract class IChecklistRepository {
  Future<List<ChecklistItem>> getByPlanId(int planId);
  Future<ChecklistItem> create(ChecklistItem item);
  Future<void> update(ChecklistItem item);
  Future<void> delete(int id);
  Future<void> togglePacked(int id);
}
