import 'package:du_xuan/core/enums/checklist_category.dart';
import 'package:du_xuan/core/enums/checklist_source.dart';

class ChecklistItem {
  final int id;
  final int planId;
  final String name;
  final int quantity;
  final ChecklistCategory category;
  final String? note;
  final int priority;
  final bool isPacked;
  final ChecklistSource source;
  final int? linkedActivityId;
  final String? suggestedLevel;

  const ChecklistItem({
    required this.id,
    required this.planId,
    required this.name,
    this.quantity = 1,
    this.category = ChecklistCategory.other,
    this.note,
    this.priority = 0,
    this.isPacked = false,
    this.source = ChecklistSource.manual,
    this.linkedActivityId,
    this.suggestedLevel,
  });

  ChecklistItem copyWith({
    int? id,
    int? planId,
    String? name,
    int? quantity,
    ChecklistCategory? category,
    String? note,
    int? priority,
    bool? isPacked,
    ChecklistSource? source,
    int? linkedActivityId,
    String? suggestedLevel,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      note: note ?? this.note,
      priority: priority ?? this.priority,
      isPacked: isPacked ?? this.isPacked,
      source: source ?? this.source,
      linkedActivityId: linkedActivityId ?? this.linkedActivityId,
      suggestedLevel: suggestedLevel ?? this.suggestedLevel,
    );
  }
}
