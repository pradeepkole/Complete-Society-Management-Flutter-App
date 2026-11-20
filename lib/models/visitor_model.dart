class VisitorModel {
  final String id;
  final String societyId;
  final String visitorName;
  final String phoneNumber;
  final String targetWing;
  final String targetFlat;
  final String purpose; // 'purpose_delivery', 'purpose_guest', 'purpose_maid', 'purpose_cab', 'purpose_service'
  final String vehicleNumber;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String guardName;
  final String status; // 'inside', 'checkedOut'
  final String memberApproval; // 'approved', 'pendingApproval', 'denied'
  final String photoUrl;

  VisitorModel({
    required this.id,
    required this.societyId,
    required this.visitorName,
    required this.phoneNumber,
    required this.targetWing,
    required this.targetFlat,
    required this.purpose,
    this.vehicleNumber = '',
    required this.checkInTime,
    this.checkOutTime,
    required this.guardName,
    this.status = 'inside',
    this.memberApproval = 'pendingApproval',
    this.photoUrl = '',
  });

  bool get isInside => status == 'inside';

  VisitorModel copyWith({
    DateTime? checkOutTime,
    String? status,
    String? memberApproval,
  }) {
    return VisitorModel(
      id: id,
      societyId: societyId,
      visitorName: visitorName,
      phoneNumber: phoneNumber,
      targetWing: targetWing,
      targetFlat: targetFlat,
      purpose: purpose,
      vehicleNumber: vehicleNumber,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      guardName: guardName,
      status: status ?? this.status,
      memberApproval: memberApproval ?? this.memberApproval,
      photoUrl: photoUrl,
    );
  }

  factory VisitorModel.fromMap(Map<String, dynamic> data, String id) {
    return VisitorModel(
      id: id,
      societyId: data['societyId'] ?? '',
      visitorName: data['visitorName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      targetWing: data['targetWing'] ?? '',
      targetFlat: data['targetFlat'] ?? '',
      purpose: data['purpose'] ?? 'purpose_guest',
      vehicleNumber: data['vehicleNumber'] ?? '',
      checkInTime: data['checkInTime'] != null
          ? DateTime.parse(data['checkInTime'])
          : DateTime.now(),
      checkOutTime: data['checkOutTime'] != null
          ? DateTime.parse(data['checkOutTime'])
          : null,
      guardName: data['guardName'] ?? '',
      status: data['status'] ?? 'inside',
      memberApproval: data['memberApproval'] ?? 'pendingApproval',
      photoUrl: data['photoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'visitorName': visitorName,
      'phoneNumber': phoneNumber,
      'targetWing': targetWing,
      'targetFlat': targetFlat,
      'purpose': purpose,
      'vehicleNumber': vehicleNumber,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'guardName': guardName,
      'status': status,
      'memberApproval': memberApproval,
      'photoUrl': photoUrl,
    };
  }
}
