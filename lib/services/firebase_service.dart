import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/society_model.dart';
import '../models/maintenance_bill_model.dart';
import '../models/ledger_entry_model.dart';
import '../models/notice_model.dart';
import '../models/complaint_model.dart';
import '../models/visitor_model.dart';
import '../utils/constants.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();
  FirebaseService._internal() {
    _initializeSeedData();
  }

  // Active Society Metadata
  late SocietyModel activeSociety;

  // In-Memory collections (synced with Firestore when available)
  final List<AppUser> _users = [];
  final List<MaintenanceBill> _bills = [];
  final List<LedgerEntry> _ledger = [];
  final List<NoticeModel> _notices = [];
  final List<ComplaintModel> _complaints = [];
  final List<VisitorModel> _visitors = [];

  void _initializeSeedData() {
    activeSociety = SocietyModel(
      id: AppConstants.defaultSocietyId,
      name: AppConstants.defaultSocietyNameEn,
      nameMr: AppConstants.defaultSocietyNameMr,
      registrationNo: AppConstants.defaultRegistrationNo,
      address: 'Plot 42, Senapati Bapat Marg, Dadar West, Mumbai - 400028',
      upiId: AppConstants.defaultSocietyUpiId,
      upiMerchantName: AppConstants.defaultSocietyUpiName,
      bankName: 'State Bank of India (Dadar West)',
      accountNo: '30491827364',
      ifsc: 'SBIN0001234',
      defaultMaintenanceAmount: 2500,
      totalFlats: 72,
    );

    // Default Seed Users (for Admin, Member, Guard)
    _users.addAll([
      AppUser(
        uid: 'usr_admin_01',
        name: 'Anil Joshi (Secretary)',
        nameMr: 'अनिल जोशी (सचिव)',
        phoneNumber: '+919820011223',
        email: 'secretary.shivaji@chs.in',
        role: 'admin',
        residentType: 'owner',
        flatNumber: 'A-101',
        wing: 'A',
        societyId: activeSociety.id,
      ),
      AppUser(
        uid: 'usr_member_01',
        name: 'Rajesh Arvind Deshmukh',
        nameMr: 'राजेश अरविंद देशमुख',
        phoneNumber: '+919820334455',
        email: 'rajesh.deshmukh@gmail.com',
        role: 'member',
        residentType: 'owner',
        flatNumber: 'A-402',
        wing: 'A',
        societyId: activeSociety.id,
      ),
      AppUser(
        uid: 'usr_guard_01',
        name: 'Ramesh Shinde (Security Guard)',
        nameMr: 'रमेश शिंदे (सुरक्षा रक्षक)',
        phoneNumber: '+919820556677',
        email: 'security.gate@chs.in',
        role: 'guard',
        residentType: 'committee',
        flatNumber: '',
        wing: '',
        societyId: activeSociety.id,
      ),
    ]);

    // Initial Maintenance Bills
    _bills.addAll([
      MaintenanceBill(
        id: 'BILL-2026-11-A402',
        societyId: activeSociety.id,
        flatNumber: 'A-402',
        wing: 'A',
        memberName: 'Rajesh Arvind Deshmukh',
        billMonth: 11,
        billYear: 2026,
        maintenanceAmount: 2500,
        sinkingFund: 300,
        repairFund: 200,
        waterCharges: 350,
        latePenalty: 0,
        totalAmount: 3350,
        dueDate: DateTime.now().add(const Duration(days: 10)),
        status: 'unpaid',
      ),
      MaintenanceBill(
        id: 'BILL-2026-10-A402',
        societyId: activeSociety.id,
        flatNumber: 'A-402',
        wing: 'A',
        memberName: 'Rajesh Arvind Deshmukh',
        billMonth: 10,
        billYear: 2026,
        maintenanceAmount: 2500,
        sinkingFund: 300,
        repairFund: 200,
        waterCharges: 350,
        latePenalty: 0,
        totalAmount: 3350,
        dueDate: DateTime.now().subtract(const Duration(days: 20)),
        status: 'paid',
        paidAt: DateTime.now().subtract(const Duration(days: 22)),
        paymentRef: 'UPI-432890123456',
        receiptNumber: 'REC-2026-10-042',
      ),
      MaintenanceBill(
        id: 'BILL-2026-11-B201',
        societyId: activeSociety.id,
        flatNumber: 'B-201',
        wing: 'B',
        memberName: 'Sunil Patil',
        billMonth: 11,
        billYear: 2026,
        maintenanceAmount: 2500,
        sinkingFund: 300,
        repairFund: 200,
        waterCharges: 350,
        latePenalty: 0,
        totalAmount: 3350,
        dueDate: DateTime.now().add(const Duration(days: 10)),
        status: 'paid',
        paidAt: DateTime.now().subtract(const Duration(days: 2)),
        paymentRef: 'UPI-432890987654',
        receiptNumber: 'REC-2026-11-021',
      ),
      MaintenanceBill(
        id: 'BILL-2026-11-C303',
        societyId: activeSociety.id,
        flatNumber: 'C-303',
        wing: 'C',
        memberName: 'Mahesh Kulkarni',
        billMonth: 11,
        billYear: 2026,
        maintenanceAmount: 2500,
        sinkingFund: 300,
        repairFund: 200,
        waterCharges: 350,
        latePenalty: 150,
        totalAmount: 3500,
        dueDate: DateTime.now().subtract(const Duration(days: 5)),
        status: 'overdue',
      ),
    ]);

    // Initial Society Ledger Entries (Expenses & Incomes)
    _ledger.addAll([
      LedgerEntry(
        id: 'LED-001',
        societyId: activeSociety.id,
        transactionDate: DateTime.now().subtract(const Duration(days: 1)),
        type: 'expense',
        category: 'cat_security_salary',
        title: 'Security Agency Salary - Oct 2026',
        titleMr: 'सुरक्षा रक्षक एजन्सी वेतन - ऑक्टोबर २०२६',
        amount: 38000,
        paymentMode: 'bank',
        voucherNo: 'PV-2026-11-001',
        vendorName: 'Tiger Security Guard Services Pvt Ltd',
        billAttachmentUrl: 'https://images.unsplash.com/photo-1554415707-9e49016a3e5c?w=400',
        recordedByUid: 'usr_admin_01',
      ),
      LedgerEntry(
        id: 'LED-002',
        societyId: activeSociety.id,
        transactionDate: DateTime.now().subtract(const Duration(days: 3)),
        type: 'expense',
        category: 'cat_common_electricity',
        title: 'Common Meter Electricity Bill (MSEB)',
        titleMr: 'सामायिक वीज देयक (महावितरण बिल)',
        amount: 14850,
        paymentMode: 'bank',
        voucherNo: 'PV-2026-11-002',
        vendorName: 'MSEDCL Mumbai',
        billAttachmentUrl: 'https://images.unsplash.com/photo-1586769852044-692d6e3703f0?w=400',
        recordedByUid: 'usr_admin_01',
      ),
      LedgerEntry(
        id: 'LED-003',
        societyId: activeSociety.id,
        transactionDate: DateTime.now().subtract(const Duration(days: 5)),
        type: 'expense',
        category: 'cat_water_tanker',
        title: 'Emergency Drinking Water Tanker (3 Trips)',
        titleMr: 'पिण्याचे पाण्याचे टँकर (३ खेपा)',
        amount: 5400,
        paymentMode: 'cash',
        voucherNo: 'PV-2026-11-003',
        vendorName: 'Mauli Water Suppliers',
        billAttachmentUrl: 'https://images.unsplash.com/photo-1526304640581-d334cdbbf45e?w=400',
        recordedByUid: 'usr_admin_01',
      ),
      LedgerEntry(
        id: 'LED-004',
        societyId: activeSociety.id,
        transactionDate: DateTime.now().subtract(const Duration(days: 2)),
        type: 'income',
        category: 'cat_maintenance_collection',
        title: 'Maintenance Collection - Flat B-201',
        titleMr: 'मासिक देखभाल वर्गणी - फ्लॅट B-201',
        amount: 3350,
        paymentMode: 'upi',
        voucherNo: 'RV-2026-11-021',
        vendorName: 'Sunil Patil',
        relatedBillId: 'BILL-2026-11-B201',
        recordedByUid: 'auto_upi',
      ),
      LedgerEntry(
        id: 'LED-005',
        societyId: activeSociety.id,
        transactionDate: DateTime.now().subtract(const Duration(days: 6)),
        type: 'income',
        category: 'cat_clubhouse_rent',
        title: 'Clubhouse Birthday Booking - Flat C-102',
        titleMr: 'क्लबहाऊस वाढदिवस समारंभ बुकिंग - C-102',
        amount: 5000,
        paymentMode: 'upi',
        voucherNo: 'RV-2026-11-005',
        vendorName: 'Pravin Shirodkar',
        recordedByUid: 'usr_admin_01',
      ),
      LedgerEntry(
        id: 'LED-006',
        societyId: activeSociety.id,
        transactionDate: DateTime.now().subtract(const Duration(days: 8)),
        type: 'expense',
        category: 'cat_lift_maintenance',
        title: 'Otis Elevator Quarterly AMC Service',
        titleMr: 'ओटिस लिफ्ट त्रैमासिक देखभाल (AMC)',
        amount: 12500,
        paymentMode: 'bank',
        voucherNo: 'PV-2026-11-004',
        vendorName: 'Otis Elevators India',
        billAttachmentUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=400',
        recordedByUid: 'usr_admin_01',
      ),
    ]);

    // Initial Digital Notices
    _notices.addAll([
      NoticeModel(
        id: 'NOT-01',
        societyId: activeSociety.id,
        title: 'Annual General Meeting (AGM) Notice',
        titleMr: 'वार्षिक सर्वसाधारण सभा (AGM) सूचना',
        content: 'The Annual General Meeting of Shivaji Park CHS will be held on Sunday, 29th November 2026 at 10:30 AM in the Society Clubhouse. Agenda includes presentation of Audited Financial Statement, building painting tender, and Diwali bonus for society staff. All members are requested to attend.',
        contentMr: 'शिवाजी पार्क सहकारी गृहनिर्माण संस्थेची वार्षिक सर्वसाधारण सभा रविवार, २९ नोव्हेंबर २०२६ रोजी सकाळी १०:३० वाजता सोसायटी क्लबहाऊसमध्ये आयोजित करण्यात आली आहे. विषयांमध्ये वार्षिक ऑडिट हिशोब तपासणी अहवाल मंजुरी, इमारतीचे रंगकाम टेंडर, व कर्मचाऱ्यांचा बोनस यावर चर्चा होईल. सर्व सदस्यांनी वेळेवर उपस्थित राहावे.',
        category: 'meeting_agm',
        priority: 'urgent',
        publishedDate: DateTime.now().subtract(const Duration(days: 2)),
        issuedByName: 'Anil Joshi (Hon. Secretary)',
      ),
      NoticeModel(
        id: 'NOT-02',
        societyId: activeSociety.id,
        title: 'BMC Water Pipeline Maintenance Schedule',
        titleMr: 'महापालिका पाणीपुरवठा पाईप दुरुस्ती वेळापत्रक',
        content: 'Please note that BMC has scheduled main pipeline repair work this Friday. Society water supply will be restricted between 2:00 PM and 7:00 PM. Kindly store sufficient water in advance.',
        contentMr: 'कृपया नोंद घ्यावी की महापालिकेचे मुख्य पाईपलाईन दुरुस्ती काम या शुक्रवारी होणार आहे. त्यामुळे सोसायटीचा पाणीपुरवठा दुपारी २ ते संध्याकाळी ७ या वेळेत बंद राहील. कृपया पुरेसे पाणी साठवून ठेवावे.',
        category: 'maintenance',
        priority: 'normal',
        publishedDate: DateTime.now().subtract(const Duration(days: 4)),
        issuedByName: 'Managing Committee',
      ),
    ]);

    // Initial Complaints
    _complaints.addAll([
      ComplaintModel(
        id: 'TKT-01',
        societyId: activeSociety.id,
        flatNumber: 'A-402',
        memberUid: 'usr_member_01',
        memberName: 'Rajesh Arvind Deshmukh',
        category: 'cat_plumbing',
        title: 'Terrace Rainwater Pipe Leakage near A-Wing duct',
        description: 'Water seepage observed on bedroom wall due to blockage in terrace drainage duct.',
        status: 'inProgress',
        priority: 'high',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        adminRemarks: 'Plumber Suresh assigned. Inspection scheduled tomorrow 11 AM.',
      ),
      ComplaintModel(
        id: 'TKT-02',
        societyId: activeSociety.id,
        flatNumber: 'B-104',
        memberUid: 'usr_member_02',
        memberName: 'Pooja Sawant',
        category: 'cat_electrical',
        title: 'B-Wing Lobby corridor tube light flickering',
        description: 'First floor corridor lights are not turning on.',
        status: 'resolved',
        priority: 'medium',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 1)),
        adminRemarks: 'Choke and LED tube replaced by society electrician.',
      ),
    ]);

    // Initial Visitors
    _visitors.addAll([
      VisitorModel(
        id: 'VIS-01',
        societyId: activeSociety.id,
        visitorName: 'Santosh Kamble (Amazon Delivery)',
        phoneNumber: '+919876543210',
        targetWing: 'A',
        targetFlat: 'A-402',
        purpose: 'purpose_delivery',
        vehicleNumber: 'MH 01 CW 8912',
        checkInTime: DateTime.now().subtract(const Duration(minutes: 15)),
        guardName: 'Ramesh Shinde',
        status: 'inside',
        memberApproval: 'approved',
      ),
      VisitorModel(
        id: 'VIS-02',
        societyId: activeSociety.id,
        visitorName: 'Vikram Joshi (Guest)',
        phoneNumber: '+919890123456',
        targetWing: 'B',
        targetFlat: 'B-201',
        purpose: 'purpose_guest',
        vehicleNumber: 'MH 02 BG 4567',
        checkInTime: DateTime.now().subtract(const Duration(hours: 2)),
        checkOutTime: DateTime.now().subtract(const Duration(minutes: 30)),
        guardName: 'Ramesh Shinde',
        status: 'checkedOut',
        memberApproval: 'approved',
      ),
    ]);
  }

  // Getters
  List<AppUser> get users => List.unmodifiable(_users);
  List<MaintenanceBill> get bills => List.unmodifiable(_bills);
  List<LedgerEntry> get ledger => List.unmodifiable(_ledger);
  List<NoticeModel> get notices => List.unmodifiable(_notices);
  List<ComplaintModel> get complaints => List.unmodifiable(_complaints);
  List<VisitorModel> get visitors => List.unmodifiable(_visitors);

  // Accounting Financial Balances
  double get totalIncome => _ledger.where((e) => e.isIncome).fold(0.0, (sum, e) => sum + e.amount);
  double get totalExpenses => _ledger.where((e) => e.isExpense).fold(0.0, (sum, e) => sum + e.amount);
  double get netSocietyBalance => totalIncome - totalExpenses + 150000; // Starting corpus ₹1.5L
  double get bankBalance => netSocietyBalance - cashBalance;
  double get cashBalance => 14250.0;

  // Bill Actions
  Future<void> recordMaintenancePayment({
    required String billId,
    required String paymentRef,
    required String paymentMode,
  }) async {
    final index = _bills.indexWhere((b) => b.id == billId);
    if (index != -1) {
      final oldBill = _bills[index];
      final receiptNo = 'REC-${oldBill.billYear}-${oldBill.billMonth.toString().padLeft(2, '0')}-${oldBill.flatNumber}';
      
      final updatedBill = oldBill.copyWith(
        status: 'paid',
        paidAt: DateTime.now(),
        paymentRef: paymentRef,
        receiptNumber: receiptNo,
      );
      _bills[index] = updatedBill;

      // Automatically credit paid amount to Society Accounting Ledger!
      final ledgerEntry = LedgerEntry(
        id: 'LED-${DateTime.now().millisecondsSinceEpoch}',
        societyId: activeSociety.id,
        transactionDate: DateTime.now(),
        type: 'income',
        category: 'cat_maintenance_collection',
        title: 'Maintenance Collection - Flat ${oldBill.flatNumber}',
        titleMr: 'मासिक देखभाल वर्गणी - फ्लॅट ${oldBill.flatNumber}',
        amount: oldBill.totalAmount,
        paymentMode: paymentMode.toLowerCase().contains('upi') ? 'upi' : 'bank',
        voucherNo: 'RV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        vendorName: oldBill.memberName,
        relatedBillId: oldBill.id,
        recordedByUid: 'auto_upi',
      );
      _ledger.insert(0, ledgerEntry);
    }
  }

  Future<void> generateMonthlyBills({
    required int month,
    required int year,
    required double baseAmount,
    required double sinkingFund,
    required double repairFund,
    required double waterCharges,
    required DateTime dueDate,
  }) async {
    // Generate bills for test flats
    final testFlats = [
      {'flat': 'A-101', 'wing': 'A', 'name': 'Anil Joshi'},
      {'flat': 'A-201', 'wing': 'A', 'name': 'Deepak Sawant'},
      {'flat': 'A-402', 'wing': 'A', 'name': 'Rajesh Arvind Deshmukh'},
      {'flat': 'B-102', 'wing': 'B', 'name': 'Nitin More'},
      {'flat': 'B-201', 'wing': 'B', 'name': 'Sunil Patil'},
      {'flat': 'C-101', 'wing': 'C', 'name': 'Sanjay Shinde'},
      {'flat': 'C-303', 'wing': 'C', 'name': 'Mahesh Kulkarni'},
    ];

    for (var f in testFlats) {
      final billId = 'BILL-$year-$month-${f['flat']!.replaceAll('-', '')}';
      final total = baseAmount + sinkingFund + repairFund + waterCharges;
      
      // Check if bill already exists
      if (!_bills.any((b) => b.id == billId)) {
        _bills.add(
          MaintenanceBill(
            id: billId,
            societyId: activeSociety.id,
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
          ),
        );
      }
    }
  }

  // Accounting Actions
  Future<void> addLedgerEntry(LedgerEntry entry) async {
    _ledger.insert(0, entry);
  }

  // Notice Actions
  Future<void> addNotice(NoticeModel notice) async {
    _notices.insert(0, notice);
  }

  // Complaint Actions
  Future<void> addComplaint(ComplaintModel complaint) async {
    _complaints.insert(0, complaint);
  }

  Future<void> updateComplaintStatus(String id, String newStatus, String remarks) async {
    final index = _complaints.indexWhere((c) => c.id == id);
    if (index != -1) {
      _complaints[index] = _complaints[index].copyWith(
        status: newStatus,
        resolvedAt: newStatus == 'resolved' ? DateTime.now() : null,
        adminRemarks: remarks,
      );
    }
  }

  // Visitor Actions
  Future<void> checkInVisitor(VisitorModel visitor) async {
    _visitors.insert(0, visitor);
  }

  Future<void> checkOutVisitor(String visitorId) async {
    final index = _visitors.indexWhere((v) => v.id == visitorId);
    if (index != -1) {
      _visitors[index] = _visitors[index].copyWith(
        checkOutTime: DateTime.now(),
        status: 'checkedOut',
      );
    }
  }

  Future<void> updateVisitorApproval(String visitorId, String approvalStatus) async {
    final index = _visitors.indexWhere((v) => v.id == visitorId);
    if (index != -1) {
      _visitors[index] = _visitors[index].copyWith(
        memberApproval: approvalStatus,
      );
    }
  }
}
