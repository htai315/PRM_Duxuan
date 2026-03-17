import 'package:intl/intl.dart';

class DateUi {
  DateUi._();

  static String shortDate(DateTime date, {String locale = 'vi'}) {
    return DateFormat('dd/MM', locale).format(date);
  }

  static String fullDate(DateTime date, {String locale = 'vi'}) {
    return DateFormat('dd/MM/yyyy', locale).format(date);
  }

  static String weekdayFullDate(DateTime date, {String locale = 'vi'}) {
    return DateFormat('EEEE, dd/MM/yyyy', locale).format(date);
  }

  static String shortDateRange(
    DateTime start,
    DateTime end, {
    String locale = 'vi',
  }) {
    return '${shortDate(start, locale: locale)} - ${shortDate(end, locale: locale)}';
  }

  static String fullDateRange(
    DateTime start,
    DateTime end, {
    String locale = 'vi',
  }) {
    return '${fullDate(start, locale: locale)} - ${fullDate(end, locale: locale)}';
  }

  static String dayCountLabel(int dayCount) {
    return '$dayCount ngày';
  }
}
