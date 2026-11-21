import 'dart:convert';
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
import '../models/collection_handover_model.dart';
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
  CollectionReference<Map<String, dynamic>> get handoversRef => _db.collection('collection_handovers');

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
    String groupingType = 'wing',
    int superAdminTermMonths = 3,
  }) async {
    final societyId = 'soc_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}';
    
    // Generate 6-digit unique join code (e.g. SOC-849201)
    final randomDigits = (100000 + Random().nextInt(900000)).toString();
    final societyCode = 'SOC-$randomDigits';

    String? logoUrl;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      // 1. Immediately create Base64 data string for 100% offline & instant display
      logoUrl = 'data:image/jpeg;base64,${base64Encode(logoBytes)}';

      // 2. Also attempt Firebase Storage in background if available
      try {
        final storageUrl = await _storage.uploadSocietyLogo(
          societyId: societyId,
          imageBytes: logoBytes,
        );
        if (storageUrl.isNotEmpty && storageUrl.startsWith('http') && !storageUrl.contains('alt=media')) {
          logoUrl = storageUrl;
        }
      } catch (_) {}
    }

    final appointedDate = DateTime.now();
    final nextDueDate = appointedDate.add(Duration(days: 30 * superAdminTermMonths));

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
      superAdminUid: adminUser.uid,
      groupingType: groupingType,
      superAdminTermMonths: superAdminTermMonths,
      superAdminAppointedDate: appointedDate,
      superAdminNextDueDate: nextDueDate,
      defaultMaintenanceAmount: 2000,
      createdAt: DateTime.now(),
    );

    await societiesRef.doc(societyId).set(society.toMap());

    // Update admin user document with super_admin role & approved status
    final updatedAdmin = adminUser.copyWith(
      societyId: societyId,
      societyCode: societyCode,
      role: 'super_admin',
      designation: 'सुपर ॲडमिन (सचिव)',
      isApproved: true,
    );
    await usersRef.doc(adminUser.uid).set(updatedAdmin.toMap());

    activeSocietyId = societyId;
    return society;
  }

  /// Update society settings (Name, address, UPI ID, Bank, Logo, Mobile login toggle)
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
    bool? allowMobileLogin,
  }) async {
    String? logoUrl = currentSociety.logoUrl;
    if (newLogoBytes != null && newLogoBytes.isNotEmpty) {
      // 1. Immediately create Base64 data string for 100% offline & instant display
      logoUrl = 'data:image/jpeg;base64,${base64Encode(newLogoBytes)}';

      // 2. Also attempt Firebase Storage in background
      try {
        final storageUrl = await _storage.uploadSocietyLogo(
          societyId: currentSociety.id,
          imageBytes: newLogoBytes,
        );
        if (storageUrl.isNotEmpty && storageUrl.startsWith('http') && !storageUrl.contains('alt=media')) {
          logoUrl = storageUrl;
        }
      } catch (_) {}
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
      allowMobileLogin: allowMobileLogin,
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

  /// Finds a registered user by phone number for mobile login
  Future<AppUser?> findUserByPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+|-'), '').trim();
    
    // Check clean phone, +91 phone, or last 10 digits
    final queries = [
      cleanPhone,
      '+91$cleanPhone',
      cleanPhone.length >= 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone,
    ];

    for (var p in queries) {
      final snap = await usersRef.where('phoneNumber', isEqualTo: p).limit(1).get();
      if (snap.docs.isNotEmpty) {
        return AppUser.fromMap(snap.docs.first.data(), snap.docs.first.id);
      }
    }
    return null;
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

  /// Stream all approved members of a society (SoftAdmin is completely hidden)
  Stream<List<AppUser>> streamSocietyMembers(String societyId) {
    return usersRef
        .where('societyId', isEqualTo: societyId)
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => AppUser.fromMap(d.data(), d.id))
            .where((u) => !u.isSoftAdmin)
            .toList());
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
    double sinkingFund = 0,
    double repairFund = 0,
    double waterCharges = 0,
    double totalMonthlyExpense = 0,
    double rawShareAmount = 0,
    double roundOffAmount = 0,
    required DateTime dueDate,
    required List<Map<String, String>> flats,
  }) async {
    final batch = _db.batch();
    final flatsCount = flats.isNotEmpty ? flats.length : 1;
    final total = baseAmount > 0 ? baseAmount : (sinkingFund + repairFund + waterCharges);

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
        totalMonthlyExpense: totalMonthlyExpense,
        totalSocietyFlats: flatsCount,
        rawShareAmount: rawShareAmount,
        roundOffAmount: roundOffAmount,
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
    String? paymentProofUrl,
    String? collectedByAdminUid,
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
      'paymentMode': paymentMode,
      'receiptNumber': receiptNo,
      if (storageReceiptUrl.isNotEmpty) 'receiptPdfUrl': storageReceiptUrl,
      if (paymentProofUrl != null && paymentProofUrl.isNotEmpty) 'paymentProofUrl': paymentProofUrl,
      if (collectedByAdminUid != null) 'collectedByAdminUid': collectedByAdminUid,
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

  /// Cancel an expense entry and automatically record negative contra reversal entry (-ve entry)
  /// Also adjusts member bills if bills were generated for that month!
  Future<void> cancelLedgerEntry({
    required String entryId,
    required String reason,
    required String adminUid,
  }) async {
    final doc = await ledgerRef.doc(entryId).get();
    if (!doc.exists) return;
    final original = LedgerEntry.fromMap(doc.data()!, doc.id);
    if (original.isCancelled) return;

    // 1. Mark original entry as cancelled (NEVER hard-deleted from database!)
    await ledgerRef.doc(entryId).update({
      'isCancelled': true,
      'cancellationReason': reason,
      'cancelledAt': DateTime.now().toIso8601String(),
      'cancelledByUid': adminUid,
    });

    // 2. Automatically create negative contra reversal entry (-ve amount)
    final reversalId = 'REV-${DateTime.now().millisecondsSinceEpoch}';
    final reversalEntry = LedgerEntry(
      id: reversalId,
      societyId: original.societyId,
      transactionDate: DateTime.now(),
      type: original.type,
      category: original.category,
      title: 'रद्द: ${original.title}',
      titleMr: 'रद्द खर्च: ${original.titleMr}',
      amount: -original.amount.abs(), // Negative amount!
      paymentMode: original.paymentMode,
      voucherNo: 'REV-${original.voucherNo}',
      vendorName: original.vendorName,
      billAttachmentUrl: original.billAttachmentUrl,
      recordedByUid: adminUid,
      notes: 'मूळ खर्च रद्द केल्यामुळे आपोआप पडलेली विरुद्ध नोंद (Contra Entry). कारण: $reason',
      isReversal: true,
      isCancelled: false,
    );
    await ledgerRef.doc(reversalId).set(reversalEntry.toMap());

    // 3. Automatically apply negative credit adjustment across all members' bills for that month/year
    try {
      final billsSnap = await billsRef
          .where('societyId', isEqualTo: original.societyId)
          .where('billMonth', isEqualTo: original.transactionDate.month)
          .where('billYear', isEqualTo: original.transactionDate.year)
          .get();

      if (billsSnap.docs.isNotEmpty) {
        final flatsCount = billsSnap.docs.length;
        final perFlatCredit = (original.amount / flatsCount).roundToDouble();
        for (var bDoc in billsSnap.docs) {
          final currentAdj = (bDoc.data()['adjustments'] as num?)?.toDouble() ?? 0.0;
          await billsRef.doc(bDoc.id).update({
            'adjustments': currentAdj + perFlatCredit,
          });
        }
      }
    } catch (_) {}
  }

  // =======================================================
  // MODULE: COLLECTION HANDOVER & COMMITTEE APPOINTMENTS
  // =======================================================

  Stream<List<CollectionHandover>> streamCollectionHandovers(String societyId) {
    return handoversRef
        .where('societyId', isEqualTo: societyId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((d) => CollectionHandover.fromMap(d.data(), d.id)).toList();
          list.sort((a, b) => b.handoverDate.compareTo(a.handoverDate));
          return list;
        });
  }

  Future<void> recordCollectionHandover({
    required CollectionHandover handover,
    Uint8List? proofBytes,
  }) async {
    String proofUrl = handover.proofPhotoUrl;
    if (proofBytes != null && proofBytes.isNotEmpty) {
      proofUrl = 'data:image/jpeg;base64,${base64Encode(proofBytes)}';
    }
    final docId = handover.id.isNotEmpty ? handover.id : 'hnd_${DateTime.now().millisecondsSinceEpoch}';
    final entry = CollectionHandover(
      id: docId,
      societyId: handover.societyId,
      groupAdminUid: handover.groupAdminUid,
      groupAdminName: handover.groupAdminName,
      assignedGroup: handover.assignedGroup,
      totalAmount: handover.totalAmount,
      paymentMode: handover.paymentMode,
      proofPhotoUrl: proofUrl,
      handoverDate: handover.handoverDate,
      notes: handover.notes,
      status: 'pending',
    );
    await handoversRef.doc(docId).set(entry.toMap());
  }

  Future<void> approveCollectionHandover({
    required String handoverId,
    required String superAdminUid,
    required String superAdminName,
  }) async {
    await handoversRef.doc(handoverId).update({
      'status': 'approved',
      'verifiedByUid': superAdminUid,
      'verifiedByName': superAdminName,
      'verifiedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> appointNewSuperAdmin({
    required String societyId,
    required String newSuperAdminUid,
    required int termMonths,
    required String appointedByUid,
  }) async {
    final appointedDate = DateTime.now();
    final nextDueDate = appointedDate.add(Duration(days: 30 * termMonths));
    await societiesRef.doc(societyId).update({
      'superAdminUid': newSuperAdminUid,
      'superAdminTermMonths': termMonths,
      'superAdminAppointedDate': appointedDate.toIso8601String(),
      'superAdminNextDueDate': nextDueDate.toIso8601String(),
    });

    await usersRef.doc(newSuperAdminUid).update({
      'role': 'super_admin',
      'designation': 'सुपर ॲडमिन (सचिव)',
    });
  }

  Future<void> assignMemberRole({
    required String uid,
    required String role, // 'chairman', 'super_admin', 'group_admin', 'member'
    String? assignedGroup,
    String? designation,
  }) async {
    final updates = <String, dynamic>{
      'role': role,
      if (assignedGroup != null) 'assignedGroup': assignedGroup,
      if (designation != null) 'designation': designation,
    };
    await usersRef.doc(uid).update(updates);
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

  // =======================================================
  // MODULE: SOFTADMIN MASTER CONTROLS (UNDOCUMENTED / HIDDEN)
  // =======================================================

  /// Fetch all registered societies for SoftAdmin switching
  Future<List<SocietyModel>> getAllSocieties() async {
    try {
      final snap = await societiesRef.get();
      return snap.docs.map((d) => SocietyModel.fromMap(d.data(), d.id)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Permanently hard-delete a single ledger entry (+ve or -ve contra)
  Future<void> softAdminHardDeleteLedgerEntry(String entryId) async {
    await ledgerRef.doc(entryId).delete();
  }

  /// SoftAdmin edit/modify ledger entry fields (amount, type, notes, etc.)
  Future<void> softAdminUpdateLedgerEntry({
    required String entryId,
    required Map<String, dynamic> data,
  }) async {
    await ledgerRef.doc(entryId).update(data);
  }

  /// Permanently delete a maintenance bill
  Future<void> softAdminHardDeleteBill(String billId) async {
    await billsRef.doc(billId).delete();
  }

  /// Permanently delete a collection handover
  Future<void> softAdminHardDeleteHandover(String handoverId) async {
    await handoversRef.doc(handoverId).delete();
  }

  /// Master Action: Blank / Wipe all transaction data for a society
  /// (Clears all ledger entries, member bills, and collection handovers)
  Future<void> softAdminBlankAllTransactions(String societyId) async {
    // 1. Delete all ledger entries
    final ledgerSnap = await ledgerRef.where('societyId', isEqualTo: societyId).get();
    for (var doc in ledgerSnap.docs) {
      await doc.reference.delete();
    }

    // 2. Delete all maintenance bills
    final billsSnap = await billsRef.where('societyId', isEqualTo: societyId).get();
    for (var doc in billsSnap.docs) {
      await doc.reference.delete();
    }

    // 3. Delete all collection handovers
    final handoversSnap = await handoversRef.where('societyId', isEqualTo: societyId).get();
    for (var doc in handoversSnap.docs) {
      await doc.reference.delete();
    }
  }
}
