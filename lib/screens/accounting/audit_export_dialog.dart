import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/accounting_provider.dart';
import '../../l10n/language_provider.dart';
import '../../services/audit_export_service.dart';
import '../../utils/app_theme.dart';

class AuditExportDialog extends StatelessWidget {
  const AuditExportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const AuditExportDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final accounting = Provider.of<AccountingProvider>(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.assessment, color: AppTheme.primaryNavy),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lang.tr('exportAuditStatement'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.isMarathi
                ? 'वार्षिक सर्वसाधारण सभा (AGM) आणि कायदेशीर हिशोब तपासणीसाठी खालील स्वरूपात अहवाल डाउनलोड करा:'
                : 'Download society balance sheet and ledger accounts for AGM & Statutory Audit in your preferred format:',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),

          // PDF Export Option
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.picture_as_pdf, color: Colors.red),
            ),
            title: const Text('Official Audit Statement (PDF)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(
              lang.isMarathi ? 'मुद्रण व AGM स्वाक्षरीसाठी तयार' : 'Printable format with signature boxes & stamps',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () async {
              Navigator.pop(context);
              final pdfBytes = await accounting.exportAuditPdf();
              await AuditExportService.shareOrPrintAuditPdf(
                pdfBytes,
                'Society_AGM_Audit_Report_${DateTime.now().year}.pdf',
              );
            },
          ),
          const Divider(),

          // CSV / Excel Export Option
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.table_chart, color: Colors.green),
            ),
            title: const Text('Excel Data Spreadsheet (CSV)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(
              lang.isMarathi ? 'मायक्रोसॉफ्ट एक्सेल / गुगल शीट मध्ये उघडा' : 'Opens directly in Microsoft Excel & Google Sheets',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () async {
              Navigator.pop(context);
              final csvData = accounting.exportFinancialCsv();
              await Share.share(
                csvData,
                subject: 'Society Financial Statement - Shivaji Park CHS',
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(lang.tr('close')),
        ),
      ],
    );
  }
}
