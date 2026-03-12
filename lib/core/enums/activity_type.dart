import 'package:flutter/material.dart';

/// Loại hoạt động trong lịch trình
enum ActivityType {
  travel,
  dining,
  sightseeing,
  shopping,
  worship,
  rest,
  other;

  String get label {
    switch (this) {
      case ActivityType.travel:
        return 'Di chuyển';
      case ActivityType.dining:
        return 'Ăn uống';
      case ActivityType.sightseeing:
        return 'Tham quan';
      case ActivityType.shopping:
        return 'Mua sắm';
      case ActivityType.worship:
        return 'Lễ chùa';
      case ActivityType.rest:
        return 'Nghỉ ngơi';
      case ActivityType.other:
        return 'Khác';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityType.travel:
        return Icons.directions_car_rounded;
      case ActivityType.dining:
        return Icons.restaurant_rounded;
      case ActivityType.sightseeing:
        return Icons.temple_buddhist_rounded;
      case ActivityType.shopping:
        return Icons.shopping_bag_rounded;
      case ActivityType.worship:
        return Icons.account_balance_rounded;
      case ActivityType.rest:
        return Icons.hotel_rounded;
      case ActivityType.other:
        return Icons.more_horiz_rounded;
    }
  }

  static ActivityType fromString(String value) {
    return ActivityType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ActivityType.other,
    );
  }
}
