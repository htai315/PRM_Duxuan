import 'package:du_xuan/data/dtos/login/login_request_dto.dart';
import 'package:du_xuan/data/dtos/login/login_response_dto.dart';
import 'package:du_xuan/data/dtos/login/register_request_dto.dart';
import 'package:du_xuan/data/interfaces/api/iauth_api.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/data/interfaces/repositories/iauth_repository.dart';
import 'package:du_xuan/domain/entities/auth_session.dart';

class AuthRepository implements IAuthRepository {
  final IAuthApi _api;
  final IMapper<LoginResponseDto, AuthSession> _mapper;

  AuthRepository({
    required IAuthApi api,
    required IMapper<LoginResponseDto, AuthSession> mapper,
  })  : _api = api,
        _mapper = mapper;

  @override
  Future<AuthSession> login(String userName, String password) async {
    final dto = await _api.login(
      LoginRequestDto(userName: userName, password: password),
    );
    return _mapper.map(dto);
  }

  @override
  Future<AuthSession> register(
    String userName,
    String fullName,
    String password,
  ) async {
    final dto = await _api.register(
      RegisterRequestDto(
        userName: userName,
        fullName: fullName,
        password: password,
      ),
    );
    return _mapper.map(dto);
  }

  @override
  Future<AuthSession?> getCurrentSession() async {
    final dto = await _api.getCurrentSession();
    if (dto == null) return null;
    return _mapper.map(dto);
  }

  @override
  Future<void> logout() => _api.logout();

  @override
  Future<void> changePassword(
    int userId,
    String oldPassword,
    String newPassword,
  ) => _api.changePassword(userId, oldPassword, newPassword);
}
