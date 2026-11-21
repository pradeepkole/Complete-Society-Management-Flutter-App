import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/accounting_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/summary_card.dart';
import 'audit_export_dialog.dart';

class MemberTransparencyScreen extends StatelessWidget {
  const MemberTransparencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final accounting = Provider.of<AccountingProvider>(context);

    final entries = accounting.ledgerEntries;
    final expenseBreakdown = accounting.getExpenseCategoryBreakdown();

    return Scaffold(
      appBar: CustomAppBar(
        title: lang.tr('transparencyDashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            tooltip: lang.tr('auditReport'),
            onPressed: () => AuditExportDialog.show(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transparency Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF047857).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF047857).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: Color(0xFF047857), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.isMarathi ? '१००% पारदर्शक सोसायटी हिशोब' : '100% Transparent Financials',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF047857)),
                        ),
                        Text(
                          lang.isMarathi
                              ? 'प्रत्येक खर्चाचे मूळ बिल व पावती सर्व सभासदांसाठी उपलब्ध आहे.'
                              : 'Every expense invoice and bank voucher is audited & verifiable by all flat members.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary metrics
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: lang.tr('netBalance'),
                    value: AppDateFormatter.formatCurrency(accounting.netSocietyBalance),
                    icon: Icons.account_balance,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: lang.tr('bankBalance'),
                    value: AppDateFormatter.formatCurrency(accounting.bankBalance),
                    icon: Icons.savings,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: lang.tr('totalIncome'),
                    value: AppDateFormatter.formatCurrency(accounting.totalIncome),
                    icon: Icons.arrow_downward,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: lang.tr('totalExpenses'),
                    value: AppDateFormatter.formatCurrency(accounting.totalExpenses),
                    icon: Icons.arrow_upward,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category Chart
            if (expenseBreakdown.isNotEmpty) ...[
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.tr('incomeVsExpense'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 36,
                            sections: expenseBreakdown.entries.map((entry) {
                              final catColor = _getCategoryColor(entry.key);
                              return PieChartSectionData(
                                value: entry.value,
                                color: catColor,
                                radius: 45,
                                title: '₹${(entry.value / 1000).toStringAsFixed(1)}k',
                                titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: expenseBreakdown.keys.map((catKey) {
                          final catColor = _getCategoryColor(catKey);
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              Text(lang.tr(catKey), style: const TextStyle(fontSize: 10, color: Color(0xFF334155))),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Attached Bill Receipts Section
            Text(
              lang.isMarathi ? 'खर्चाची बिले व ऑडिट पावत्या:' : 'Audited Expenses & Attached Vouchers:',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
            ),
            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: entry.isIncome ? Colors.green.shade50 : Colors.red.shade50,
                      child: Icon(
                        entry.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: entry.isIncome ? Colors.green : Colors.red,
                        size: 18,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lang.isMarathi ? (entry.titleMr.isNotEmpty ? entry.titleMr : entry.title) : (entry.title.isNotEmpty ? entry.title : entry.titleMr),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              decoration: entry.isCancelled ? TextDecoration.lineThrough : null,
                              color: entry.isCancelled ? Colors.grey.shade600 : null,
                            ),
                          ),
                        ),
                        if (entry.isCancelled)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red)),
                            child: Text(lang.isMarathi ? 'रद्द' : 'Cancelled', style: const TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                          )
                        else if (entry.isReversal)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange)),
                            child: Text(lang.isMarathi ? 'विरुद्ध नोंद' : 'Contra', style: const TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      '${entry.voucherNo} • ${entry.vendorName.isNotEmpty ? entry.vendorName : entry.paymentMode.toUpperCase()} • ${entry.transactionDate.day}/${entry.transactionDate.month}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppDateFormatter.formatCurrency(entry.amount),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: entry.isIncome ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                        if (entry.billAttachmentUrl.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('View Bill', style: TextStyle(fontSize: 9, color: Colors.blue)),
                          ),
                      ],
                    ),
                    onTap: () {
                      _showProofDialog(context, entry, lang);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProofDialog(BuildContext context, dynamic entry, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.isMarathi ? entry.titleMr : entry.title, style: const TextStyle(fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voucher No: ${entry.voucherNo}'),
            Text('Amount: ${AppDateFormatter.formatCurrency(entry.amount)}'),
            Text('Vendor/Party: ${entry.vendorName}'),
            Text('Mode: ${entry.paymentMode.toUpperCase()}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppTheme.primaryNavy),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.billAttachmentUrl.isNotEmpty
                          ? 'Physical tax invoice verified by Society Auditor.'
                          : 'Online transaction receipt verified.',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.tr('close'))),
        ],
      ),
    );
  }

  Color _getCategoryColor(String categoryKey) {
    switch (categoryKey) {
      case 'cat_common_electricity':
        return const Color(0xFFEA580C);
      case 'cat_water_bill':
      case 'cat_water_tanker':
        return const Color(0xFF0284C7);
      case 'cat_watchman_salary':
      case 'cat_security_salary':
        return const Color(0xFF1E3A8A);
      case 'cat_sweeper_salary':
      case 'cat_housekeeping_cleaning':
        return const Color(0xFF059669);
      case 'cat_lift_maintenance':
        return const Color(0xFF7C3AED);
      case 'cat_misc_repair':
      case 'cat_plumbing_repairs':
        return const Color(0xFFD97706);
      case 'cat_labour_payment':
        return const Color(0xFF475569);
      case 'cat_goods_purchase':
        return const Color(0xFF2563EB);
      case 'cat_development_expenses':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF0D9488);
    }
  }
}
