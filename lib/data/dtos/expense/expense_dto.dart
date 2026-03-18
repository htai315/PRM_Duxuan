class ExpenseDto {
  final int? id;
  final int planId;
  final int? planDayId;
  final int? activityId;
  final String title;
  final double amount;
  final String category;
  final String? note;
  final String spentAt;
  final String createdAt;
  final String updatedAt;
  final String source;

  const ExpenseDto({
    this.id,
    required this.planId,
    this.planDayId,
    this.activityId,
    required this.title,
    required this.amount,
    this.category = 'OTHER',
    this.note,
    required this.spentAt,
    required this.createdAt,
    required this.updatedAt,
    this.source = 'MANUAL',
  });

  factory ExpenseDto.fromMap(Map<String, dynamic> map) {
    return ExpenseDto(
      id: map['id'] as int?,
      planId: map['plan_id'] as int,
      planDayId: map['plan_day_id'] as int?,
      activityId: map['activity_id'] as int?,
      title: (map['title'] ?? '').toString(),
      amount: (map['amount'] as num).toDouble(),
      category: (map['category'] ?? 'OTHER').toString(),
      note: map['note']?.toString(),
      spentAt: (map['spent_at'] ?? '').toString(),
      createdAt: (map['created_at'] ?? '').toString(),
      updatedAt: (map['updated_at'] ?? '').toString(),
      source: (map['source'] ?? 'MANUAL').toString(),
    );
  }
}
