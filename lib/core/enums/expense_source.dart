enum ExpenseSource {
  manual,
  migrated,
  copied;

  String get label {
    switch (this) {
      case ExpenseSource.manual:
        return 'Thủ công';
      case ExpenseSource.migrated:
        return 'Chuyển đổi';
      case ExpenseSource.copied:
        return 'Sao chép';
    }
  }

  static ExpenseSource fromString(String value) {
    return ExpenseSource.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ExpenseSource.manual,
    );
  }
}
