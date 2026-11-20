import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/maintenance_bill_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/billing_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_app_bar.dart';
import 'upi_payment_dialog.dart';

class MemberBillsScreen extends StatelessWidget {
  const MemberBillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final billing = Provider.of<BillingProvider>(context);

    final flatNumber = auth.currentUser?.flatNumber ?? 'A-402';
    final bills = billing.getBillsForFlat(flatNumber);

    return Scaffold(
      appBar: CustomAppBar(
        title: '${lang.tr('monthlyBills')} ($flatNumber)',
      ),
      body: bills.isEmpty
          ? Center(
              child: Text(
                lang.isMarathi ? 'कोणतेही देयक उपलब्ध नाही' : 'No bills found',
                style: const TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bills.length,
              itemBuilder: (context, index) {
                final bill = bills[index];
                return _buildBillCard(context, bill, lang, billing);
              },
            ),
    );
  }

  Widget _buildBillCard(
    BuildContext context,
    MaintenanceBill bill,
    LanguageProvider lang,
    BillingProvider billing,
  ) {
    final isPaid = bill.isPaid;
    final isOverdue = bill.isOverdue;

    Color statusColor = isPaid
        ? const Color(0xFF16A34A)
        : (isOverdue ? const Color(0xFFDC2626) : const Color(0xFFEA580C));

    String statusText = isPaid
        ? lang.tr('paid')
        : (isOverdue ? lang.tr('overdue') : lang.tr('unpaid'));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppDateFormatter.getMonthName(bill.billMonth, isMarathi: lang.isMarathi)} ${bill.billYear}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    Text(
                      '${lang.tr('dueDate')}: ${AppDateFormatter.formatDate(bill.dueDate, isMarathi: lang.isMarathi)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Charges Breakdown Table
            _buildChargeRow(lang.tr('maintenanceCharge'), bill.maintenanceAmount),
            _buildChargeRow(lang.tr('sinkingFund'), bill.sinkingFund),
            _buildChargeRow(lang.tr('repairFund'), bill.repairFund),
            _buildChargeRow(lang.tr('waterCharges'), bill.waterCharges),
            if (bill.latePenalty > 0)
              _buildChargeRow(lang.tr('latePenalty'), bill.latePenalty, isRed: true),

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.tr('totalPayable'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryNavy),
                  ),
                  Text(
                    AppDateFormatter.formatCurrency(bill.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryNavy),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            if (!isPaid) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: Text('${lang.tr('payNow')} (UPI / QR)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => UpiPaymentDialog.show(context, bill),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf, size: 18, color: Color(0xFF16A34A)),
                      label: Text(
                        lang.tr('downloadPdf'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF16A34A)),
                      ),
                      onPressed: () => billing.downloadReceiptPdf(bill),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '${lang.tr('receiptNo')}: ${bill.receiptNumber} • ${bill.paymentRef}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChargeRow(String label, double amount, {bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
          Text(
            AppDateFormatter.formatCurrency(amount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isRed ? Colors.red : Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
