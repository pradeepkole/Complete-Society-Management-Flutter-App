import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/billing_provider.dart';
import '../../providers/accounting_provider.dart';
import '../../providers/notice_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/summary_card.dart';
import '../billing/billing_management_screen.dart';
import '../accounting/balance_sheet_screen.dart';
import '../accounting/add_ledger_entry_screen.dart';
import '../accounting/audit_export_dialog.dart';
import '../notices/add_notice_screen.dart';

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final billing = Provider.of<BillingProvider>(context);
    final accounting = Provider.of<AccountingProvider>(context);
    final notices = Provider.of<NoticeProvider>(context);
    final complaints = Provider.of<ComplaintProvider>(context);

    final totalBills = billing.allBills.length;
    final paidBills = billing.allBills.where((b) => b.isPaid).length;
    final collectionPct = totalBills > 0 ? ((paidBills / totalBills) * 100).toStringAsFixed(0) : '0';
    final openComplaints = complaints.allComplaints.where((c) => c.status != 'resolved').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          // Admin Welcome Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${lang.tr('welcomeBack')} ${lang.isMarathi ? auth.currentUser?.nameMr : auth.currentUser?.name}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        lang.tr('admin'),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  lang.tr('netBalance'),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                Text(
                  AppDateFormatter.formatCurrency(accounting.netSocietyBalance),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${lang.tr('bankBalance')}: ${AppDateFormatter.formatCurrency(accounting.bankBalance)}',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '${lang.tr('cashBalance')}: ${AppDateFormatter.formatCurrency(accounting.cashBalance)}',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // High-level Stats Row
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: lang.isMarathi ? 'देखभाल वसुली दर' : 'Collection Rate',
                  value: '$collectionPct%',
                  subtitle: '$paidBills of $totalBills flats paid',
                  icon: Icons.pie_chart,
                  color: const Color(0xFF16A34A),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BillingManagementScreen()));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: lang.isMarathi ? 'प्रलंबित तक्रारी' : 'Active Issues',
                  value: '$openComplaints',
                  subtitle: lang.isMarathi ? 'निवारण बाकी' : 'Awaiting resolution',
                  icon: Icons.handyman,
                  color: const Color(0xFFEA580C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Actions Grid
          Text(
            lang.tr('quickActions'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _buildActionTile(
                context,
                icon: Icons.add_card,
                label: lang.tr('generateBills'),
                color: const Color(0xFF1E3A8A),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BillingManagementScreen()));
                },
              ),
              const SizedBox(width: 8),
              _buildActionTile(
                context,
                icon: Icons.post_add,
                label: lang.tr('recordExpense'),
                color: const Color(0xFFDC2626),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddLedgerEntryScreen(initialType: 'expense')),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildActionTile(
                context,
                icon: Icons.announcement,
                label: lang.tr('postNotice'),
                color: const Color(0xFF0284C7),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddNoticeScreen()));
                },
              ),
              const SizedBox(width: 8),
              _buildActionTile(
                context,
                icon: Icons.assessment,
                label: lang.tr('auditReport'),
                color: const Color(0xFF16A34A),
                onTap: () => AuditExportDialog.show(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Recent Activity: Latest Ledger Entries
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.tr('recentActivity'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BalanceSheetScreen()));
                },
                child: Text(lang.tr('viewDetails'), style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          ...accounting.ledgerEntries.take(3).map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: entry.isIncome ? Colors.green.shade50 : Colors.red.shade50,
                  child: Icon(
                    entry.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: entry.isIncome ? Colors.green : Colors.red,
                    size: 16,
                  ),
                ),
                title: Text(
                  lang.isMarathi ? entry.titleMr : entry.title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${entry.voucherNo} • ${entry.paymentMode.toUpperCase()}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                trailing: Text(
                  '${entry.isIncome ? '+' : '-'}${AppDateFormatter.formatCurrency(entry.amount)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: entry.isIncome ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
