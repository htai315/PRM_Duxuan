import 'package:du_xuan/core/enums/checklist_category.dart';
import 'package:du_xuan/core/enums/checklist_source.dart';
import 'package:du_xuan/data/dtos/checklist/checklist_item_dto.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/domain/entities/checklist_item.dart';

class ChecklistMapper implements IMapper<ChecklistItemDto, ChecklistItem> {
  @override
  ChecklistItem map(ChecklistItemDto input) {
    return ChecklistItem(
      id: input.id ?? 0,
      planId: input.planId,
      name: input.name,
      quantity: input.quantity,
      category: ChecklistCategory.fromString(input.category),
      note: input.note,
      priority: input.priority,
      isPacked: input.isPacked == 1,
      source: ChecklistSource.fromString(input.source),
      linkedActivityId: input.linkedActivityId,
      suggestedLevel: input.suggestedLevel,
    );
  }
}
