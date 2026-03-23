import 'package:du_xuan/domain/entities/user.dart';

abstract class IUserRepository {
  Future<User?> getById(int id);
  Future<List<User>> getAll({int? excludeUserId});
  Future<List<User>> search(
    String query, {
    int? excludeUserId,
    int limit = 20,
  });
}
