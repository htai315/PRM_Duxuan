import 'package:flutter/material.dart';

/// Phân loại đồ trong checklist
enum ChecklistCategory {
  clothing,
  toiletry,
  electronics,
  document,
  medicine,
  food,
  other;

  String get label {
    switch (this) {
      case ChecklistCategory.clothing:
        return 'Quần áo';
      case ChecklistCategory.toiletry:
        return 'Vệ sinh';
      case ChecklistCategory.electronics:
        return 'Điện tử';
      case ChecklistCategory.document:
        return 'Tài liệu';
      case ChecklistCategory.medicine:
        return 'Thuốc';
      case ChecklistCategory.food:
        return 'Đồ ăn';
      case ChecklistCategory.other:
        return 'Khác';
    }
  }

  Color get color {
    switch (this) {
      case ChecklistCategory.clothing:
        return const Color(0xFFE53935);
      case ChecklistCategory.toiletry:
        return const Color(0xFF00897B);
      case ChecklistCategory.electronics:
        return const Color(0xFF1565C0);
      case ChecklistCategory.document:
        return const Color(0xFF7B1FA2);
      case ChecklistCategory.medicine:
        return const Color(0xFFD81B60);
      case ChecklistCategory.food:
        return const Color(0xFFFF8F00);
      case ChecklistCategory.other:
        return const Color(0xFF546E7A);
    }
  }

  IconData get icon {
    switch (this) {
      case ChecklistCategory.clothing:
        return Icons.checkroom_rounded;
      case ChecklistCategory.toiletry:
        return Icons.sanitizer_rounded;
      case ChecklistCategory.electronics:
        return Icons.devices_rounded;
      case ChecklistCategory.document:
        return Icons.description_rounded;
      case ChecklistCategory.medicine:
        return Icons.medication_rounded;
      case ChecklistCategory.food:
        return Icons.lunch_dining_rounded;
      case ChecklistCategory.other:
        return Icons.inventory_2_rounded;
    }
  }

  static ChecklistCategory fromString(String value) {
    return ChecklistCategory.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ChecklistCategory.other,
    );
  }
}
