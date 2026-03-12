/// Trạng thái hoạt động
enum ActivityStatus {
  todo,
  done;

  String get label {
    switch (this) {
      case ActivityStatus.todo:
        return 'Chưa xong';
      case ActivityStatus.done:
        return 'Hoàn thành';
    }
  }

  static ActivityStatus fromString(String value) {
    return ActivityStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ActivityStatus.todo,
    );
  }
}
