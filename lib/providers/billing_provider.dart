import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/maintenance_bill_model.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';
import '../services/upi_payment_service.dart';
import '../services/pdf_receipt_service.dart';

class BillingProvider extends ChangeNotifier {
  final FirebaseService _fallbackService = FirebaseService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;

  List<MaintenanceBill> _bills = [];
  StreamSubscription<List<MaintenanceBill>>? _billsSubscription;
  bool _isProcessingPayment = false;

  BillingProvider() {
    _bills = List.from(_fallbackService.bills);
    _initLiveFirestoreStream();
  }

  void _initLiveFirestoreStream() {
    try {
      _billsSubscription = _firestoreService.streamAllBills().listen((liveBills) {
        if (liveBills.isNotEmpty) {
          _bills = liveBills;
          notifyListeners();
        }
      }, onError: (e) {
        // Fallback to local service if firestore offline
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _billsSubscription?.cancel();
    super.dispose();
  }

  bool get isProcessingPayment => _isProcessingPayment;
  List<MaintenanceBill> get allBills => _bills.isNotEmpty ? _bills : _fallbackService.bills;

  List<MaintenanceBill> getBillsForFlat(String flatNumber) {
    return allBills.where((b) => b.flatNumber == flatNumber).toList();
  }

  MaintenanceBill? getLatestBillForFlat(String flatNumber) {
    final flatBills = getBillsForFlat(flatNumber);
    if (flatBills.isEmpty) return null;
    flatBills.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    return flatBills.first;
  }

  double getTotalPendingAmountForFlat(String flatNumber) {
    return allBills
        .where((b) => b.flatNumber == flatNumber && !b.isPaid)
        .fold(0.0, (sum, b) => sum + b.totalAmount);
  }

  String getDynamicUpiQrPayload(MaintenanceBill bill) {
    return UpiPaymentService.generateUpiUri(
      upiId: _fallbackService.activeSociety.upiId,
      merchantName: _fallbackService.activeSociety.upiMerchantName,
      amount: bill.totalAmount,
      billId: bill.id,
      flatNumber: bill.flatNumber,
      monthYear: '${bill.billMonth}-${bill.billYear}',
    );
  }

  /// Execute UPI payment (Deep link or scanned QR confirmation)
  /// - Marks bill paid in live Firestore
  /// - Uploads PDF receipt to live Firebase Storage
  /// - Automatically credits live Society Accounting Ledger
  Future<bool> processPayment({
    required String billId,
    required String paymentMode,
    String? utrRef,
  }) async {
    _isProcessingPayment = true;
    notifyListeners();

    final bill = allBills.firstWhere((b) => b.id == billId);
    final ref = utrRef ?? 'UPI-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';

    try {
      // 1. Generate PDF receipt bytes
      final pdfBytes = await getReceiptPdfBytes(bill);

      // 2. Commit to live Firestore and Firebase Storage
      await _firestoreService.completePaymentAndCreditLedger(
        bill: bill,
        paymentRef: ref,
        paymentMode: paymentMode,
        receiptPdfBytes: pdfBytes,
      );
    } catch (e) {
      // Also record in local fallback service
      await _fallbackService.recordMaintenancePayment(
        billId: billId,
        paymentRef: ref,
        paymentMode: paymentMode,
      );
    }

    _isProcessingPayment = false;
    notifyListeners();
    return true;
  }

  /// Generate Monthly Bills for all flats (Admin feature) in live Firestore
  Future<void> generateBillsForMonth({
    required int month,
    required int year,
    required double baseAmount,
    required double sinkingFund,
    required double repairFund,
    required double waterCharges,
    required DateTime dueDate,
  }) async {
    try {
      await _firestoreService.generateMonthlyBillsBatch(
        month: month,
        year: year,
        baseAmount: baseAmount,
        sinkingFund: sinkingFund,
        repairFund: repairFund,
        waterCharges: waterCharges,
        dueDate: dueDate,
      );
    } catch (_) {
      await _fallbackService.generateMonthlyBills(
        month: month,
        year: year,
        baseAmount: baseAmount,
        sinkingFund: sinkingFund,
        repairFund: repairFund,
        waterCharges: waterCharges,
        dueDate: dueDate,
      );
    }
    notifyListeners();
  }

  /// Download or Print PDF Receipt
  Future<void> downloadReceiptPdf(MaintenanceBill bill) async {
    final pdfBytes = await getReceiptPdfBytes(bill);
    final filename = 'Receipt_${bill.flatNumber}_${bill.billMonth}_${bill.billYear}.pdf';
    await PdfReceiptService.printOrShareReceipt(pdfBytes, filename);
  }

  Future<Uint8List> getReceiptPdfBytes(MaintenanceBill bill) async {
    return await PdfReceiptService.generateMaintenanceReceiptPdf(
      bill: bill,
      societyNameEn: _fallbackService.activeSociety.name,
      societyNameMr: _fallbackService.activeSociety.nameMr,
      registrationNo: _fallbackService.activeSociety.registrationNo,
      societyAddress: _fallbackService.activeSociety.address,
      societyUpiId: _fallbackService.activeSociety.upiId,
    );
  }
}
