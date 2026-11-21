import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/society_model.dart';
import '../models/maintenance_bill_model.dart';
import '../models/ledger_entry_model.dart';
import '../models/notice_model.dart';
import '../models/complaint_model.dart';
import '../models/visitor_model.dart';
import 'firebase_storage_service.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._internal();
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorageService _storage = FirebaseStorageService.instance;

  String? activeSocietyId;

  // Collection References
  CollectionReference<Map<String, dynamic>> get societiesRef => _db.collection('societies');
  CollectionReference<Map<String, dynamic>> get usersRef => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get billsRef => _db.collection('bills');
  CollectionReference<Map<String, dynamic>> get ledgerRef => _db.collection('accounting_ledger');
  CollectionReference<Map<String, dynamic>> get noticesRef => _db.collection('notices');
  CollectionReference<Map<String, dynamic>> get complaintsRef => _db.collection('complaints');
  CollectionReference<Map<String, dynamic>> get visitorsRef => _db.collection('visitors');

  // =======================================================
  // MULTI-TENANT ONBOARDING & SOCIETY MANAGEMENT
  // =======================================================

  /// Creates a new society with optional logo and assigns creator as Admin
  Future<SocietyModel> createSociety({
    required String name,
    required String nameMr,
    required String address,
    required String city,
    required String pincode,
    required String registrationNo,
    required List<String> wings,
    required int totalFlats,
    required AppUser adminUser,
    Uint8List? logoBytes,
  }) async {
    final societyId = 'soc_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}';
    
    // Generate 6-digit unique join code (e.g. SOC-849201)
    final randomDigits = (100000 + Random().nextInt(900000)).toString();
    final societyCode = 'SOC-$randomDigits';

    String? logoUrl;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      logoUrl = await _storage.uploadSocietyLogo(
        societyId: societyId,
        imageBytes: logoBytes,
      );
    }

    final society = SocietyModel(
      id: societyId,
      societyCode: societyCode,
      name: name,
      nameMr: nameMr.isNotEmpty ? nameMr : name,
      address: address,
      city: city,
      pincode: pincode,
      registrationNo: registrationNo,
      wings: wings.isNotEmpty ? wings : ['A', 'B'],
      totalFlats: totalFlats > 0 ? totalFlats : 40,
      logoUrl: logoUrl,
      adminUid: adminUser.uid,
      defaultMaintenanceAmount: 2000,
      createdAt: DateTime.now(),
    );

    await societiesRef.doc(societyId).set(society.toMap());

    // Update admin user document with admin role & approved status
    final updatedAdmin = adminUser.copyWith(
      societyId: societyId,
      societyCode: societyCode,
      role: 'admin',
      isApproved: true,
    );
    await usersRef.doc(adminUser.uid).set(updatedAdmin.toMap());

    activeSocietyId = societyId;
    return society;
  }

  /// Update society settings (Name, address, UPI ID, Bank, Logo)
  Future<SocietyModel> updateSocietySettings({
    required SocietyModel currentSociety,
    String? name,
    String? nameMr,
    String? address,
    String? city,
    String? pincode,
    String? upiId,
    String? upiMerchantName,
    String? bankName,
    String? accountNo,
    String? ifsc,
    double? defaultMaintenanceAmount,
    Uint8List? newLogoBytes,
  }) async {
    String? logoUrl = currentSociety.logoUrl;
    if (newLogoBytes != null && newLogoBytes.isNotEmpty) {
      logoUrl = await _storage.uploadSocietyLogo(
        societyId: currentSociety.id,
        imageBytes: newLogoBytes,
      );
    }

    final updated = currentSociety.copyWith(
      name: name,
      nameMr: nameMr,
      address: address,
      city: city,
      pincode: pincode,
      upiId: upiId,
      upiMerchantName: upiMerchantName,
      bankName: bankName,
      accountNo: accountNo,
      ifsc: ifsc,
      defaultMaintenanceAmount: defaultMaintenanceAmount,
      logoUrl: logoUrl,
    );

    await societiesRef.doc(currentSociety.id).set(updated.toMap(), SetOptions(merge: true));
    return updated;
  }

  /// Finds society by 6-digit societyCode
  Future<SocietyModel?> findSocietyByCode(String code) async {
    final query = await societiesRef
        .where('societyCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return SocietyModel.fromMap(doc.data(), doc.id);
  }

  /// Fetch society details by ID
  Future<SocietyModel?> getSociety(String societyId) async {
    final doc = await societiesRef.doc(societyId).get();
    if (!doc.exists || doc.data() == null) return null;
    return SocietyModel.fromMap(doc.data()!, doc.id);
  }

  // =======================================================
  // USER & MEMBERSHIP MANAGEMENT
  // =======================================================

  /// Save or update user profile
  Future<void> saveUser(AppUser user) async {
    await usersRef.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  /// Fetch user profile by UID
  Future<AppUser?> getUser(String uid) async {
    final doc = await usersRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(doc.data()!, doc.id);
  }

  /// Submits a request to join an existing society (awaits admin approval)
  Future<void> submitJoinRequest({
    required AppUser user,
    required String societyId,
    required String societyCode,
    required String role,
    required String wing,
    required String flatNumber,
    String? phoneNumber,
  }) async {
    final joinRequest = user.copyWith(
      societyId: societyId,
      societyCode: societyCode,
      role: role,
      wing: wing,
      flatNumber: flatNumber,
      phoneNumber: phoneNumber ?? user.phoneNumber,
      isApproved: false, // Must be approved by Admin
    );

    await usersRef.doc(user.uid).set(joinRequest.toMap(), SetOptions(merge: true));
  }

  /// Stream pending member join requests for admin approval
  Stream<List<AppUser>> streamPendingApprovals(String societyId) {
    return usersRef
        .where('societyId', isEqualTo: societyId)
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => AppUser.fromMap(d.data(), d.id)).toList());
  }

  /// Admin approves pending member
  Future<void> approveMember(String uid, {String? role, String? wing, String? flatNumber}) async {
    final updates = <String, dynamic>{
      'isApproved': true,
      if (role != null) 'role': role,
      if (wing != null) 'wing': wing,
      if (flatNumber != null) 'flatNumber': flatNumber,
    };
    await usersRef.doc(uid).update(updates);
  }

  /// Admin rejects pending member
  Future<void> rejectMember(String uid) async {
    await usersRef.doc(uid).delete();
  }

  /// Stream all approved members of a society
  Stream<List<AppUser>> streamSocietyMembers(String societyId) {
    return usersRef
        .where('societyId', isEqualTo: societyId)
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => AppUser.fromMap(d.data(), d.id)).toList());
  }

  // =======================================================
  // MODULE 2: MAINTENANCE BILLING & PAYMENTS
  // =======================================================

  Stream<List<MaintenanceBill>> streamMaintenanceBills({
    required String societyId,
    String? flatNumber,
  }) {
    Query<Map<String, dynamic>> query = billsRef.where('societyId', isEqualTo: societyId);

    if (flatNumber != null && flatNumber.isNotEmpty) {
      query = query.where('flatNumber', isEqualTo: flatNumber);
    }

    return query
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => MaintenanceBill.fromMap(d.data(), d.id)).toList());
  }

  Future<void> generateMonthlyBillsBatch({
    required String societyId,
    required int month,
    required int year,
    required double baseAmount,
    required double sinkingFund,
    required double repairFund,
    required double waterCharges,
    required DateTime dueDate,
    required List<Map<String, String>> flats,
  }) async {
    final batch = _db.batch();
    final total = baseAmount + sinkingFund + repairFund + waterCharges;

    for (var f in flats) {
      final flat = f['flat'] ?? '';
      final wing = f['wing'] ?? '';
      final name = f['name'] ?? 'Flat Member';
      if (flat.isEmpty) continue;

      final billId = 'BILL-$year-$month-${flat.replaceAll('-', '')}';
      final doc = billsRef.doc(billId);

      final bill = MaintenanceBill(
        id: billId,
        societyId: societyId,
        flatNumber: flat,
        wing: wing,
        memberName: name,
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

  /// Complete payment, upload receipt PDF, and credit accounting ledger
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
      societyId: bill.societyId,
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
  // MODULE 3: SOCIETY ACCOUNTING & EXPENSES
  // =======================================================

  Stream<List<LedgerEntry>> streamLedgerEntries(String societyId) {
    return ledgerRef
        .where('societyId', isEqualTo: societyId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((d) => LedgerEntry.fromMap(d.data(), d.id)).toList();
          list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
          return list;
        });
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
      societyId: entry.societyId,
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
  // MODULE 4: NOTICES, COMPLAINTS, VISITORS
  // =======================================================

  Stream<List<NoticeModel>> streamNotices(String societyId) {
    return noticesRef
        .where('societyId', isEqualTo: societyId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((d) => NoticeModel.fromMap(d.data(), d.id)).toList();
          list.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
          return list;
        });
  }

  Future<void> postNotice(NoticeModel notice) async {
    await noticesRef.doc(notice.id).set(notice.toMap());
  }

  Stream<List<ComplaintModel>> streamComplaints(String societyId, {String? flatNumber}) {
    Query<Map<String, dynamic>> query = complaintsRef.where('societyId', isEqualTo: societyId);

    if (flatNumber != null && flatNumber.isNotEmpty) {
      query = query.where('flatNumber', isEqualTo: flatNumber);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((d) => ComplaintModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
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

  Stream<List<VisitorModel>> streamVisitors(String societyId) {
    return visitorsRef
        .where('societyId', isEqualTo: societyId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((d) => VisitorModel.fromMap(d.data(), d.id)).toList();
          list.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
          return list;
        });
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
