import 'package:intl/intl.dart';

class CurrencyFormatter {
  static const String locale = 'id_ID';
  static const String symbol = 'Rp ';

  static String format(double amount) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String formatWithDecimal(double amount) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static double? parse(String amount) {
    try {
      final cleanAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');
      return double.parse(cleanAmount);
    } catch (e) {
      return null;
    }
  }
}

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  static DateTime? parseDate(String dateStr) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dateStr);
    } catch (e) {
      return null;
    }
  }
}
