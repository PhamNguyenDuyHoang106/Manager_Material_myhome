import 'package:intl/intl.dart';

class MoneyUtils {
  MoneyUtils._();

  static int toCents(double amount) => (amount * 100).round();

  static double fromCents(int cents) => cents / 100;

  static final _formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static String format(int cents) => _formatter.format(fromCents(cents));

  static String formatDouble(double amount) => _formatter.format(amount);
}
