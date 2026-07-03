import 'package:flutter/services.dart';
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

  static final _thousandsFormatter = NumberFormat('#,###', 'vi_VN');

  static String format(int cents) => _formatter.format(fromCents(cents));

  static String formatDouble(double amount) => _formatter.format(amount);

  static String formatInt(int amount) => _thousandsFormatter.format(amount);

  static String formatQty(double qty) {
    if (qty == qty.truncateToDouble()) return qty.toInt().toString();
    return qty.toString();
  }
}

class ThousandsFormatter extends TextInputFormatter {
  static final _formatter = NumberFormat('#,###', 'vi_VN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final cleanText = newValue.text.replaceAll('.', '');
    final number = int.tryParse(cleanText);
    if (number == null && cleanText.isNotEmpty) {
      return oldValue;
    }
    
    if (cleanText.isEmpty) {
      return const TextEditingValue();
    }

    final formattedText = _formatter.format(number);

    int oldDigitCount = 0;
    for (int i = 0; i < newValue.selection.baseOffset; i++) {
      if (newValue.text[i] != '.') {
        oldDigitCount++;
      }
    }

    int newCursorOffset = 0;
    int digitCount = 0;
    while (digitCount < oldDigitCount && newCursorOffset < formattedText.length) {
      if (formattedText[newCursorOffset] != '.') {
        digitCount++;
      }
      newCursorOffset++;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }
}
