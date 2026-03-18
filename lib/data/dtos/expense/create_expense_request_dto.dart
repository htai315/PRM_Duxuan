class CreateExpenseRequestDto {
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

  const CreateExpenseRequestDto({
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

  Map<String, dynamic> toMap() => {
    'plan_id': planId,
    'plan_day_id': planDayId,
    'activity_id': activityId,
    'title': title,
    'amount': amount,
    'category': category,
    'note': note,
    'spent_at': spentAt,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'source': source,
  };
}
