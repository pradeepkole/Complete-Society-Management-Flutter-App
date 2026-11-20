class SocietyModel {
  final String id;
  final String name;
  final String nameMr;
  final String registrationNo;
  final String address;
  final String upiId;
  final String upiMerchantName;
  final String bankName;
  final String accountNo;
  final String ifsc;
  final double defaultMaintenanceAmount;
  final int totalFlats;

  SocietyModel({
    required this.id,
    required this.name,
    required this.nameMr,
    required this.registrationNo,
    required this.address,
    required this.upiId,
    required this.upiMerchantName,
    required this.bankName,
    required this.accountNo,
    required this.ifsc,
    this.defaultMaintenanceAmount = 2500,
    this.totalFlats = 72,
  });

  factory SocietyModel.fromMap(Map<String, dynamic> data, String id) {
    return SocietyModel(
      id: id,
      name: data['name'] ?? '',
      nameMr: data['nameMr'] ?? '',
      registrationNo: data['registrationNo'] ?? '',
      address: data['address'] ?? '',
      upiId: data['upiId'] ?? '',
      upiMerchantName: data['upiMerchantName'] ?? '',
      bankName: data['bankName'] ?? '',
      accountNo: data['accountNo'] ?? '',
      ifsc: data['ifsc'] ?? '',
      defaultMaintenanceAmount: (data['defaultMaintenanceAmount'] as num?)?.toDouble() ?? 2500,
      totalFlats: data['totalFlats'] ?? 72,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameMr': nameMr,
      'registrationNo': registrationNo,
      'address': address,
      'upiId': upiId,
      'upiMerchantName': upiMerchantName,
      'bankName': bankName,
      'accountNo': accountNo,
      'ifsc': ifsc,
      'defaultMaintenanceAmount': defaultMaintenanceAmount,
      'totalFlats': totalFlats,
    };
  }
}
