import 'package:flutter_test/flutter_test.dart';
import 'package:society_gate/models/maintenance_bill_model.dart';
import 'package:society_gate/models/ledger_entry_model.dart';
import 'package:society_gate/services/upi_payment_service.dart';
import 'package:society_gate/l10n/app_strings.dart';

void main() {
  group('Maintenance Bill & Calculation Tests', () {
    test('Calculates total payable bill correctly with funds and water charges', () {
      final bill = MaintenanceBill(
        id: 'BILL-2026-11-A402',
        societyId: 'society-6ad99',
        flatNumber: 'A-402',
        wing: 'A',
        memberName: 'Rajesh Arvind Deshmukh',
        billMonth: 11,
        billYear: 2026,
        maintenanceAmount: 2500,
        sinkingFund: 300,
        repairFund: 200,
        waterCharges: 350,
        latePenalty: 100,
        totalAmount: 3450,
        dueDate: DateTime(2026, 11, 15),
        status: 'unpaid',
      );

      expect(bill.totalAmount, 3450);
      expect(bill.isPaid, false);
      expect(bill.flatNumber, 'A-402');
    });

    test('UPI Payment URI builder generates compliant NPCI deep-link string', () {
      final uri = UpiPaymentService.generateUpiUri(
        upiId: 'shivajiparkchs@sbi',
        merchantName: 'Shivaji Park CHS Ltd',
        amount: 3350.0,
        billId: 'BILL-2026-11-A402',
        flatNumber: 'A-402',
        monthYear: '11-2026',
      );

      expect(uri.startsWith('upi://pay?'), true);
      expect(uri.contains('pa=shivajiparkchs%40sbi') || uri.contains('pa=shivajiparkchs@sbi'), true);
      expect(uri.contains('am=3350.00'), true);
      expect(uri.contains('cu=INR'), true);
    });
  });

  group('Society Accounting Ledger Tests', () {
    test('Ledger entry correctly identifies income vs expense', () {
      final expense = LedgerEntry(
        id: 'LED-001',
        societyId: 'society-6ad99',
        transactionDate: DateTime.now(),
        type: 'expense',
        category: 'cat_security_salary',
        title: 'Security Agency Salary',
        titleMr: 'सुरक्षा रक्षक एजन्सी वेतन',
        amount: 38000,
        paymentMode: 'bank',
        voucherNo: 'PV-01',
        vendorName: 'Tiger Security',
        recordedByUid: 'admin',
      );

      final income = LedgerEntry(
        id: 'LED-002',
        societyId: 'society-6ad99',
        transactionDate: DateTime.now(),
        type: 'income',
        category: 'cat_maintenance_collection',
        title: 'Maintenance Collection - A-402',
        titleMr: 'मासिक देखभाल वर्गणी - A-402',
        amount: 3350,
        paymentMode: 'upi',
        voucherNo: 'RV-01',
        vendorName: 'Rajesh Deshmukh',
        recordedByUid: 'auto_upi',
      );

      expect(expense.isExpense, true);
      expect(expense.isIncome, false);
      expect(income.isIncome, true);
      expect(income.isExpense, false);
    });
  });

  group('Bilingual Marathi & English Localization Tests', () {
    test('Translates core society keys in English and Marathi', () {
      expect(AppStrings.get('appName', 'en'), 'SocietyGate');
      expect(AppStrings.get('appName', 'mr'), 'सोसायटी गेट');

      expect(AppStrings.get('maintenanceBilling', 'en'), 'Maintenance & Payments');
      expect(AppStrings.get('maintenanceBilling', 'mr'), 'मासिक देखभाल व भरणा');

      expect(AppStrings.get('transparencyDashboard', 'en'), 'Member Transparency Dashboard');
      expect(AppStrings.get('transparencyDashboard', 'mr'), 'सदस्य पारदर्शकता डॅशबोर्ड');

      expect(AppStrings.get('visitorEntry', 'en'), 'Visitor Entry Register');
      expect(AppStrings.get('visitorEntry', 'mr'), 'गेट अभ्यागत नोंदवही');
    });
  });
}
