import 'package:du_xuan/data/dtos/login/user_dto.dart';
import 'package:du_xuan/data/interfaces/mapper/imapper.dart';
import 'package:du_xuan/domain/entities/user.dart';

class UserMapper implements IMapper<UserDto, User> {
  @override
  User map(UserDto input) {
    return User(
      id: input.id,
      userName: input.userName,
      fullName: input.fullName,
      createdAt: DateTime.tryParse(input.createdAt) ?? DateTime.now(),
    );
  }
}
