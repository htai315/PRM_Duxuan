import 'package:du_xuan/core/enums/plan_status.dart';
import 'package:du_xuan/data/dtos/plan/plan_dto.dart';
import 'package:du_xuan/data/dtos/plan/plan_day_dto.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/domain/entities/plan.dart';
import 'package:du_xuan/domain/entities/plan_day.dart';

/// PlanDto → Plan entity
class PlanMapper implements IMapper<PlanDto, Plan> {
  @override
  Plan map(PlanDto input) {
    return Plan(
      id: input.id ?? 0,
      userId: input.userId,
      name: input.name,
      description: input.description,
      startDate: DateTime.parse(input.startDate),
      endDate: DateTime.parse(input.endDate),
      participants: input.participants,
      coverImage: input.coverImage,
      note: input.note,
      status: PlanStatus.fromString(input.status),
      createdAt: DateTime.parse(input.createdAt),
      updatedAt: DateTime.parse(input.updatedAt),
    );
  }
}

/// PlanDayDto → PlanDay entity
class PlanDayMapper implements IMapper<PlanDayDto, PlanDay> {
  @override
  PlanDay map(PlanDayDto input) {
    return PlanDay(
      id: input.id ?? 0,
      planId: input.planId,
      date: DateTime.parse(input.date),
      dayNumber: input.dayNumber,
    );
  }
}
