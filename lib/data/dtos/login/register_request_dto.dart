class RegisterRequestDto {
  final String userName;
  final String fullName;
  final String password;

  const RegisterRequestDto({
    required this.userName,
    required this.fullName,
    required this.password,
  });
}
