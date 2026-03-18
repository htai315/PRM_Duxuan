import 'package:du_xuan/domain/entities/activity.dart';
import 'package:du_xuan/domain/entities/expense.dart';
import 'package:intl/intl.dart';

class ActivityDayCostSummary {
  final double estimatedTotal;
  final double actualTotal;
  final bool hasActualEntries;
  final bool hasEstimatedEntries;

  const ActivityDayCostSummary({
    required this.estimatedTotal,
    required this.actualTotal,
    required this.hasActualEntries,
    required this.hasEstimatedEntries,
  });

  bool get hasAnyCost => estimatedTotal > 0 || actualTotal > 0;

  String get bottomBarTitle =>
      hasActualEntries ? 'Chi tiêu thực tế hôm nay' : 'Chi phí dự kiến hôm nay';

  String get bottomBarTotalLabel => ActivityCostUi.formatCurrency(
    hasActualEntries ? actualTotal : estimatedTotal,
  );

  String? get bottomBarSupportingText {
    if (!hasActualEntries || !hasEstimatedEntries) return null;
    return 'Dự kiến từ lịch trình: ${ActivityCostUi.formatCurrency(estimatedTotal)}';
  }

  String get dayChipLabel {
    if (hasActualEntries) {
      return 'Thực tế ${ActivityCostUi.formatCompactCurrency(actualTotal)}';
    }
    if (hasEstimatedEntries) {
      return 'Dự kiến ${ActivityCostUi.formatCompactCurrency(estimatedTotal)}';
    }
    return '0₫';
  }
}

class ActivityCostUi {
  static final NumberFormat _fullFormatter = NumberFormat.decimalPattern('vi');

  static bool hasEstimatedCost(Activity activity) =>
      activity.estimatedCost != null && activity.estimatedCost! > 0;

  static String formatCurrency(double amount) {
    if (amount <= 0) return '0₫';
    return '${_fullFormatter.format(amount.round())}₫';
  }

  static String formatCompactCurrency(double amount) {
    if (amount <= 0) return '0₫';
    if (amount >= 1000000) {
      return '${_trimTrailingZero((amount / 1000000).toStringAsFixed(1))}tr';
    }
    if (amount >= 1000) {
      return '${_trimTrailingZero((amount / 1000).toStringAsFixed(amount < 10000 ? 1 : 0))}k';
    }
    return '${amount.round()}₫';
  }

  static String? activityCostBadgeLabel(Activity activity) {
    if (hasEstimatedCost(activity)) {
      return 'Dự kiến ${formatCompactCurrency(activity.estimatedCost!)}';
    }
    return null;
  }

  static String varianceLabel(double variance) {
    final prefix = variance >= 0 ? '+' : '-';
    return '$prefix${formatCurrency(variance.abs())}';
  }

  static ActivityDayCostSummary buildDaySummary({
    required Iterable<Activity> activities,
    required Iterable<Expense> expenses,
  }) {
    double estimatedTotal = 0;
    double actualTotal = 0;

    for (final activity in activities) {
      final estimated = hasEstimatedCost(activity)
          ? activity.estimatedCost!
          : 0.0;
      estimatedTotal += estimated;
    }

    for (final expense in expenses) {
      if (expense.amount > 0) {
        actualTotal += expense.amount;
      }
    }

    return ActivityDayCostSummary(
      estimatedTotal: estimatedTotal,
      actualTotal: actualTotal,
      hasActualEntries: actualTotal > 0,
      hasEstimatedEntries: estimatedTotal > 0,
    );
  }

  static String _trimTrailingZero(String value) {
    if (!value.contains('.')) return value;
    return value.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
