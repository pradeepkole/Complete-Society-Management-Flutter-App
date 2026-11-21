import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/maintenance_bill_model.dart';
import '../../providers/billing_provider.dart';
import '../../providers/accounting_provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/summary_card.dart';
import 'group_admin_collection_screen.dart';
import '../admin/handover_approval_screen.dart';

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
    final auth = Provider.of<AuthProvider>(context);
    final isMr = lang.isMarathi;

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
        actions: [
          if (auth.isGroupAdmin)
            IconButton(
              icon: const Icon(Icons.collections_bookmark, color: Colors.white),
              tooltip: isMr ? 'माझा विंग/मजला संकलन' : 'Group Collection',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupAdminCollectionScreen()));
              },
            ),
          if (auth.canManageExpenses)
            IconButton(
              icon: const Icon(Icons.verified_user, color: Colors.white),
              tooltip: isMr ? 'हस्तांतरण पडताळणी' : 'Handover Approvals',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HandoverApprovalScreen()));
              },
            ),
        ],
      ),
      floatingActionButton: auth.canManageExpenses
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_card),
              label: Text(isMr ? 'नवीन देयके तयार करा (खर्च विभाजन)' : 'Generate Bills (Divide Expenses)'),
              onPressed: () => _showGenerateBillsDialog(context, billing, lang),
            )
          : (auth.isGroupAdmin
              ? FloatingActionButton.extended(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.point_of_sale),
                  label: Text(isMr ? 'माझे गट संकलन' : 'My Group Collection'),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupAdminCollectionScreen()));
                  },
                )
              : null),
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
    final isMr = lang.isMarathi;

    final accounting = Provider.of<AccountingProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Compute actual expenses for the selected month
    double computeMonthExpenses(int m, int y) {
      return accounting.expenses
          .where((e) => e.transactionDate.month == m && e.transactionDate.year == y && !e.isCancelled && !e.isReversal)
          .fold(0.0, (sum, e) => sum + e.amount);
    }

    double initialActualExpense = computeMonthExpenses(selectedMonth, selectedYear);
    final totalFlats = auth.currentSociety?.totalFlats ?? 20;

    final expenseController = TextEditingController(
      text: initialActualExpense > 0 ? initialActualExpense.toStringAsFixed(0) : '35000',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) {
          final currentExp = double.tryParse(expenseController.text) ?? 0;
          final rawShare = totalFlats > 0 ? (currentExp / totalFlats) : 0.0;
          final roundedShare = rawShare.roundToDouble();
          final roundOff = roundedShare - rawShare;

          return AlertDialog(
            title: Text(
              isMr ? 'मासिक देयके निर्मिती (खर्च समान वाटप)' : 'Generate Bills (Equal Division)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lang.tr('billForMonth')}: ${AppDateFormatter.getMonthName(selectedMonth, isMarathi: isMr)} $selectedYear',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryNavy),
                  ),
                  const SizedBox(height: 12),

                  // Total Month Expense Field
                  Text(
                    isMr ? 'या महिन्यातील एकूण प्रत्यक्ष खर्च (₹) *' : 'Total Month Actual Expense (₹) *',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: expenseController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.currency_rupee),
                      helperText: isMr
                          ? 'लेजरमधील नोंदवलेल्या प्रत्यक्ष खर्चावरून आपोआप आलेली रक्कम'
                          : 'Calculated from actual recorded ledger expenses',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Division & Round Off Calculation Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(isMr ? 'एकूण फ्लॅट संख्या:' : 'Total Flats:', style: const TextStyle(fontSize: 12)),
                            Text('$totalFlats', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(isMr ? 'प्रति फ्लॅट मूळ हिस्सा:' : 'Per Flat Share:', style: const TextStyle(fontSize: 12)),
                            Text('₹${rawShare.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(isMr ? 'राऊंड ऑफ (Round Off):' : 'Round Off:', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                            Text(
                              '${roundOff >= 0 ? "+" : ""}₹${roundOff.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isMr ? 'प्रत्येक फ्लॅटचे अंतिम देयक:' : 'Final Payable Per Flat:',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                            ),
                            Text(
                              '₹${roundedShare.toStringAsFixed(0)}.00',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(lang.tr('cancel'))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
                onPressed: () async {
                  final finalExpense = double.tryParse(expenseController.text) ?? 0;
                  if (finalExpense <= 0) return;

                  await billing.generateBillsBasedOnActualExpenses(
                    month: selectedMonth,
                    year: selectedYear,
                    totalActualExpense: finalExpense,
                    dueDate: DateTime.now().add(const Duration(days: 15)),
                  );

                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isMr
                              ? '$selectedMonth/$selectedYear चे प्रत्यक्ष खर्च विभागून सर्व फ्लॅट्सची स्वतंत्र बिले तयार झाली!'
                              : 'Bills generated with equal expense share for $selectedMonth/$selectedYear!',
                        ),
                      ),
                    );
                  }
                },
                child: Text(isMr ? 'सर्व बिले तयार करा' : 'Generate All Bills'),
              ),
            ],
          );
        },
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
