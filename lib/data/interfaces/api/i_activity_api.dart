import 'package:du_xuan/data/dtos/activity/activity_dto.dart';
import 'package:du_xuan/data/dtos/activity/create_activity_request_dto.dart';
import 'package:du_xuan/data/dtos/activity/update_activity_request_dto.dart';

abstract class IActivityApi {
  Future<List<ActivityDto>> getByPlanDayId(int planDayId);
  Future<ActivityDto?> getById(int id);
  Future<int> create(CreateActivityRequestDto req);
  Future<void> update(UpdateActivityRequestDto req);
  Future<void> delete(int id);
}
