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
    this.sinkingFund = 300,
    this.repairFund = 200,
    this.waterCharges = 350,
    this.latePenalty = 0,
    required this.totalAmount,
    required this.dueDate,
    this.status = 'unpaid',
    this.paidAt,
    this.paymentRef = '',
    this.receiptNumber = '',
    this.receiptPdfUrl = '',
  });

  bool get isPaid => status == 'paid';
  bool get isOverdue => status == 'overdue' || (status == 'unpaid' && DateTime.now().isAfter(dueDate));

  MaintenanceBill copyWith({
    String? status,
    DateTime? paidAt,
    String? paymentRef,
    String? receiptNumber,
    String? receiptPdfUrl,
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
      totalAmount: totalAmount,
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
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'paidAt': paidAt?.toIso8601String(),
      'paymentRef': paymentRef,
      'receiptNumber': receiptNumber,
      'receiptPdfUrl': receiptPdfUrl,
    };
  }
}
