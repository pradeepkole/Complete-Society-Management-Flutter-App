import 'package:intl/intl.dart';
export 'constants.dart';

class AppDateFormatter {
  static final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String formatCurrency(double amount) {
    return currencyFormat.format(amount);
  }

  static String formatDate(DateTime date, {bool isMarathi = false}) {
    if (isMarathi) {
      const mrMonths = [
        'जानेवारी', 'फेब्रुवारी', 'मार्च', 'एप्रिल', 'मे', 'जून',
        'जुलै', 'ऑगस्ट', 'सप्टेंबर', 'ऑक्टोबर', 'नोव्हेंबर', 'डिसेंबर'
      ];
      final day = date.day.toString().padLeft(2, '0');
      final month = (date.month >= 1 && date.month <= 12) ? mrMonths[date.month - 1] : date.month.toString();
      return '$day $month ${date.year}';
    }
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date, {bool isMarathi = false}) {
    if (isMarathi) {
      final dStr = formatDate(date, isMarathi: true);
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'दु.' : 'स.';
      return '$dStr, $hour:$minute $period';
    }
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String getMonthName(int month, {bool isMarathi = false}) {
    const enMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const mrMonths = [
      'जानेवारी', 'फेब्रुवारी', 'मार्च', 'एप्रिल', 'मे', 'जून',
      'जुलै', 'ऑगस्ट', 'सप्टेंबर', 'ऑक्टोबर', 'नोव्हेंबर', 'डिसेंबर'
    ];
    if (month >= 1 && month <= 12) {
      return isMarathi ? mrMonths[month - 1] : enMonths[month - 1];
    }
    return '';
  }
}
