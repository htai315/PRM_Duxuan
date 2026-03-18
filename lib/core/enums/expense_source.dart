enum ExpenseSource {
  manual,
  migrated;

  String get label {
    switch (this) {
      case ExpenseSource.manual:
        return 'Thủ công';
      case ExpenseSource.migrated:
        return 'Chuyển đổi';
    }
  }

  static ExpenseSource fromString(String value) {
    return ExpenseSource.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ExpenseSource.manual,
    );
  }
}
