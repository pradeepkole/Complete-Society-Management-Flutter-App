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
      // e.g. 20 नोव्हेंबर 2026
      return DateFormat('dd MMM yyyy', 'mr').format(date);
    }
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date, {bool isMarathi = false}) {
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
