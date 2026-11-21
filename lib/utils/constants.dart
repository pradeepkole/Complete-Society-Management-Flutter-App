class AppConstants {
  static const String defaultSocietyId = 'soc_default';
  static const String defaultSocietyNameEn = 'Housing Society Ltd.';
  static const String defaultSocietyNameMr = 'सहकारी गृहनिर्माण संस्था मर्यादित';
  static const String defaultSocietyUpiId = 'society@oksbi';
  static const String defaultSocietyUpiName = 'Society Maintenance';
  static const String defaultRegistrationNo = 'REG/CHS/2026';

  static const List<String> wings = ['A', 'B', 'C', 'D'];
  
  static const List<String> expenseCategories = [
    'cat_common_electricity',    // 1. Electricity bill
    'cat_water_bill',             // 2. Water bill
    'cat_watchman_salary',        // 3. Watchman salary
    'cat_sweeper_salary',         // 4. Sweepers salary
    'cat_lift_maintenance',       // 5. Lift maintenance (AMC)
    'cat_misc_repair',            // 6. Misc repairy
    'cat_labour_payment',         // 7. Labour payment
    'cat_goods_purchase',         // 8. Goods purchase
    'cat_development_expenses',   // 9. Development expenses
    'cat_other_expense',          // 10. Other / सानुकूल खर्च
  ];

  static const List<String> incomeCategories = [
    'cat_maintenance_collection',
    'cat_parking_charges',
    'cat_transfer_fee',
    'cat_noc_charges',
    'cat_clubhouse_rent',
    'cat_penalty_fines',
    'cat_bank_interest',
    'cat_other_income',
  ];

  static const List<String> paymentModes = ['bank', 'cash', 'upi'];
}
