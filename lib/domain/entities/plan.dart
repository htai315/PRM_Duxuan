import 'package:du_xuan/core/enums/plan_status.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';

class Plan {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final String? participants;
  final String? coverImage;
  final String? note;
  final PlanStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PlanDay> days;

  const Plan({
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
    required this.createdAt,
    required this.updatedAt,
    this.days = const [],
  });

  /// Số ngày trong kế hoạch
  int get totalDays => endDate.difference(startDate).inDays + 1;

  /// Trạng thái hiển thị (computed, không lưu DB)
  String get displayStatus {
    if (status == PlanStatus.completed) return 'Hoàn thành';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    if (today.isBefore(start)) return 'Sắp diễn ra';
    if (today.isAfter(end)) return 'Đã qua ngày';
    return 'Đang diễn ra';
  }

  /// Bản sao với thay đổi
  Plan copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? participants,
    String? coverImage,
    String? note,
    PlanStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PlanDay>? days,
  }) {
    return Plan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      participants: participants ?? this.participants,
      coverImage: coverImage ?? this.coverImage,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      days: days ?? this.days,
    );
  }
}
