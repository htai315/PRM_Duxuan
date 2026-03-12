class PlanDayDto {
  final int? id;
  final int planId;
  final String date;
  final int dayNumber;

  const PlanDayDto({
    this.id,
    required this.planId,
    required this.date,
    required this.dayNumber,
  });

  factory PlanDayDto.fromMap(Map<String, dynamic> map) {
    return PlanDayDto(
      id: map['id'] as int?,
      planId: map['plan_id'] as int,
      date: (map['date'] ?? '').toString(),
      dayNumber: map['day_number'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'plan_id': planId,
      'date': date,
      'day_number': dayNumber,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}
