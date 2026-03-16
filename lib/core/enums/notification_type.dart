/// Phân loại thông báo trong ứng dụng.
enum NotificationType {
  reminder,
  system;

  String get label {
    switch (this) {
      case NotificationType.reminder:
        return 'Nhắc nhở';
      case NotificationType.system:
        return 'Hệ thống';
    }
  }

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => NotificationType.system,
    );
  }
}
