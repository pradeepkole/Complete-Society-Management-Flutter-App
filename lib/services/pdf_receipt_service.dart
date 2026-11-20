import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/maintenance_bill_model.dart';
import '../utils/constants.dart';

class PdfReceiptService {
  static Future<Uint8List> generateMaintenanceReceiptPdf({
    required MaintenanceBill bill,
    required String societyNameEn,
    required String societyNameMr,
    required String registrationNo,
    required String societyAddress,
    required String societyUpiId,
  }) async {
    final pdf = pw.Document();

    final paidDate = bill.paidAt != null
        ? '${bill.paidAt!.day}/${bill.paidAt!.month}/${bill.paidAt!.year}'
        : '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue900, width: 2),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAlignment.start,
              children: [
                // Header: Society Details
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
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Reg. No: $registrationNo',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        societyAddress,
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue900,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'OFFICIAL MAINTENANCE RECEIPT / देखभाल वर्गणी पावती',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(thickness: 1, color: PdfColors.blue900),

                // Receipt Metadata
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAlignment.start,
                      children: [
                        pw.Text('Receipt No: ${bill.receiptNumber.isNotEmpty ? bill.receiptNumber : 'REC-${bill.billYear}-${bill.billMonth}-${bill.flatNumber}'}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text('Bill Month: ${bill.billMonth}/${bill.billYear}',
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Flat / Unit No: ${bill.flatNumber} (Wing ${bill.wing})',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blue900)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAlignment.end,
                      children: [
                        pw.Text('Payment Date: $paidDate', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Payment Status: PAID / भरले',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800, fontSize: 10)),
                        pw.Text('Mode: UPI Online ($societyUpiId)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.Text('UTR / Ref: ${bill.paymentRef.isNotEmpty ? bill.paymentRef : 'UPI-REC-SUCCESS'}',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text('Resident / Member Name: ${bill.memberName}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),

                pw.SizedBox(height: 16),

                // Table of charges
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(4),
                    2: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Sr.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Particulars / तपशील', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Amount (INR)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)))),
                      ],
                    ),
                    _buildTableRow('1', 'Regular Maintenance Charges (नियमित देखभाल आकार)', bill.maintenanceAmount),
                    _buildTableRow('2', 'Sinking Fund (सिंकिंग फंड राखीव निधी)', bill.sinkingFund),
                    _buildTableRow('3', 'Building Repair & Maintenance Fund (दुरुस्ती निधी)', bill.repairFund),
                    _buildTableRow('4', 'Water & Municipal Charges (पाणी वापर शुल्क)', bill.waterCharges),
                    if (bill.latePenalty > 0)
                      _buildTableRow('5', 'Late Payment Penalty (विलंब आकार)', bill.latePenalty),
                  ],
                ),

                // Total Row
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  color: PdfColors.blue50,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL AMOUNT PAID / एकूण प्राप्त रक्कम:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blue900),
                      ),
                      pw.Text(
                        'Rs. ${bill.totalAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.blue900),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Footer & Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAlignment.start,
                      children: [
                        pw.Container(
                          width: 80,
                          height: 40,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.blue900, width: 1),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Center(
                            child: pw.Text('SOCIETY SEAL\n[VERIFIED]',
                                textAlign: pw.TextAlign.center,
                                style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue900)),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Generated electronically via SocietyGate App.',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAlignment.end,
                      children: [
                        pw.Text('For $societyNameEn',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        pw.SizedBox(height: 30),
                        pw.Text('Hon. Secretary / Treasurer',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.blue900)),
                        pw.Text('(मानद सचिव / खजिनदार)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _buildTableRow(String sr, String title, double amount) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(sr, style: const pw.TextStyle(fontSize: 9))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(title, style: const pw.TextStyle(fontSize: 9))),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Rs. ${amount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
          ),
        ),
      ],
    );
  }

  static Future<void> printOrShareReceipt(Uint8List pdfData, String filename) async {
    await Printing.sharePdf(bytes: pdfData, filename: filename);
  }
}
