class PlanDto {
  final int? id;
  final int userId;
  final String name;
  final String? description;
  final String startDate;
  final String endDate;
  final String? participants;
  final String? coverImage;
  final String? note;
  final String status;
  final String createdAt;
  final String updatedAt;

  const PlanDto({
    this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    this.participants,
    this.coverImage,
    this.note,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlanDto.fromMap(Map<String, dynamic> map) {
    return PlanDto(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: (map['name'] ?? '').toString(),
      description: map['description']?.toString(),
      startDate: (map['start_date'] ?? '').toString(),
      endDate: (map['end_date'] ?? '').toString(),
      participants: map['participants']?.toString(),
      coverImage: map['cover_image']?.toString(),
      note: map['note']?.toString(),
      status: (map['status'] ?? 'draft').toString(),
      createdAt: (map['created_at'] ?? '').toString(),
      updatedAt: (map['updated_at'] ?? '').toString(),
    );
  }

}

