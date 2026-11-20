import 'package:intl/intl.dart';

class AppConstants {
  static const String defaultSocietyId = 'soc_shivaji_park_01';
  static const String defaultSocietyNameEn = 'Shivaji Park Co-op Housing Society Ltd.';
  static const String defaultSocietyNameMr = 'शिवाजी पार्क सहकारी गृहनिर्माण संस्था मर्यादित';
  static const String defaultSocietyUpiId = 'shivajiparkchs@sbi';
  static const String defaultSocietyUpiName = 'Shivaji Park CHS Maintenance';
  static const String defaultRegistrationNo = 'MUM/W-E/CHS/12345/2015';

  static const List<String> wings = ['A', 'B', 'C'];
  
  static const List<String> expenseCategories = [
    'cat_security_salary',
    'cat_common_electricity',
    'cat_water_tanker',
    'cat_lift_maintenance',
    'cat_housekeeping_cleaning',
    'cat_plumbing_repairs',
    'cat_auditor_legal_fees',
    'cat_festival_celebration',
    'cat_other_expense',
  ];

  static const List<String> incomeCategories = [
    'cat_maintenance_collection',
    'cat_clubhouse_rent',
    'cat_parking_charges',
    'cat_penalty_fines',
    'cat_bank_interest',
    'cat_other_income',
  ];

  static const List<String> paymentModes = ['bank', 'cash', 'upi'];
}

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
