enum PlanTimelineState {
  upcoming,
  ongoing,
  pastDue;

  String get label {
    switch (this) {
      case PlanTimelineState.upcoming:
        return 'Sắp diễn ra';
      case PlanTimelineState.ongoing:
        return 'Đang diễn ra';
      case PlanTimelineState.pastDue:
        return 'Đã qua ngày';
    }
  }
}
