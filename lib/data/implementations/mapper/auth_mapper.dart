import 'package:du_xuan/data/dtos/login/login_response_dto.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/domain/entities/auth_session.dart';
import 'package:du_xuan/domain/entities/user.dart';

/// Chuyển LoginResponseDto → AuthSession entity
class AuthSessionMapper implements IMapper<LoginResponseDto, AuthSession> {
  @override
  AuthSession map(LoginResponseDto input) {
    return AuthSession(
      token: input.token,
      user: User(
        id: input.user.id,
        userName: input.user.userName,
        fullName: input.user.fullName,
        createdAt: DateTime.parse(input.user.createdAt),
      ),
    );
  }
}
