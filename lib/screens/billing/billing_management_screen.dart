import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/maintenance_bill_model.dart';
import '../../providers/billing_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/summary_card.dart';

class BillingManagementScreen extends StatefulWidget {
  const BillingManagementScreen({super.key});

  @override
  State<BillingManagementScreen> createState() => _BillingManagementScreenState();
}

class _BillingManagementScreenState extends State<BillingManagementScreen> {
  String _selectedFilter = 'all'; // 'all', 'unpaid', 'paid', 'overdue'

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final billing = Provider.of<BillingProvider>(context);

    final allBills = billing.allBills;
    final filteredBills = allBills.where((b) {
      if (_selectedFilter == 'all') return true;
      if (_selectedFilter == 'paid') return b.isPaid;
      if (_selectedFilter == 'unpaid') return !b.isPaid && !b.isOverdue;
      if (_selectedFilter == 'overdue') return b.isOverdue;
      return true;
    }).toList();

    final totalCollected = allBills.where((b) => b.isPaid).fold(0.0, (sum, b) => sum + b.totalAmount);
    final totalPending = allBills.where((b) => !b.isPaid).fold(0.0, (sum, b) => sum + b.totalAmount);

    return Scaffold(
      appBar: CustomAppBar(
        title: lang.tr('maintenanceBilling'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_card),
        label: Text(lang.tr('generateBills')),
        onPressed: () => _showGenerateBillsDialog(context, billing, lang),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: lang.isMarathi ? 'एकूण वसूल रक्कम' : 'Total Collected',
                    value: AppDateFormatter.formatCurrency(totalCollected),
                    icon: Icons.check_circle,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: lang.isMarathi ? 'एकूण थकीत बाकी' : 'Total Pending',
                    value: AppDateFormatter.formatCurrency(totalPending),
                    icon: Icons.pending_actions,
                    color: const Color(0xFFEA580C),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Filter Tabs
            Row(
              children: [
                _buildFilterChip('all', lang.tr('all')),
                const SizedBox(width: 8),
                _buildFilterChip('unpaid', lang.tr('unpaid')),
                const SizedBox(width: 8),
                _buildFilterChip('paid', lang.tr('paid')),
                const SizedBox(width: 8),
                _buildFilterChip('overdue', lang.tr('overdue')),
              ],
            ),

            const SizedBox(height: 16),

            // Bills List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredBills.length,
              itemBuilder: (context, index) {
                final bill = filteredBills[index];
                return _buildAdminBillTile(context, bill, lang, billing);
              },
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryNavy,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : Colors.grey.shade800,
      ),
      onSelected: (_) {
        setState(() {
          _selectedFilter = key;
        });
      },
    );
  }

  Widget _buildAdminBillTile(
    BuildContext context,
    MaintenanceBill bill,
    LanguageProvider lang,
    BillingProvider billing,
  ) {
    Color statusColor = bill.isPaid
        ? const Color(0xFF16A34A)
        : (bill.isOverdue ? const Color(0xFFDC2626) : const Color(0xFFEA580C));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.12),
          child: Text(
            bill.flatNumber.split('-').last,
            style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 13),
          ),
        ),
        title: Text(
          '${bill.flatNumber} • ${bill.memberName}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${AppDateFormatter.getMonthName(bill.billMonth, isMarathi: lang.isMarathi)} ${bill.billYear} • Due: ${bill.dueDate.day}/${bill.dueDate.month}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppDateFormatter.formatCurrency(bill.totalAmount),
              style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              bill.isPaid ? 'PAID' : (bill.isOverdue ? 'OVERDUE' : 'PENDING'),
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ],
        ),
        onTap: () {
          if (bill.isPaid) {
            billing.downloadReceiptPdf(bill);
          } else {
            _showAdminMarkPaidDialog(context, bill, billing, lang);
          }
        },
      ),
    );
  }

  void _showGenerateBillsDialog(BuildContext context, BillingProvider billing, LanguageProvider lang) {
    final now = DateTime.now();
    int selectedMonth = now.month;
    int selectedYear = now.year;
    final baseController = TextEditingController(text: '2500');
    final sinkingController = TextEditingController(text: '300');
    final repairController = TextEditingController(text: '200');
    final waterController = TextEditingController(text: '350');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.tr('generateBills'), style: const TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${lang.tr('billForMonth')}: ${AppDateFormatter.getMonthName(selectedMonth, isMarathi: lang.isMarathi)} $selectedYear',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: baseController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: lang.tr('maintenanceCharge')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sinkingController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: lang.tr('sinkingFund')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: repairController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: lang.tr('repairFund')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: waterController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: lang.tr('waterCharges')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              await billing.generateBillsForMonth(
                month: selectedMonth,
                year: selectedYear,
                baseAmount: double.tryParse(baseController.text) ?? 2500,
                sinkingFund: double.tryParse(sinkingController.text) ?? 300,
                repairFund: double.tryParse(repairController.text) ?? 200,
                waterCharges: double.tryParse(waterController.text) ?? 350,
                dueDate: DateTime.now().add(const Duration(days: 15)),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Monthly maintenance bills generated for all flats!')),
              );
            },
            child: Text(lang.tr('submit')),
          ),
        ],
      ),
    );
  }

  void _showAdminMarkPaidDialog(
    BuildContext context,
    MaintenanceBill bill,
    BillingProvider billing,
    LanguageProvider lang,
  ) {
    final refController = TextEditingController(text: 'CASH-REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    String mode = 'cash';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${lang.tr('markPaidManually')} (${bill.flatNumber})', style: const TextStyle(fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ${AppDateFormatter.formatCurrency(bill.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: refController,
              decoration: InputDecoration(labelText: lang.tr('transactionRef')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.tr('cancel'))),
          ElevatedButton(
            onPressed: () async {
              await billing.processPayment(
                billId: bill.id,
                paymentMode: mode,
                utrRef: refController.text,
              );
              Navigator.pop(context);
            },
            child: Text(lang.tr('confirm')),
          ),
        ],
      ),
    );
  }
}
