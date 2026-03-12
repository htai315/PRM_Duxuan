/// Nguồn tạo checklist item
enum ChecklistSource {
  manual,
  suggested;

  String get label {
    switch (this) {
      case ChecklistSource.manual:
        return 'Thủ công';
      case ChecklistSource.suggested:
        return 'Gợi ý';
    }
  }

  static ChecklistSource fromString(String value) {
    return ChecklistSource.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ChecklistSource.manual,
    );
  }
}
