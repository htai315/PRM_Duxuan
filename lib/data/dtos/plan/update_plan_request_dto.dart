/// DTO ghi — dùng khi cập nhật Plan.
class UpdatePlanRequestDto {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final String startDate;
  final String endDate;
  final String? participants;
  final String? coverImage;
  final String? note;
  final String status;

  const UpdatePlanRequestDto({
    required this.id,
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
    'updated_at': DateTime.now().toIso8601String(),
  };
}
