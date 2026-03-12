/// Trạng thái kế hoạch du xuân
enum PlanStatus {
  draft,
  active,
  completed,
  archived;

  String get label {
    switch (this) {
      case PlanStatus.draft:
        return 'Nháp';
      case PlanStatus.active:
        return 'Đang thực hiện';
      case PlanStatus.completed:
        return 'Hoàn thành';
      case PlanStatus.archived:
        return 'Lưu trữ';
    }
  }

  /// Parse từ String lưu trong DB
  static PlanStatus fromString(String value) {
    return PlanStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => PlanStatus.draft,
    );
  }
}
