import 'package:flutter/material.dart';

enum ExpenseCategory {
  transport,
  food,
  ticket,
  lodging,
  shopping,
  other;

  String get label {
    switch (this) {
      case ExpenseCategory.transport:
        return 'Di chuyển';
      case ExpenseCategory.food:
        return 'Ăn uống';
      case ExpenseCategory.ticket:
        return 'Vé';
      case ExpenseCategory.lodging:
        return 'Lưu trú';
      case ExpenseCategory.shopping:
        return 'Mua sắm';
      case ExpenseCategory.other:
        return 'Khác';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.transport:
        return Icons.directions_car_filled_rounded;
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.ticket:
        return Icons.confirmation_number_rounded;
      case ExpenseCategory.lodging:
        return Icons.hotel_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.other:
        return Icons.receipt_long_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.transport:
        return const Color(0xFF1565C0);
      case ExpenseCategory.food:
        return const Color(0xFFFF8F00);
      case ExpenseCategory.ticket:
        return const Color(0xFFD4403A);
      case ExpenseCategory.lodging:
        return const Color(0xFF7B1FA2);
      case ExpenseCategory.shopping:
        return const Color(0xFF00897B);
      case ExpenseCategory.other:
        return const Color(0xFF546E7A);
    }
  }

  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }
}
