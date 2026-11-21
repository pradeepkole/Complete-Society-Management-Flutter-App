import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/maintenance_bill_model.dart';
import '../services/firestore_service.dart';
import '../services/upi_payment_service.dart';
import '../services/pdf_receipt_service.dart';

class BillingProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService.instance;

  String? _societyId;
  List<MaintenanceBill> _bills = [];
  StreamSubscription<List<MaintenanceBill>>? _billsSubscription;
  bool _isProcessingPayment = false;

  BillingProvider();

  void setSocietyId(String societyId) {
    if (_societyId == societyId) return;
    _societyId = societyId;
    _billsSubscription?.cancel();

    _billsSubscription = _firestoreService
        .streamMaintenanceBills(societyId: societyId)
        .listen((liveBills) {
      _bills = liveBills;
      notifyListeners();
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _billsSubscription?.cancel();
    super.dispose();
  }

  bool get isProcessingPayment => _isProcessingPayment;
  List<MaintenanceBill> get allBills => _bills;

  List<MaintenanceBill> getBillsForFlat(String flatNumber) {
    return _bills.where((b) => b.flatNumber == flatNumber).toList();
  }

  MaintenanceBill? getLatestBillForFlat(String flatNumber) {
    final flatBills = getBillsForFlat(flatNumber);
    if (flatBills.isEmpty) return null;
    flatBills.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    return flatBills.first;
  }

  double getTotalPendingAmount() {
    return _bills
        .where((b) => b.status == 'unpaid')
        .fold(0.0, (sum, b) => sum + b.totalAmount);
  }

  double getTotalCollectedAmount() {
    return _bills
        .where((b) => b.status == 'paid')
        .fold(0.0, (sum, b) => sum + b.totalAmount);
  }

  int getPendingCount() => _bills.where((b) => b.status == 'unpaid').length;
  int getPaidCount() => _bills.where((b) => b.status == 'paid').length;

  Future<void> generateBillsForMonth({
    required int month,
    required int year,
    required double baseAmount,
    required double sinkingFund,
    required double repairFund,
    required double waterCharges,
    required DateTime dueDate,
    String? societyId,
    List<Map<String, String>>? flats,
  }) async {
    final targetSocietyId = societyId ?? _societyId;
    if (targetSocietyId == null) return;

    List<Map<String, String>> targetFlats = flats ?? [];
    if (targetFlats.isEmpty) {
      final society = await _firestoreService.getSociety(targetSocietyId);
      final wings = society?.wings ?? ['A', 'B'];
      final flatsPerWing = ((society?.totalFlats ?? 20) / wings.length).ceil();
      for (var w in wings) {
        for (int i = 1; i <= flatsPerWing; i++) {
          final floor = (i - 1) ~/ 4 + 1;
          final unit = (i - 1) % 4 + 1;
          final flatNum = '$w-${floor}0$unit';
          targetFlats.add({'flat': flatNum, 'wing': w, 'name': 'Resident $flatNum'});
        }
      }
    }

    await _firestoreService.generateMonthlyBillsBatch(
      societyId: targetSocietyId,
      month: month,
      year: year,
      baseAmount: baseAmount,
      sinkingFund: sinkingFund,
      repairFund: repairFund,
      waterCharges: waterCharges,
      dueDate: dueDate,
      flats: targetFlats,
    );
  }

  Future<void> processPayment({
    required String billId,
    required String paymentMode,
    required String utrRef,
  }) async {
    final bill = _bills.firstWhere((b) => b.id == billId);
    await _firestoreService.completePaymentAndCreditLedger(
      bill: bill,
      paymentRef: utrRef,
      paymentMode: paymentMode,
    );
  }

  /// Group Admin records member payment (Cash with receipt photo or UPI with screenshot)
  Future<void> recordMemberPaymentByAdmin({
    required MaintenanceBill bill,
    required String paymentMode, // 'cash' or 'upi'
    required String utrRef,
    Uint8List? proofBytes,
    required String adminUid,
  }) async {
    String? proofUrl;
    if (proofBytes != null && proofBytes.isNotEmpty) {
      proofUrl = 'data:image/jpeg;base64,${base64Encode(proofBytes)}';
    }

    await _firestoreService.completePaymentAndCreditLedger(
      bill: bill,
      paymentRef: utrRef,
      paymentMode: paymentMode,
      paymentProofUrl: proofUrl,
      collectedByAdminUid: adminUid,
    );
  }

  /// Generate monthly maintenance bills divided equally from actual recorded expenses + Round Off
  Future<void> generateBillsBasedOnActualExpenses({
    required int month,
    required int year,
    required DateTime dueDate,
    required double totalActualExpense,
    String? societyId,
    List<Map<String, String>>? flats,
  }) async {
    final targetSocietyId = societyId ?? _societyId;
    if (targetSocietyId == null) return;

    List<Map<String, String>> targetFlats = flats ?? [];
    if (targetFlats.isEmpty) {
      final society = await _firestoreService.getSociety(targetSocietyId);
      final wings = society?.wings ?? ['A', 'B'];
      final flatsPerWing = ((society?.totalFlats ?? 20) / wings.length).ceil();
      for (var w in wings) {
        for (int i = 1; i <= flatsPerWing; i++) {
          final floor = (i - 1) ~/ 4 + 1;
          final unit = (i - 1) % 4 + 1;
          final flatNum = '$w-${floor}0$unit';
          targetFlats.add({'flat': flatNum, 'wing': w, 'name': 'Resident $flatNum'});
        }
      }
    }

    final flatsCount = targetFlats.isNotEmpty ? targetFlats.length : 1;
    final rawShare = totalActualExpense / flatsCount;
    final roundedShare = rawShare.roundToDouble();
    final roundOff = roundedShare - rawShare;

    await _firestoreService.generateMonthlyBillsBatch(
      societyId: targetSocietyId,
      month: month,
      year: year,
      baseAmount: roundedShare,
      totalMonthlyExpense: totalActualExpense,
      rawShareAmount: rawShare,
      roundOffAmount: roundOff,
      dueDate: dueDate,
      flats: targetFlats,
    );
  }

  Future<bool> processUpiPayment({
    required MaintenanceBill bill,
    required String upiId,
    required String merchantName,
    required BuildContext context,
    required String societyNameEn,
    required String societyNameMr,
    required String registrationNo,
    required String societyAddress,
  }) async {
    _isProcessingPayment = true;
    notifyListeners();

    try {
      final success = await UpiPaymentService.launchUpiPayment(
        payeeVpa: upiId,
        payeeName: merchantName,
        transactionNote: 'Maint-${bill.billMonth}/${bill.billYear}-Flat${bill.flatNumber}',
        amount: bill.totalAmount,
      );

      final dummyRef = 'UPI-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      final pdfBytes = await PdfReceiptService.generateMaintenanceReceiptPdf(
        bill: bill.copyWith(
          status: 'paid',
          paidAt: DateTime.now(),
          paymentRef: dummyRef,
        ),
        societyNameEn: societyNameEn,
        societyNameMr: societyNameMr,
        registrationNo: registrationNo,
        societyAddress: societyAddress,
        societyUpiId: upiId,
      );

      await _firestoreService.completePaymentAndCreditLedger(
        bill: bill,
        paymentRef: dummyRef,
        paymentMode: 'UPI Instant App',
        receiptPdfBytes: pdfBytes,
      );

      _isProcessingPayment = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isProcessingPayment = false;
      notifyListeners();
      return false;
    }
  }

  Future<Uint8List> generateReceiptPdf({
    required MaintenanceBill bill,
    required String societyNameEn,
    required String societyNameMr,
    required String registrationNo,
    required String societyAddress,
    required String societyUpiId,
  }) async {
    return await PdfReceiptService.generateMaintenanceReceiptPdf(
      bill: bill,
      societyNameEn: societyNameEn,
      societyNameMr: societyNameMr,
      registrationNo: registrationNo,
      societyAddress: societyAddress,
      societyUpiId: societyUpiId,
    );
  }

  String getDynamicUpiQrPayload(
    MaintenanceBill bill, {
    String? upiId,
    String? merchantName,
  }) {
    return UpiPaymentService.generateUpiUri(
      upiId: upiId ?? 'society@oksbi',
      merchantName: merchantName ?? 'Society Maintenance',
      amount: bill.totalAmount,
      billId: bill.id,
      flatNumber: bill.flatNumber,
      monthYear: '${bill.billMonth}/${bill.billYear}',
    );
  }

  Future<void> downloadReceiptPdf(
    MaintenanceBill bill, {
    String? societyName,
    String? societyAddress,
    String? upiId,
  }) async {
    final pdfBytes = await PdfReceiptService.generateMaintenanceReceiptPdf(
      bill: bill,
      societyNameEn: societyName ?? 'Housing Society',
      societyNameMr: 'गृहनिर्माण संस्था',
      registrationNo: 'REG-${_societyId ?? "MUMBAI"}',
      societyAddress: societyAddress ?? 'Maharashtra, India',
      societyUpiId: upiId ?? 'society@oksbi',
    );
    await PdfReceiptService.printOrShareReceipt(
      pdfBytes,
      'Receipt_${bill.flatNumber}_${bill.billMonth}_${bill.billYear}.pdf',
    );
  }
}
