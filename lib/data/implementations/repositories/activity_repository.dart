import 'package:du_xuan/data/dtos/activity/activity_dto.dart';
import 'package:du_xuan/data/dtos/activity/create_activity_request_dto.dart';
import 'package:du_xuan/data/dtos/activity/update_activity_request_dto.dart';
import 'package:du_xuan/data/interfaces/api/i_activity_api.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/data/interfaces/repositories/i_activity_repository.dart';
import 'package:du_xuan/domain/entities/activity.dart';

class ActivityRepository implements IActivityRepository {
  final IActivityApi _api;
  final IMapper<ActivityDto, Activity> _mapper;

  ActivityRepository({
    required IActivityApi api,
    required IMapper<ActivityDto, Activity> mapper,
  })  : _api = api,
        _mapper = mapper;

  @override
  Future<List<Activity>> getByPlanDayId(int planDayId) async {
    final dtos = await _api.getByPlanDayId(planDayId);
    return dtos.map(_mapper.map).toList();
  }

  @override
  Future<Activity> create(Activity activity) async {
    // Auto order_index = max + 1
    final existing = await _api.getByPlanDayId(activity.planDayId);
    final maxOrder = existing.isEmpty
        ? 0
        : existing.map((e) => e.orderIndex).reduce((a, b) => a > b ? a : b);

    final req = CreateActivityRequestDto(
      planDayId: activity.planDayId,
      title: activity.title,
      activityType: activity.activityType.name.toUpperCase(),
      startTime: activity.startTime,
      endTime: activity.endTime,
      destinationId: activity.destinationId,
      locationText: activity.locationText,
      note: activity.note,
      estimatedCost: activity.estimatedCost,
      priority: activity.priority,
      orderIndex: maxOrder + 1,
      status: activity.status.name.toUpperCase(),
    );

    final id = await _api.create(req);
    final created = await _api.getById(id);
    return _mapper.map(created!);
  }

  @override
  Future<void> update(Activity activity) async {
    final req = UpdateActivityRequestDto(
      id: activity.id,
      planDayId: activity.planDayId,
      title: activity.title,
      activityType: activity.activityType.name.toUpperCase(),
      startTime: activity.startTime,
      endTime: activity.endTime,
      destinationId: activity.destinationId,
      locationText: activity.locationText,
      note: activity.note,
      estimatedCost: activity.estimatedCost,
      priority: activity.priority,
      orderIndex: activity.orderIndex,
      status: activity.status.name.toUpperCase(),
    );
    await _api.update(req);
  }

  @override
  Future<void> delete(int id) async {
    await _api.delete(id);
  }

  @override
  Future<void> toggleStatus(int id) async {
    final dto = await _api.getById(id);
    if (dto == null) return;

    final current = dto.status.toUpperCase();
    final newStatus = current == 'DONE' ? 'TODO' : 'DONE';

    final req = UpdateActivityRequestDto(
      id: dto.id!,
      planDayId: dto.planDayId,
      title: dto.title,
      activityType: dto.activityType,
      startTime: dto.startTime,
      endTime: dto.endTime,
      destinationId: dto.destinationId,
      locationText: dto.locationText,
      note: dto.note,
      estimatedCost: dto.estimatedCost,
      priority: dto.priority,
      orderIndex: dto.orderIndex,
      status: newStatus,
    );
    await _api.update(req);
  }
}
