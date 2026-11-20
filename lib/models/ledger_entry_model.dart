class LedgerEntry {
  final String id;
  final String societyId;
  final DateTime transactionDate;
  final String type; // 'income' or 'expense'
  final String category; // e.g. 'cat_security_salary', 'cat_common_electricity', 'cat_maintenance_collection'
  final String title;
  final String titleMr;
  final double amount;
  final String paymentMode; // 'bank', 'cash', 'upi'
  final String voucherNo;
  final String vendorName;
  final String billAttachmentUrl;
  final String? relatedBillId;
  final String recordedByUid;
  final String notes;

  LedgerEntry({
    required this.id,
    required this.societyId,
    required this.transactionDate,
    required this.type,
    required this.category,
    required this.title,
    required this.titleMr,
    required this.amount,
    required this.paymentMode,
    required this.voucherNo,
    required this.vendorName,
    this.billAttachmentUrl = '',
    this.relatedBillId,
    required this.recordedByUid,
    this.notes = '',
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  factory LedgerEntry.fromMap(Map<String, dynamic> data, String id) {
    return LedgerEntry(
      id: id,
      societyId: data['societyId'] ?? '',
      transactionDate: data['transactionDate'] != null
          ? DateTime.parse(data['transactionDate'])
          : DateTime.now(),
      type: data['type'] ?? 'expense',
      category: data['category'] ?? 'cat_other_expense',
      title: data['title'] ?? '',
      titleMr: data['titleMr'] ?? data['title'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: data['paymentMode'] ?? 'bank',
      voucherNo: data['voucherNo'] ?? '',
      vendorName: data['vendorName'] ?? '',
      billAttachmentUrl: data['billAttachmentUrl'] ?? '',
      relatedBillId: data['relatedBillId'],
      recordedByUid: data['recordedByUid'] ?? '',
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'transactionDate': transactionDate.toIso8601String(),
      'type': type,
      'category': category,
      'title': title,
      'titleMr': titleMr,
      'amount': amount,
      'paymentMode': paymentMode,
      'voucherNo': voucherNo,
      'vendorName': vendorName,
      'billAttachmentUrl': billAttachmentUrl,
      'relatedBillId': relatedBillId,
      'recordedByUid': recordedByUid,
      'notes': notes,
    };
  }
}
