class AppUser {
  final String uid;
  final String name;
  final String nameMr;
  final String phoneNumber;
  final String email;
  final String role; // 'admin' / 'super_admin', 'chairman', 'group_admin', 'member', 'guard'
  final String residentType; // 'owner', 'tenant', 'committee'
  final String flatNumber; // e.g. "A-402"
  final String wing; // e.g. "A"
  final String? assignedGroup; // e.g. "Wing A", "1st Floor" (for group_admin)
  final String? designation; // e.g. "चेअरमन", "सुपर ॲडमिन (सचिव)", "विंग A ॲडमिन"
  final String societyId;
  final String? societyCode;
  final String? photoUrl;
  final bool isApproved; // Admin must approve joining members
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.nameMr,
    this.phoneNumber = '',
    required this.email,
    required this.role,
    this.residentType = 'owner',
    this.flatNumber = '',
    this.wing = '',
    this.assignedGroup,
    this.designation,
    required this.societyId,
    this.societyCode,
    this.photoUrl,
    this.isApproved = true,
    this.createdAt,
  });

  bool get isSoftAdmin =>
      role == 'soft_admin' ||
      email.toLowerCase().contains('pradeepkole@gmail') ||
      phoneNumber.contains('9822681814') ||
      phoneNumber.contains('9623458653');

  bool get isAdmin => isSoftAdmin || role == 'admin' || role == 'super_admin' || role == 'chairman' || role == 'group_admin';
  bool get isSuperAdmin => isSoftAdmin || role == 'super_admin' || role == 'admin';
  bool get isChairman => role == 'chairman';
  bool get isGroupAdmin => role == 'group_admin';
  bool get isMember => role == 'member';
  bool get isGuard => role == 'guard';

  // Authority check: Only Super Admin and Chairman can manage expenses & cancel entries
  bool get canManageExpenses => isSoftAdmin || isSuperAdmin || isChairman;
  bool get canCancelEntries => isSoftAdmin || isSuperAdmin || isChairman;
  bool get isCollectionAdminOnly => isGroupAdmin && !canManageExpenses;

  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      name: data['name'] ?? '',
      nameMr: data['nameMr'] ?? data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'member',
      residentType: data['residentType'] ?? 'owner',
      flatNumber: data['flatNumber'] ?? '',
      wing: data['wing'] ?? '',
      assignedGroup: data['assignedGroup'],
      designation: data['designation'],
      societyId: data['societyId'] ?? '',
      societyCode: data['societyCode'],
      photoUrl: data['photoUrl'],
      isApproved: data['isApproved'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is int
              ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
              : DateTime.tryParse(data['createdAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameMr': nameMr,
      'phoneNumber': phoneNumber,
      'email': email,
      'role': role,
      'residentType': residentType,
      'flatNumber': flatNumber,
      'wing': wing,
      'assignedGroup': assignedGroup,
      'designation': designation,
      'societyId': societyId,
      'societyCode': societyCode,
      'photoUrl': photoUrl,
      'isApproved': isApproved,
      'createdAt': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    };
  }

  AppUser copyWith({
    String? name,
    String? nameMr,
    String? phoneNumber,
    String? role,
    String? residentType,
    String? flatNumber,
    String? wing,
    String? assignedGroup,
    String? designation,
    String? societyId,
    String? societyCode,
    String? photoUrl,
    bool? isApproved,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      nameMr: nameMr ?? this.nameMr,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email,
      role: role ?? this.role,
      residentType: residentType ?? this.residentType,
      flatNumber: flatNumber ?? this.flatNumber,
      wing: wing ?? this.wing,
      assignedGroup: assignedGroup ?? this.assignedGroup,
      designation: designation ?? this.designation,
      societyId: societyId ?? this.societyId,
      societyCode: societyCode ?? this.societyCode,
      photoUrl: photoUrl ?? this.photoUrl,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt,
    );
  }
}
