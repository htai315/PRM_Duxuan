import 'package:du_xuan/data/dtos/login/user_dto.dart';
import 'package:du_xuan/data/interfaces/api/i_user_api.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/data/interfaces/repositories/i_user_repository.dart';
import 'package:du_xuan/domain/entities/user.dart';

class UserRepository implements IUserRepository {
  final IUserApi _api;
  final IMapper<UserDto, User> _mapper;

  UserRepository({
    required IUserApi api,
    required IMapper<UserDto, User> mapper,
  }) : _api = api,
       _mapper = mapper;

  @override
  Future<User?> getById(int id) async {
    final dto = await _api.getById(id);
    if (dto == null) return null;
    return _mapper.map(dto);
  }

  @override
  Future<List<User>> getAll({int? excludeUserId}) async {
    final dtos = await _api.getAll(excludeUserId: excludeUserId);
    return dtos.map(_mapper.map).toList();
  }

  @override
  Future<List<User>> search(
    String query, {
    int? excludeUserId,
    int limit = 20,
  }) async {
    final dtos = await _api.search(
      query,
      excludeUserId: excludeUserId,
      limit: limit,
    );
    return dtos.map(_mapper.map).toList();
  }
}
