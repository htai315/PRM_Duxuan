import 'package:du_xuan/core/enums/plan_status.dart';
import 'package:du_xuan/core/enums/plan_timeline_state.dart';
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

  /// Trạng thái timeline tính từ ngày, độc lập với lifecycle status trong DB.
  PlanTimelineState get timelineState {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    if (today.isBefore(start)) return PlanTimelineState.upcoming;
    if (today.isAfter(end)) return PlanTimelineState.pastDue;
    return PlanTimelineState.ongoing;
  }

  String get timelineLabel => timelineState.label;

  /// Nhãn status hiển thị cho UI: lifecycle cho completed/draft/archived,
  /// timeline cho active.
  String get statusBadgeLabel {
    switch (status) {
      case PlanStatus.active:
        return timelineLabel;
      case PlanStatus.draft:
      case PlanStatus.completed:
      case PlanStatus.archived:
        return status.label;
    }
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
