class SocietyModel {
  final String id;
  final String societyCode; // 6-digit unique code for members to join
  final String name;
  final String nameMr;
  final String registrationNo;
  final String address;
  final String city;
  final String pincode;
  final String? logoUrl; // Society Logo image URL
  final List<String> wings; // e.g. ['A', 'B', 'C']
  final String upiId;
  final String upiMerchantName;
  final String bankName;
  final String accountNo;
  final String ifsc;
  final double defaultMaintenanceAmount;
  final int totalFlats;
  final String adminUid;
  final bool allowMobileLogin;
  final DateTime? createdAt;

  SocietyModel({
    required this.id,
    this.societyCode = '',
    required this.name,
    required this.nameMr,
    this.registrationNo = '',
    required this.address,
    this.city = '',
    this.pincode = '',
    this.logoUrl,
    this.wings = const ['A', 'B'],
    this.upiId = '',
    this.upiMerchantName = '',
    this.bankName = '',
    this.accountNo = '',
    this.ifsc = '',
    this.defaultMaintenanceAmount = 2000,
    this.totalFlats = 40,
    this.adminUid = '',
    this.allowMobileLogin = false,
    this.createdAt,
  });

  bool get hasLogo => logoUrl != null && logoUrl!.trim().isNotEmpty;
  bool get hasUpiConfigured => upiId.trim().isNotEmpty;

  factory SocietyModel.fromMap(Map<String, dynamic> data, String id) {
    return SocietyModel(
      id: id,
      societyCode: data['societyCode'] ?? '',
      name: data['name'] ?? '',
      nameMr: data['nameMr'] ?? data['name'] ?? '',
      registrationNo: data['registrationNo'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      pincode: data['pincode'] ?? '',
      logoUrl: data['logoUrl'],
      wings: data['wings'] != null ? List<String>.from(data['wings']) : ['A', 'B'],
      upiId: data['upiId'] ?? '',
      upiMerchantName: data['upiMerchantName'] ?? data['name'] ?? '',
      bankName: data['bankName'] ?? '',
      accountNo: data['accountNo'] ?? '',
      ifsc: data['ifsc'] ?? '',
      defaultMaintenanceAmount: (data['defaultMaintenanceAmount'] as num?)?.toDouble() ?? 2000,
      totalFlats: (data['totalFlats'] as num?)?.toInt() ?? 40,
      adminUid: data['adminUid'] ?? '',
      allowMobileLogin: data['allowMobileLogin'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
              : DateTime.tryParse(data['createdAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyCode': societyCode,
      'name': name,
      'nameMr': nameMr,
      'registrationNo': registrationNo,
      'address': address,
      'city': city,
      'pincode': pincode,
      'logoUrl': logoUrl,
      'wings': wings,
      'upiId': upiId,
      'upiMerchantName': upiMerchantName,
      'bankName': bankName,
      'accountNo': accountNo,
      'ifsc': ifsc,
      'defaultMaintenanceAmount': defaultMaintenanceAmount,
      'totalFlats': totalFlats,
      'adminUid': adminUid,
      'allowMobileLogin': allowMobileLogin,
      'createdAt': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    };
  }

  SocietyModel copyWith({
    String? societyCode,
    String? name,
    String? nameMr,
    String? registrationNo,
    String? address,
    String? city,
    String? pincode,
    String? logoUrl,
    List<String>? wings,
    String? upiId,
    String? upiMerchantName,
    String? bankName,
    String? accountNo,
    String? ifsc,
    double? defaultMaintenanceAmount,
    int? totalFlats,
    String? adminUid,
    bool? allowMobileLogin,
  }) {
    return SocietyModel(
      id: id,
      societyCode: societyCode ?? this.societyCode,
      name: name ?? this.name,
      nameMr: nameMr ?? this.nameMr,
      registrationNo: registrationNo ?? this.registrationNo,
      address: address ?? this.address,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      logoUrl: logoUrl ?? this.logoUrl,
      wings: wings ?? this.wings,
      upiId: upiId ?? this.upiId,
      upiMerchantName: upiMerchantName ?? this.upiMerchantName,
      bankName: bankName ?? this.bankName,
      accountNo: accountNo ?? this.accountNo,
      ifsc: ifsc ?? this.ifsc,
      defaultMaintenanceAmount: defaultMaintenanceAmount ?? this.defaultMaintenanceAmount,
      totalFlats: totalFlats ?? this.totalFlats,
      adminUid: adminUid ?? this.adminUid,
      allowMobileLogin: allowMobileLogin ?? this.allowMobileLogin,
      createdAt: createdAt,
    );
  }
}
