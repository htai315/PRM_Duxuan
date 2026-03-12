/// DTO ghi — dùng khi tạo Plan mới.
class CreatePlanRequestDto {
  final int userId;
  final String name;
  final String? description;
  final String startDate;
  final String endDate;
  final String? participants;
  final String? coverImage;
  final String? note;
  final String status;

  const CreatePlanRequestDto({
    required this.userId,
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    this.participants,
    this.coverImage,
    this.note,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'name': name,
    'description': description,
    'start_date': startDate,
    'end_date': endDate,
    'participants': participants,
    'cover_image': coverImage,
    'note': note,
    'status': status,
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  };
}
