class UserDto {
  final int id;
  final String userName;
  final String fullName;
  final String createdAt;

  const UserDto({
    required this.id,
    required this.userName,
    required this.fullName,
    required this.createdAt,
  });

  /// Từ SQLite row
  factory UserDto.fromMap(Map<String, dynamic> map) {
    return UserDto(
      id: map['id'] as int,
      userName: (map['user_name'] ?? '').toString(),
      fullName: (map['full_name'] ?? '').toString(),
      createdAt: (map['created_at'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_name': userName,
    'full_name': fullName,
    'created_at': createdAt,
  };
}
