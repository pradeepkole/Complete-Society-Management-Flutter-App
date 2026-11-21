import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/billing_provider.dart';
import '../../providers/accounting_provider.dart';
import '../../providers/notice_provider.dart';
import '../../providers/visitor_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../billing/upi_payment_dialog.dart';
import '../billing/member_bills_screen.dart';
import '../accounting/member_transparency_screen.dart';
import '../complaints/raise_complaint_screen.dart';
import '../notices/notice_board_screen.dart';
import '../admin/committee_directory_screen.dart';

class MemberDashboardTab extends StatelessWidget {
  const MemberDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final billing = Provider.of<BillingProvider>(context);
    final accounting = Provider.of<AccountingProvider>(context);
    final notices = Provider.of<NoticeProvider>(context);
    final visitors = Provider.of<VisitorProvider>(context);

    final flatNumber = auth.currentUser?.flatNumber ?? 'A-402';
    final latestBill = billing.getLatestBillForFlat(flatNumber);
    final isDuePending = latestBill != null && !latestBill.isPaid;
    final pendingVisitors = visitors.getVisitorsForFlat(flatNumber).where((v) => v.memberApproval == 'pendingApproval').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flat Member Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primaryOrange,
                  child: Text(
                    flatNumber.split('-').last,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${lang.tr('flat')} $flatNumber',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      Text(
                        lang.isMarathi ? (auth.currentUser?.nameMr ?? '') : (auth.currentUser?.name ?? ''),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${lang.tr('owner')} • Wing ${auth.currentUser?.wing ?? "A"}',
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Visitor Gate Alert (if visitor waiting)
          if (pendingVisitors.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade400, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.doorbell, color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      Text(
                        lang.isMarathi ? 'गेटवर पाहुणे आले आहेत!' : 'Visitor at Security Gate!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${pendingVisitors.first.visitorName} (${lang.tr(pendingVisitors.first.purpose)})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => visitors.setApproval(pendingVisitors.first.id, 'denied'),
                          child: const Text('Deny / नकार'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                          onPressed: () => visitors.setApproval(pendingVisitors.first.id, 'approved'),
                          child: const Text('Approve / परवानगी द्या'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Maintenance Bill Banner: Pending or Paid
          if (isDuePending) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEA580C), width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFEA580C), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            lang.tr('maintenanceBilling'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFEA580C)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          lang.tr('unpaid'),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${AppDateFormatter.getMonthName(latestBill.billMonth, isMarathi: lang.isMarathi)} ${latestBill.billYear}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppDateFormatter.formatCurrency(latestBill.totalAmount),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                  ),
                  Text(
                    '${lang.tr('dueDate')}: ${AppDateFormatter.formatDate(latestBill.dueDate, isMarathi: lang.isMarathi)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 14),

                  // Pay via UPI / Dynamic QR Action
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_2, size: 20),
                      label: Text('${lang.tr('payViaUpi')} / ${lang.tr('scanQrCode')}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => UpiPaymentDialog.show(context, latestBill),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Color(0xFF16A34A), size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.isMarathi ? 'मासिक देखभाल भरली आहे!' : 'Maintenance Up-to-Date!',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF16A34A)),
                        ),
                        Text(
                          lang.isMarathi
                              ? 'तुमचे सर्व थकीत देयके पूर्ण भरलेली आहेत.'
                              : 'No outstanding dues pending on flat $flatNumber.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  if (latestBill != null && latestBill.isPaid)
                    IconButton(
                      icon: const Icon(Icons.download, color: Color(0xFF16A34A)),
                      tooltip: lang.tr('downloadPdf'),
                      onPressed: () => billing.downloadReceiptPdf(latestBill),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Member Transparency Balance Tile
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberTransparencyScreen()));
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNavy.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance, color: AppTheme.primaryNavy, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.tr('transparencyDashboard'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${lang.tr('netBalance')}: ${AppDateFormatter.formatCurrency(accounting.netSocietyBalance)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Quick Member Actions
          Text(
            lang.tr('quickActions'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _buildMemberAction(
                context,
                icon: Icons.receipt_long,
                label: lang.tr('monthlyBills'),
                color: Colors.blue.shade800,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberBillsScreen())),
              ),
              const SizedBox(width: 8),
              _buildMemberAction(
                context,
                icon: Icons.badge,
                label: lang.isMarathi ? 'समिती फलक' : 'Committee',
                color: const Color(0xFF0D9488),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommitteeDirectoryScreen())),
              ),
              const SizedBox(width: 8),
              _buildMemberAction(
                context,
                icon: Icons.report_problem,
                label: lang.tr('raiseComplaint'),
                color: Colors.orange.shade800,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RaiseComplaintScreen())),
              ),
              const SizedBox(width: 8),
              _buildMemberAction(
                context,
                icon: Icons.campaign,
                label: lang.tr('noticeBoard'),
                color: Colors.purple.shade800,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeBoardScreen())),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Latest Notice Alert
          if (notices.notices.isNotEmpty) ...[
            Text(
              lang.tr('noticeBoard'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.notifications_active, color: Color(0xFFDC2626)),
                title: Text(
                  lang.isMarathi ? notices.notices.first.titleMr : notices.notices.first.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  AppDateFormatter.formatDate(notices.notices.first.publishedDate, isMarathi: lang.isMarathi),
                  style: const TextStyle(fontSize: 10),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeBoardScreen())),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
