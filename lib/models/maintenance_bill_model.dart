class MaintenanceBill {
  final String id;
  final String societyId;
  final String flatNumber;
  final String wing;
  final String memberName;
  final int billMonth; // 1-12
  final int billYear;
  final double maintenanceAmount;
  final double sinkingFund;
  final double repairFund;
  final double waterCharges;
  final double latePenalty;
  final double totalAmount;
  final double totalMonthlyExpense;
  final int totalSocietyFlats;
  final double rawShareAmount;
  final double roundOffAmount;
  final double adjustments;
  final String? collectedByAdminUid;
  final String? paymentProofUrl;
  final String paymentMode;
  final DateTime dueDate;
  final String status; // 'unpaid', 'paid', 'overdue'
  final DateTime? paidAt;
  final String paymentRef;
  final String receiptNumber;
  final String receiptPdfUrl;

  MaintenanceBill({
    required this.id,
    required this.societyId,
    required this.flatNumber,
    required this.wing,
    required this.memberName,
    required this.billMonth,
    required this.billYear,
    required this.maintenanceAmount,
    this.sinkingFund = 0,
    this.repairFund = 0,
    this.waterCharges = 0,
    this.latePenalty = 0,
    required this.totalAmount,
    this.totalMonthlyExpense = 0,
    this.totalSocietyFlats = 1,
    this.rawShareAmount = 0,
    this.roundOffAmount = 0,
    this.adjustments = 0,
    this.collectedByAdminUid,
    this.paymentProofUrl,
    this.paymentMode = 'online',
    required this.dueDate,
    this.status = 'unpaid',
    this.paidAt,
    this.paymentRef = '',
    this.receiptNumber = '',
    this.receiptPdfUrl = '',
  });

  bool get isPaid => status == 'paid';
  bool get isOverdue => status == 'overdue' || (status == 'unpaid' && DateTime.now().isAfter(dueDate));
  double get netPayable => (totalAmount - adjustments).clamp(0.0, double.infinity);

  MaintenanceBill copyWith({
    String? status,
    DateTime? paidAt,
    String? paymentRef,
    String? receiptNumber,
    String? receiptPdfUrl,
    double? totalAmount,
    double? adjustments,
    String? collectedByAdminUid,
    String? paymentProofUrl,
    String? paymentMode,
  }) {
    return MaintenanceBill(
      id: id,
      societyId: societyId,
      flatNumber: flatNumber,
      wing: wing,
      memberName: memberName,
      billMonth: billMonth,
      billYear: billYear,
      maintenanceAmount: maintenanceAmount,
      sinkingFund: sinkingFund,
      repairFund: repairFund,
      waterCharges: waterCharges,
      latePenalty: latePenalty,
      totalAmount: totalAmount ?? this.totalAmount,
      totalMonthlyExpense: totalMonthlyExpense,
      totalSocietyFlats: totalSocietyFlats,
      rawShareAmount: rawShareAmount,
      roundOffAmount: roundOffAmount,
      adjustments: adjustments ?? this.adjustments,
      collectedByAdminUid: collectedByAdminUid ?? this.collectedByAdminUid,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      paymentMode: paymentMode ?? this.paymentMode,
      dueDate: dueDate,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      paymentRef: paymentRef ?? this.paymentRef,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      receiptPdfUrl: receiptPdfUrl ?? this.receiptPdfUrl,
    );
  }

  factory MaintenanceBill.fromMap(Map<String, dynamic> data, String id) {
    return MaintenanceBill(
      id: id,
      societyId: data['societyId'] ?? '',
      flatNumber: data['flatNumber'] ?? '',
      wing: data['wing'] ?? '',
      memberName: data['memberName'] ?? '',
      billMonth: data['billMonth'] ?? DateTime.now().month,
      billYear: data['billYear'] ?? DateTime.now().year,
      maintenanceAmount: (data['maintenanceAmount'] as num?)?.toDouble() ?? 0,
      sinkingFund: (data['sinkingFund'] as num?)?.toDouble() ?? 0,
      repairFund: (data['repairFund'] as num?)?.toDouble() ?? 0,
      waterCharges: (data['waterCharges'] as num?)?.toDouble() ?? 0,
      latePenalty: (data['latePenalty'] as num?)?.toDouble() ?? 0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      totalMonthlyExpense: (data['totalMonthlyExpense'] as num?)?.toDouble() ?? 0,
      totalSocietyFlats: (data['totalSocietyFlats'] as num?)?.toInt() ?? 1,
      rawShareAmount: (data['rawShareAmount'] as num?)?.toDouble() ?? 0,
      roundOffAmount: (data['roundOffAmount'] as num?)?.toDouble() ?? 0,
      adjustments: (data['adjustments'] as num?)?.toDouble() ?? 0,
      collectedByAdminUid: data['collectedByAdminUid'],
      paymentProofUrl: data['paymentProofUrl'],
      paymentMode: data['paymentMode'] ?? 'online',
      dueDate: data['dueDate'] != null ? DateTime.parse(data['dueDate']) : DateTime.now().add(const Duration(days: 15)),
      status: data['status'] ?? 'unpaid',
      paidAt: data['paidAt'] != null ? DateTime.parse(data['paidAt']) : null,
      paymentRef: data['paymentRef'] ?? '',
      receiptNumber: data['receiptNumber'] ?? '',
      receiptPdfUrl: data['receiptPdfUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'flatNumber': flatNumber,
      'wing': wing,
      'memberName': memberName,
      'billMonth': billMonth,
      'billYear': billYear,
      'maintenanceAmount': maintenanceAmount,
      'sinkingFund': sinkingFund,
      'repairFund': repairFund,
      'waterCharges': waterCharges,
      'latePenalty': latePenalty,
      'totalAmount': totalAmount,
      'totalMonthlyExpense': totalMonthlyExpense,
      'totalSocietyFlats': totalSocietyFlats,
      'rawShareAmount': rawShareAmount,
      'roundOffAmount': roundOffAmount,
      'adjustments': adjustments,
      'collectedByAdminUid': collectedByAdminUid,
      'paymentProofUrl': paymentProofUrl,
      'paymentMode': paymentMode,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'paidAt': paidAt?.toIso8601String(),
      'paymentRef': paymentRef,
      'receiptNumber': receiptNumber,
      'receiptPdfUrl': receiptPdfUrl,
    };
  }
}
