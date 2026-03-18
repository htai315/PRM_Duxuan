import 'package:du_xuan/core/utils/app_currency_input_formatter.dart';

class ParsedCostInput {
  final double? value;
  final String? errorMessage;

  const ParsedCostInput({required this.value, required this.errorMessage});

  bool get isValid => errorMessage == null;
}

class AppFormValidators {
  static String? validatePlanName(String name) {
    if (name.trim().isEmpty) {
      return 'Vui lòng nhập tên kế hoạch';
    }
    return null;
  }

  static String? validatePlanDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null) {
      return 'Vui lòng chọn ngày bắt đầu';
    }
    if (endDate == null) {
      return 'Vui lòng chọn ngày kết thúc';
    }
    if (endDate.isBefore(startDate)) {
      return 'Ngày kết thúc phải sau ngày bắt đầu';
    }
    return null;
  }

  static String? validateActivityTitle(String title) {
    if (title.trim().isEmpty) {
      return 'Vui lòng nhập tiêu đề hoạt động';
    }
    return null;
  }

  static String? validateActivityTimeRange(String? startTime, String? endTime) {
    final normalizedStart = startTime?.trim() ?? '';
    final normalizedEnd = endTime?.trim() ?? '';
    if (normalizedStart.isEmpty || normalizedEnd.isEmpty) {
      return null;
    }

    if (normalizedEnd.compareTo(normalizedStart) <= 0) {
      return 'Giờ kết thúc phải sau giờ bắt đầu';
    }
    return null;
  }

  static ParsedCostInput parseEstimatedCost(String rawValue) {
    final normalized = rawValue.trim();
    if (normalized.isEmpty) {
      return const ParsedCostInput(value: null, errorMessage: null);
    }

    final compact = AppCurrencyInputFormatter.stripFormatting(
      normalized,
    ).replaceAll(RegExp(r'\s+'), '');
    final decimalPattern = RegExp(r'^\d+[.,]\d+$');
    final groupedPattern = RegExp(r'^\d{1,3}([.,]\d{3})+$');
    final plainDigitsPattern = RegExp(r'^\d+$');

    if (plainDigitsPattern.hasMatch(compact)) {
      return _buildParsedCostResult(double.tryParse(compact));
    }

    if (groupedPattern.hasMatch(compact)) {
      final digitsOnly = compact.replaceAll(RegExp(r'[.,]'), '');
      return _buildParsedCostResult(double.tryParse(digitsOnly));
    }

    if (decimalPattern.hasMatch(compact)) {
      final decimalValue = compact.replaceAll(',', '.');
      return _buildParsedCostResult(double.tryParse(decimalValue));
    }

    return const ParsedCostInput(
      value: null,
      errorMessage: 'Chi phí không hợp lệ',
    );
  }

  static ParsedCostInput _buildParsedCostResult(double? value) {
    if (value == null) {
      return const ParsedCostInput(
        value: null,
        errorMessage: 'Chi phí không hợp lệ',
      );
    }
    return ParsedCostInput(value: value, errorMessage: null);
  }
}
