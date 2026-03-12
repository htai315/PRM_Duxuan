class ChecklistItemDto {
  final int? id;
  final int planId;
  final String name;
  final int quantity;
  final String category;
  final String? note;
  final int priority;
  final int isPacked; // 0 or 1
  final String source;
  final int? linkedActivityId;
  final String? suggestedLevel;

  const ChecklistItemDto({
    this.id,
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

  factory ChecklistItemDto.fromMap(Map<String, dynamic> map) {
    return ChecklistItemDto(
      id: map['id'] as int?,
      planId: map['plan_id'] as int,
      name: (map['name'] ?? '').toString(),
      quantity: (map['quantity'] as int?) ?? 1,
      category: (map['category'] ?? 'OTHER').toString(),
      note: map['note']?.toString(),
      priority: (map['priority'] as int?) ?? 0,
      isPacked: (map['is_packed'] as int?) ?? 0,
      source: (map['source'] ?? 'MANUAL').toString(),
      linkedActivityId: map['linked_activity_id'] as int?,
      suggestedLevel: map['suggested_level']?.toString(),
    );
  }

}

