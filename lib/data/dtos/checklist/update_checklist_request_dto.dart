/// DTO ghi — dùng khi cập nhật ChecklistItem.
class UpdateChecklistRequestDto {
  final int id;
  final int planId;
  final String name;
  final int quantity;
  final String category;
  final String? note;
  final int priority;
  final int isPacked;
  final String source;
  final int? linkedActivityId;
  final String? suggestedLevel;

  const UpdateChecklistRequestDto({
    required this.id,
    required this.planId,
    required this.name,
    this.quantity = 1,
    this.category = 'OTHER',
    this.note,
    this.priority = 0,
    this.isPacked = 0,
    this.source = 'MANUAL',
    this.linkedActivityId,
    this.suggestedLevel,
  });

  Map<String, dynamic> toMap() => {
    'plan_id': planId,
    'name': name,
    'quantity': quantity,
    'category': category,
    'note': note,
    'priority': priority,
    'is_packed': isPacked,
    'source': source,
    'linked_activity_id': linkedActivityId,
    'suggested_level': suggestedLevel,
  };
}
