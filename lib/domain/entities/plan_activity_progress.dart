class PlanActivityProgress {
  final int planId;
  final int totalActivities;
  final int completedActivities;

  const PlanActivityProgress({
    required this.planId,
    required this.totalActivities,
    required this.completedActivities,
  });

  const PlanActivityProgress.empty(this.planId)
    : totalActivities = 0,
      completedActivities = 0;

  double get progress {
    if (totalActivities <= 0) return 0;
    return (completedActivities / totalActivities).clamp(0.0, 1.0);
  }
}
