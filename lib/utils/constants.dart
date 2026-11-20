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
