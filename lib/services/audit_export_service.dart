import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/ledger_entry_model.dart';

class AuditExportService {
  /// Generates CSV data for Excel export
  static String generateFinancialCsv({
    required String societyName,
    required List<LedgerEntry> entries,
    required double totalIncome,
    required double totalExpenses,
    required double netBalance,
    required double bankBalance,
    required double cashBalance,
  }) {
    List<List<dynamic>> rows = [];

    // Header Metadata
    rows.add(['SOCIETY FINANCIAL AUDIT STATEMENT / हिशोब तपासणी अहवाल']);
    rows.add(['Society:', societyName]);
    rows.add(['Generated On:', DateTime.now().toIso8601String()]);
    rows.add([]);

    // Summary Section
    rows.add(['FINANCIAL SUMMARY (INR)']);
    rows.add(['Total Income (जमा):', totalIncome.toStringAsFixed(2)]);
    rows.add(['Total Expenses (खर्च):', totalExpenses.toStringAsFixed(2)]);
    rows.add(['Net Society Balance (एकूण शिल्लक):', netBalance.toStringAsFixed(2)]);
    rows.add(['Bank Account Balance:', bankBalance.toStringAsFixed(2)]);
    rows.add(['Cash-in-Hand Balance:', cashBalance.toStringAsFixed(2)]);
    rows.add([]);

    // Table Header
    rows.add([
      'Voucher No',
      'Date',
      'Type (Income/Expense)',
      'Category',
      'Particulars / Payee / Source',
      'Payment Mode',
      'Amount (INR)',
      'Audit Attachment Link',
    ]);

    // Data Rows
    for (var entry in entries) {
      rows.add([
        entry.voucherNo,
        '${entry.transactionDate.day}/${entry.transactionDate.month}/${entry.transactionDate.year}',
        entry.isIncome ? 'INCOME / जमा' : 'EXPENSE / खर्च',
        entry.category,
        entry.vendorName.isNotEmpty ? '${entry.title} (${entry.vendorName})' : entry.title,
        entry.paymentMode.toUpperCase(),
        entry.amount.toStringAsFixed(2),
        entry.billAttachmentUrl.isNotEmpty ? entry.billAttachmentUrl : 'None',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Generates an official AGM Audit PDF Statement
  static Future<Uint8List> generateAuditPdf({
    required String societyNameEn,
    required String registrationNo,
    required List<LedgerEntry> entries,
    required double totalIncome,
    required double totalExpenses,
    required double netBalance,
    required double bankBalance,
    required double cashBalance,
    required int year,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Title Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    societyNameEn.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text('Registration No: $registrationNo', style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'ANNUAL FINANCIAL AUDIT & BALANCE STATEMENT (FY $year)',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.deepOrange800,
                    ),
                  ),
                  pw.Text(
                    'वार्षिक सर्वसाधारण सभा (AGM) आर्थिक जमा-खर्च अहवाल',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1, color: PdfColors.blue900),

            // Summary Table
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _summaryBox('Total Income (जमा)', 'Rs. ${totalIncome.toStringAsFixed(0)}', PdfColors.green800),
                  _summaryBox('Total Expenses (खर्च)', 'Rs. ${totalExpenses.toStringAsFixed(0)}', PdfColors.red800),
                  _summaryBox('Net Balance (शिल्लक)', 'Rs. ${netBalance.toStringAsFixed(0)}', PdfColors.blue900),
                  _summaryBox('Bank Balance', 'Rs. ${bankBalance.toStringAsFixed(0)}', PdfColors.grey900),
                  _summaryBox('Cash Balance', 'Rs. ${cashBalance.toStringAsFixed(0)}', PdfColors.grey900),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Text(
              'Detailed Ledger Transactions (नोंदवही तपशील):',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 8),

            // Transaction Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.2),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(3.5),
                4: const pw.FlexColumnWidth(1.2),
                5: const pw.FlexColumnWidth(1.8),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  children: [
                    _headerCell('Voucher'),
                    _headerCell('Date'),
                    _headerCell('Type'),
                    _headerCell('Particulars / Payee'),
                    _headerCell('Mode'),
                    _headerCell('Amount (INR)'),
                  ],
                ),
                ...entries.map((entry) {
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: entry.isIncome ? PdfColors.green50 : PdfColors.white,
                    ),
                    children: [
                      _dataCell(entry.voucherNo),
                      _dataCell('${entry.transactionDate.day}/${entry.transactionDate.month}'),
                      _dataCell(entry.isIncome ? 'Income' : 'Expense',
                          color: entry.isIncome ? PdfColors.green900 : PdfColors.red900, bold: true),
                      _dataCell('${entry.title}${entry.vendorName.isNotEmpty ? ' (${entry.vendorName})' : ''}'),
                      _dataCell(entry.paymentMode.toUpperCase()),
                      _dataCell('Rs. ${entry.amount.toStringAsFixed(0)}', align: pw.Alignment.centerRight, bold: true),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 30),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAlignment.start,
                  children: [
                    pw.Text('Prepared by:', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 24),
                    pw.Text('Hon. Treasurer / खजिनदार', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAlignment.center,
                  children: [
                    pw.Text('Approved by:', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 24),
                    pw.Text('Hon. Secretary / मानद सचिव', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAlignment.end,
                  children: [
                    pw.Text('Audited by:', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 24),
                    pw.Text('Chartered Accountant / Certified Auditor', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _summaryBox(String title, String value, PdfColor valueColor) {
    return pw.Column(
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: valueColor)),
      ],
    );
  }

  static pw.Widget _headerCell(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        title,
        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8),
      ),
    );
  }

  static pw.Widget _dataCell(String text, {PdfColor? color, bool bold = false, pw.Alignment align = pw.Alignment.centerLeft}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 8,
            color: color ?? PdfColors.black,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  static Future<void> shareOrPrintAuditPdf(Uint8List pdfData, String filename) async {
    await Printing.sharePdf(bytes: pdfData, filename: filename);
  }
}
