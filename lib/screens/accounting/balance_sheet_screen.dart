import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/ledger_entry_model.dart';
import '../../providers/accounting_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/summary_card.dart';
import 'add_ledger_entry_screen.dart';
import 'audit_export_dialog.dart';

class BalanceSheetScreen extends StatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  State<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends State<BalanceSheetScreen> {
  String _activeTab = 'all'; // 'all', 'expense', 'income'

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final accounting = Provider.of<AccountingProvider>(context);

    final entries = accounting.ledgerEntries.where((e) {
      if (_activeTab == 'all') return true;
      if (_activeTab == 'expense') return e.isExpense;
      if (_activeTab == 'income') return e.isIncome;
      return true;
    }).toList();

    final expenseBreakdown = accounting.getExpenseCategoryBreakdown();

    return Scaffold(
      appBar: CustomAppBar(
        title: lang.tr('realTimeBalanceSheet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            tooltip: lang.tr('auditReport'),
            onPressed: () => AuditExportDialog.show(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(lang.tr('recordExpense')),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddLedgerEntryScreen(initialType: 'expense')),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            // Net Society Balance Hero Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang.tr('netBalance'),
                        style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'FY ${DateTime.now().year}',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppDateFormatter.formatCurrency(accounting.netSocietyBalance),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAlignment.start,
                            children: [
                              Text(lang.tr('bankBalance'), style: const TextStyle(fontSize: 10, color: Colors.white70)),
                              Text(
                                AppDateFormatter.formatCurrency(accounting.bankBalance),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.payments, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAlignment.start,
                            children: [
                              Text(lang.tr('cashBalance'), style: const TextStyle(fontSize: 10, color: Colors.white70)),
                              Text(
                                AppDateFormatter.formatCurrency(accounting.cashBalance),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Income vs Expense Metrics
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: lang.tr('totalIncome'),
                    value: AppDateFormatter.formatCurrency(accounting.totalIncome),
                    icon: Icons.trending_up,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: lang.tr('totalExpenses'),
                    value: AppDateFormatter.formatCurrency(accounting.totalExpenses),
                    icon: Icons.trending_down,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Expense Breakdown Chart
            if (expenseBreakdown.isNotEmpty) ...[
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
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

            // Ledger Transactions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.tr('societyAccounting'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.file_download, size: 16),
                  label: Text(lang.tr('exportAuditStatement'), style: const TextStyle(fontSize: 11)),
                  onPressed: () => AuditExportDialog.show(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tab bar filter
            Row(
              children: [
                _buildFilterButton('all', lang.tr('all')),
                const SizedBox(width: 8),
                _buildFilterButton('expense', lang.tr('totalExpenses')),
                const SizedBox(width: 8),
                _buildFilterButton('income', lang.tr('totalIncome')),
              ],
            ),
            const SizedBox(height: 12),

            // Ledger List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _buildLedgerTile(context, entry, lang);
              },
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String key, String label) {
    final isSelected = _activeTab == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryNavy,
      labelStyle: TextStyle(
        fontSize: 11,
        color: isSelected ? Colors.white : Colors.grey.shade800,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _activeTab = key),
    );
  }

  Widget _buildLedgerTile(BuildContext context, LedgerEntry entry, LanguageProvider lang) {
    final isIncome = entry.isIncome;
    final color = isIncome ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
            size: 18,
          ),
        ),
        title: Text(
          lang.isMarathi ? entry.titleMr : entry.title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${entry.voucherNo} • ${entry.paymentMode.toUpperCase()} • ${AppDateFormatter.formatDate(entry.transactionDate, isMarathi: lang.isMarathi)}',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'}${AppDateFormatter.formatCurrency(entry.amount)}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
            if (entry.billAttachmentUrl.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.attachment, size: 12, color: Colors.blue.shade700),
                  const SizedBox(width: 2),
                  Text('Invoice', style: TextStyle(fontSize: 9, color: Colors.blue.shade700)),
                ],
              ),
          ],
        ),
        onTap: () {
          _showEntryDetailsDialog(context, entry, lang);
        },
      ),
    );
  }

  void _showEntryDetailsDialog(BuildContext context, LedgerEntry entry, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.isMarathi ? entry.titleMr : entry.title, style: const TextStyle(fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAlignment.start,
          children: [
            Text('${lang.tr('voucherNo')}: ${entry.voucherNo}'),
            Text('${lang.tr('amount')}: ${AppDateFormatter.formatCurrency(entry.amount)}'),
            Text('${lang.tr('paymentMode')}: ${entry.paymentMode.toUpperCase()}'),
            if (entry.vendorName.isNotEmpty) Text('${lang.tr('vendorParty')}: ${entry.vendorName}'),
            Text('${lang.tr('category')}: ${lang.tr(entry.category)}'),
            Text('${lang.tr('date')}: ${AppDateFormatter.formatDate(entry.transactionDate, isMarathi: lang.isMarathi)}'),
            if (entry.billAttachmentUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    const Icon(Icons.verified, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        lang.isMarathi ? 'मूळ पावती ऑडिटसाठी जोडलेली आहे.' : 'Physical bill attached for audit.',
                        style: const TextStyle(fontSize: 11, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      case 'cat_security_salary':
        return const Color(0xFF1E3A8A);
      case 'cat_common_electricity':
        return const Color(0xFFEA580C);
      case 'cat_water_tanker':
        return const Color(0xFF0284C7);
      case 'cat_lift_maintenance':
        return const Color(0xFF7C3AED);
      case 'cat_housekeeping_cleaning':
        return const Color(0xFF059669);
      default:
        return const Color(0xFFD97706);
    }
  }
}
