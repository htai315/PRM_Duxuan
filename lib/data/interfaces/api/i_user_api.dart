import 'package:du_xuan/data/dtos/login/user_dto.dart';

abstract class IUserApi {
  Future<UserDto?> getById(int id);
  Future<List<UserDto>> getAll({int? excludeUserId});
  Future<List<UserDto>> search(
    String query, {
    int? excludeUserId,
    int limit = 20,
  });
}
