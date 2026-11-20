import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/society_model.dart';
import '../models/maintenance_bill_model.dart';
import '../models/ledger_entry_model.dart';
import '../models/notice_model.dart';
import '../models/complaint_model.dart';
import '../models/visitor_model.dart';
import '../utils/constants.dart';
import 'firebase_storage_service.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._internal();
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorageService _storage = FirebaseStorageService.instance;

  static const String currentSocietyId = 'society-6ad99';

  // Collection References
  CollectionReference<Map<String, dynamic>> get societiesRef => _db.collection('societies');
  CollectionReference<Map<String, dynamic>> get usersRef => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get billsRef => _db.collection('bills');
  CollectionReference<Map<String, dynamic>> get ledgerRef => _db.collection('accounting_ledger');
  CollectionReference<Map<String, dynamic>> get noticesRef => _db.collection('notices');
  CollectionReference<Map<String, dynamic>> get complaintsRef => _db.collection('complaints');
  CollectionReference<Map<String, dynamic>> get visitorsRef => _db.collection('visitors');

  /// Automatically bootstraps starter society profile and documents in live Firestore if empty
  Future<void> initializeSocietyDefaults() async {
    try {
      final socDoc = await societiesRef.doc(currentSocietyId).get();
      if (!socDoc.exists) {
        final initialSociety = SocietyModel(
          id: currentSocietyId,
          name: AppConstants.defaultSocietyNameEn,
          nameMr: AppConstants.defaultSocietyNameMr,
          registrationNo: AppConstants.defaultRegistrationNo,
          address: 'Plot 42, Senapati Bapat Marg, Dadar West, Mumbai - 400028',
          upiId: AppConstants.defaultSocietyUpiId,
          upiMerchantName: AppConstants.defaultSocietyUpiName,
          bankName: 'State Bank of India (Dadar West)',
          accountNo: '380597262688',
          ifsc: 'SBIN0001234',
          defaultMaintenanceAmount: 2500,
          totalFlats: 72,
        );
        await societiesRef.doc(currentSocietyId).set(initialSociety.toMap());

        // Bootstrap sample ledger
        final sampleLedgers = [
          LedgerEntry(
            id: 'LED-INIT-001',
            societyId: currentSocietyId,
            transactionDate: DateTime.now().subtract(const Duration(days: 2)),
            type: 'expense',
            category: 'cat_security_salary',
            title: 'Security Agency Monthly Salary',
            titleMr: 'सुरक्षा रक्षक एजन्सी मासिक वेतन',
            amount: 38000,
            paymentMode: 'bank',
            voucherNo: 'PV-2026-11-001',
            vendorName: 'Tiger Security Guard Services',
            recordedByUid: 'admin',
          ),
          LedgerEntry(
            id: 'LED-INIT-002',
            societyId: currentSocietyId,
            transactionDate: DateTime.now().subtract(const Duration(days: 4)),
            type: 'expense',
            category: 'cat_common_electricity',
            title: 'MSEDCL Common Meter Electricity Bill',
            titleMr: 'महावितरण सामायिक वीज बिल',
            amount: 14850,
            paymentMode: 'bank',
            voucherNo: 'PV-2026-11-002',
            vendorName: 'MSEDCL Mumbai',
            recordedByUid: 'admin',
          ),
          LedgerEntry(
            id: 'LED-INIT-003',
            societyId: currentSocietyId,
            transactionDate: DateTime.now().subtract(const Duration(days: 1)),
            type: 'income',
            category: 'cat_maintenance_collection',
            title: 'Maintenance Collection - Flat B-201',
            titleMr: 'मासिक देखभाल वर्गणी - B-201',
            amount: 3350,
            paymentMode: 'upi',
            voucherNo: 'RV-2026-11-021',
            vendorName: 'Sunil Patil',
            recordedByUid: 'auto_upi',
          ),
        ];

        for (var l in sampleLedgers) {
          await ledgerRef.doc(l.id).set(l.toMap());
        }

        // Bootstrap sample notices
        final sampleNotice = NoticeModel(
          id: 'NOT-INIT-01',
          societyId: currentSocietyId,
          title: 'Annual General Meeting (AGM) Notice',
          titleMr: 'वार्षिक सर्वसाधारण सभा (AGM) सूचना',
          content: 'The Annual General Meeting of Shivaji Park CHS will be held in the Society Clubhouse. All members are requested to attend.',
          contentMr: 'शिवाजी पार्क हौसिंग सोसायटीची वार्षिक सर्वसाधारण सभा सोसायटी क्लबहाऊसमध्ये आयोजित करण्यात आली आहे.',
          category: 'meeting_agm',
          priority: 'urgent',
          publishedDate: DateTime.now(),
          issuedByName: 'Hon. Secretary',
        );
        await noticesRef.doc(sampleNotice.id).set(sampleNotice.toMap());
      }
    } catch (_) {}
  }

  // ==========================================
  // MODULE 1: USERS & AUTHENTICATION (LIVE)
  // ==========================================
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await usersRef.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!, uid);
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveUserProfile(AppUser user) async {
    await usersRef.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  // =======================================================
  // MODULE 2: MAINTENANCE BILLING & PAYMENTS (LIVE FIRESTORE)
  // =======================================================
  Stream<List<MaintenanceBill>> streamAllBills() {
    return billsRef
        .orderBy('billYear', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => MaintenanceBill.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<MaintenanceBill>> streamBillsForFlat(String flatNumber) {
    return billsRef
        .where('flatNumber', isEqualTo: flatNumber)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => MaintenanceBill.fromMap(d.data(), d.id)).toList());
  }

  Future<void> generateMonthlyBillsBatch({
    required int month,
    required int year,
    required double baseAmount,
    required double sinkingFund,
    required double repairFund,
    required double waterCharges,
    required DateTime dueDate,
  }) async {
    final batch = _db.batch();
    final testFlats = [
      {'flat': 'A-101', 'wing': 'A', 'name': 'Anil Joshi'},
      {'flat': 'A-201', 'wing': 'A', 'name': 'Deepak Sawant'},
      {'flat': 'A-402', 'wing': 'A', 'name': 'Rajesh Arvind Deshmukh'},
      {'flat': 'B-102', 'wing': 'B', 'name': 'Nitin More'},
      {'flat': 'B-201', 'wing': 'B', 'name': 'Sunil Patil'},
      {'flat': 'C-101', 'wing': 'C', 'name': 'Sanjay Shinde'},
      {'flat': 'C-303', 'wing': 'C', 'name': 'Mahesh Kulkarni'},
    ];

    final total = baseAmount + sinkingFund + repairFund + waterCharges;

    for (var f in testFlats) {
      final billId = 'BILL-$year-$month-${f['flat']!.replaceAll('-', '')}';
      final doc = billsRef.doc(billId);

      final bill = MaintenanceBill(
        id: billId,
        societyId: currentSocietyId,
        flatNumber: f['flat']!,
        wing: f['wing']!,
        memberName: f['name']!,
        billMonth: month,
        billYear: year,
        maintenanceAmount: baseAmount,
        sinkingFund: sinkingFund,
        repairFund: repairFund,
        waterCharges: waterCharges,
        totalAmount: total,
        dueDate: dueDate,
        status: 'unpaid',
      );

      batch.set(doc, bill.toMap(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Atomically verify payment, upload receipt PDF to Storage, mark Paid, and credit Accounting Ledger
  Future<void> completePaymentAndCreditLedger({
    required MaintenanceBill bill,
    required String paymentRef,
    required String paymentMode,
    Uint8List? receiptPdfBytes,
  }) async {
    String storageReceiptUrl = '';
    final receiptNo = 'REC-${bill.billYear}-${bill.billMonth.toString().padLeft(2, '0')}-${bill.flatNumber}';

    if (receiptPdfBytes != null) {
      storageReceiptUrl = await _storage.uploadMaintenanceReceiptPdf(
        billId: bill.id,
        pdfBytes: receiptPdfBytes,
      );
    }

    final batch = _db.batch();

    // 1. Mark Bill Paid in Firestore
    final billDoc = billsRef.doc(bill.id);
    batch.update(billDoc, {
      'status': 'paid',
      'paidAt': DateTime.now().toIso8601String(),
      'paymentRef': paymentRef,
      'receiptNumber': receiptNo,
      if (storageReceiptUrl.isNotEmpty) 'receiptPdfUrl': storageReceiptUrl,
    });

    // 2. Automatically credit Society Accounting Ledger in Firestore
    final ledgerId = 'LED-${DateTime.now().millisecondsSinceEpoch}';
    final ledgerDoc = ledgerRef.doc(ledgerId);
    final ledgerEntry = LedgerEntry(
      id: ledgerId,
      societyId: currentSocietyId,
      transactionDate: DateTime.now(),
      type: 'income',
      category: 'cat_maintenance_collection',
      title: 'Maintenance Collection - Flat ${bill.flatNumber}',
      titleMr: 'मासिक देखभाल वर्गणी - फ्लॅट ${bill.flatNumber}',
      amount: bill.totalAmount,
      paymentMode: paymentMode.toLowerCase().contains('upi') ? 'upi' : 'bank',
      voucherNo: 'RV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      vendorName: bill.memberName,
      billAttachmentUrl: storageReceiptUrl,
      relatedBillId: bill.id,
      recordedByUid: 'auto_upi',
      notes: 'Paid via $paymentMode (Ref: $paymentRef)',
    );
    batch.set(ledgerDoc, ledgerEntry.toMap());

    await batch.commit();
  }

  // =======================================================
  // MODULE 3: SOCIETY ACCOUNTING & EXPENSES (LIVE FIRESTORE & STORAGE)
  // =======================================================
  Stream<List<LedgerEntry>> streamLedgerEntries() {
    return ledgerRef
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => LedgerEntry.fromMap(d.data(), d.id)).toList());
  }

  Future<void> recordLedgerEntry({
    required LedgerEntry entry,
    Uint8List? documentBytes,
    String documentExtension = 'jpg',
  }) async {
    String attachmentUrl = entry.billAttachmentUrl;

    if (documentBytes != null && documentBytes.isNotEmpty) {
      attachmentUrl = await _storage.uploadVoucherDocument(
        voucherNo: entry.voucherNo,
        fileBytes: documentBytes,
        fileExtension: documentExtension,
      );
    }

    final entryWithDoc = LedgerEntry(
      id: entry.id,
      societyId: currentSocietyId,
      transactionDate: entry.transactionDate,
      type: entry.type,
      category: entry.category,
      title: entry.title,
      titleMr: entry.titleMr,
      amount: entry.amount,
      paymentMode: entry.paymentMode,
      voucherNo: entry.voucherNo,
      vendorName: entry.vendorName,
      billAttachmentUrl: attachmentUrl,
      relatedBillId: entry.relatedBillId,
      recordedByUid: entry.recordedByUid,
      notes: entry.notes,
    );

    await ledgerRef.doc(entry.id).set(entryWithDoc.toMap());
  }

  // =======================================================
  // MODULE 4: CORE FEATURES (NOTICES, COMPLAINTS, VISITORS)
  // =======================================================
  Stream<List<NoticeModel>> streamNotices() {
    return noticesRef
        .orderBy('publishedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => NoticeModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> postNotice(NoticeModel notice) async {
    await noticesRef.doc(notice.id).set(notice.toMap());
  }

  Stream<List<ComplaintModel>> streamComplaints() {
    return complaintsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => ComplaintModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addComplaint(ComplaintModel complaint) async {
    await complaintsRef.doc(complaint.id).set(complaint.toMap());
  }

  Future<void> updateComplaintStatus(String id, String newStatus, String remarks) async {
    await complaintsRef.doc(id).update({
      'status': newStatus,
      'adminRemarks': remarks,
      'resolvedAt': newStatus == 'resolved' ? DateTime.now().toIso8601String() : null,
    });
  }

  Stream<List<VisitorModel>> streamVisitors() {
    return visitorsRef
        .orderBy('checkInTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => VisitorModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> checkInVisitor(VisitorModel visitor) async {
    await visitorsRef.doc(visitor.id).set(visitor.toMap());
  }

  Future<void> checkOutVisitor(String visitorId) async {
    await visitorsRef.doc(visitorId).update({
      'status': 'checkedOut',
      'checkOutTime': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateVisitorApproval(String visitorId, String approvalStatus) async {
    await visitorsRef.doc(visitorId).update({
      'memberApproval': approvalStatus,
    });
  }
}
