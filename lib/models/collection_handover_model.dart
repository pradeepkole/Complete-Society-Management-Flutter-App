class CollectionHandover {
  final String id;
  final String societyId;
  final String groupAdminUid;
  final String groupAdminName;
  final String assignedGroup; // e.g. "Wing A" or "1st Floor"
  final double totalAmount;
  final String paymentMode; // 'cash' or 'upi'
  final String proofPhotoUrl; // Photo of cash handover voucher or UPI transfer screenshot
  final DateTime handoverDate;
  final String notes;
  final String status; // 'pending', 'approved', 'rejected'
  final String? verifiedByUid;
  final String? verifiedByName;
  final DateTime? verifiedAt;

  CollectionHandover({
    required this.id,
    required this.societyId,
    required this.groupAdminUid,
    required this.groupAdminName,
    required this.assignedGroup,
    required this.totalAmount,
    required this.paymentMode,
    this.proofPhotoUrl = '',
    required this.handoverDate,
    this.notes = '',
    this.status = 'pending',
    this.verifiedByUid,
    this.verifiedByName,
    this.verifiedAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory CollectionHandover.fromMap(Map<String, dynamic> data, String id) {
    return CollectionHandover(
      id: id,
      societyId: data['societyId'] ?? '',
      groupAdminUid: data['groupAdminUid'] ?? '',
      groupAdminName: data['groupAdminName'] ?? '',
      assignedGroup: data['assignedGroup'] ?? '',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: data['paymentMode'] ?? 'cash',
      proofPhotoUrl: data['proofPhotoUrl'] ?? '',
      handoverDate: data['handoverDate'] != null
          ? DateTime.tryParse(data['handoverDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: data['notes'] ?? '',
      status: data['status'] ?? 'pending',
      verifiedByUid: data['verifiedByUid'],
      verifiedByName: data['verifiedByName'],
      verifiedAt: data['verifiedAt'] != null
          ? DateTime.tryParse(data['verifiedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'groupAdminUid': groupAdminUid,
      'groupAdminName': groupAdminName,
      'assignedGroup': assignedGroup,
      'totalAmount': totalAmount,
      'paymentMode': paymentMode,
      'proofPhotoUrl': proofPhotoUrl,
      'handoverDate': handoverDate.toIso8601String(),
      'notes': notes,
      'status': status,
      'verifiedByUid': verifiedByUid,
      'verifiedByName': verifiedByName,
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }

  CollectionHandover copyWith({
    String? status,
    String? verifiedByUid,
    String? verifiedByName,
    DateTime? verifiedAt,
  }) {
    return CollectionHandover(
      id: id,
      societyId: societyId,
      groupAdminUid: groupAdminUid,
      groupAdminName: groupAdminName,
      assignedGroup: assignedGroup,
      totalAmount: totalAmount,
      paymentMode: paymentMode,
      proofPhotoUrl: proofPhotoUrl,
      handoverDate: handoverDate,
      notes: notes,
      status: status ?? this.status,
      verifiedByUid: verifiedByUid ?? this.verifiedByUid,
      verifiedByName: verifiedByName ?? this.verifiedByName,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}
