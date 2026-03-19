enum PlanCopyRequestStatus {
  pending,
  accepted,
  rejected,
  cancelled;

  String get label {
    switch (this) {
      case PlanCopyRequestStatus.pending:
        return 'Chờ phản hồi';
      case PlanCopyRequestStatus.accepted:
        return 'Đã chấp nhận';
      case PlanCopyRequestStatus.rejected:
        return 'Đã từ chối';
      case PlanCopyRequestStatus.cancelled:
        return 'Đã hủy';
    }
  }

  static PlanCopyRequestStatus fromString(String value) {
    return PlanCopyRequestStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => PlanCopyRequestStatus.pending,
    );
  }
}
