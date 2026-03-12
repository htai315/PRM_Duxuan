import 'package:du_xuan/data/dtos/login/user_dto.dart';

class LoginResponseDto {
  final String token;
  final UserDto user;

  const LoginResponseDto({
    required this.token,
    required this.user,
  });
}
