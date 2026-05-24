import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String todayIso() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  static String formatDisplay(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  static bool isSameDay(String isoDate, DateTime day) {
    return isoDate.startsWith(DateFormat('yyyy-MM-dd').format(day));
  }

  static bool isSameMonth(String isoDate, DateTime day) {
    return isoDate.startsWith(DateFormat('yyyy-MM').format(day));
  }
}
