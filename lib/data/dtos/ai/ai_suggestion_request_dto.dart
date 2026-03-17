import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';
import 'package:intl/intl.dart';

class AiSuggestionRequestDto {
  final AiSuggestionPlanDto plan;
  final List<AiSuggestionDayDto> days;
  final List<String> existingItemNames;

  const AiSuggestionRequestDto({
    required this.plan,
    required this.days,
    required this.existingItemNames,
  });

  factory AiSuggestionRequestDto.fromDomain({
    required Plan plan,
    required Map<PlanDay, List<Activity>> activitiesByDay,
    required List<String> existingItemNames,
  }) {
    final dateFmt = DateFormat('dd/MM');
    final sortedDays = activitiesByDay.keys.toList()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    return AiSuggestionRequestDto(
      plan: AiSuggestionPlanDto.fromDomain(plan, dateFmt),
      days: sortedDays
          .map(
            (day) => AiSuggestionDayDto.fromDomain(
              day,
              activitiesByDay[day] ?? const <Activity>[],
              dateFmt,
            ),
          )
          .toList(),
      existingItemNames: List.unmodifiable(existingItemNames),
    );
  }

  Map<String, dynamic> toJson() => {
    'plan': plan.toJson(),
    'days': days.map((day) => day.toJson()).toList(),
    'existingItemNames': existingItemNames,
  };
}

class AiSuggestionPlanDto {
  final int id;
  final String name;
  final String? description;
  final String? participants;
  final String? note;
  final String startDate;
  final String endDate;
  final int totalDays;
  final String displayDateRange;

  const AiSuggestionPlanDto({
    required this.id,
    required this.name,
    required this.description,
    required this.participants,
    required this.note,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.displayDateRange,
  });

  factory AiSuggestionPlanDto.fromDomain(Plan plan, DateFormat dateFmt) {
    return AiSuggestionPlanDto(
      id: plan.id,
      name: plan.name,
      description: plan.description,
      participants: plan.participants,
      note: plan.note,
      startDate: plan.startDate.toIso8601String(),
      endDate: plan.endDate.toIso8601String(),
      totalDays: plan.totalDays,
      displayDateRange:
          '${dateFmt.format(plan.startDate)} - ${dateFmt.format(plan.endDate)}',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'participants': participants,
    'note': note,
    'startDate': startDate,
    'endDate': endDate,
    'totalDays': totalDays,
    'displayDateRange': displayDateRange,
  };
}

class AiSuggestionDayDto {
  final int id;
  final int dayNumber;
  final String date;
  final String displayDate;
  final List<AiSuggestionActivityDto> activities;

  const AiSuggestionDayDto({
    required this.id,
    required this.dayNumber,
    required this.date,
    required this.displayDate,
    required this.activities,
  });

  factory AiSuggestionDayDto.fromDomain(
    PlanDay day,
    List<Activity> activities,
    DateFormat dateFmt,
  ) {
    return AiSuggestionDayDto(
      id: day.id,
      dayNumber: day.dayNumber,
      date: day.date.toIso8601String(),
      displayDate: dateFmt.format(day.date),
      activities: activities
          .map(AiSuggestionActivityDto.fromDomain)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayNumber': dayNumber,
    'date': date,
    'displayDate': displayDate,
    'activities': activities.map((activity) => activity.toJson()).toList(),
  };
}

class AiSuggestionActivityDto {
  final int id;
  final String title;
  final String activityType;
  final String activityTypeLabel;
  final String? startTime;
  final String? endTime;
  final String? locationText;
  final String? note;

  const AiSuggestionActivityDto({
    required this.id,
    required this.title,
    required this.activityType,
    required this.activityTypeLabel,
    required this.startTime,
    required this.endTime,
    required this.locationText,
    required this.note,
  });

  factory AiSuggestionActivityDto.fromDomain(Activity activity) {
    return AiSuggestionActivityDto(
      id: activity.id,
      title: activity.title,
      activityType: activity.activityType.name,
      activityTypeLabel: activity.activityType.label,
      startTime: activity.startTime,
      endTime: activity.endTime,
      locationText: activity.locationText,
      note: activity.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'activityType': activityType,
    'activityTypeLabel': activityTypeLabel,
    'startTime': startTime,
    'endTime': endTime,
    'locationText': locationText,
    'note': note,
  };
}
