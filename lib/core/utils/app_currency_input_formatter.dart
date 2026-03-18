import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AppCurrencyInputFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat.decimalPattern('vi_VN');

  static String formatStoredAmount(num? value) {
    if (value == null || value <= 0) return '';
    return '${_formatter.format(value.round())} đ';
  }

  static String stripFormatting(String rawValue) {
    final normalized = rawValue.trim();
    return normalized
        .replaceAll(RegExp('vnd', caseSensitive: false), '')
        .replaceAll('₫', '')
        .replaceAll('đ', '')
        .trim();
  }

  static String _extractDigits(String rawValue) {
    final digits = rawValue.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    return digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _extractDigits(newValue.text);
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = '${_formatter.format(int.parse(digits))} đ';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
      composing: TextRange.empty,
    );
  }
}
