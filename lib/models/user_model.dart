class AppUser {
  final String uid;
  final String name;
  final String nameMr;
  final String phoneNumber;
  final String email;
  final String role; // 'admin', 'member', 'guard'
  final String residentType; // 'owner', 'tenant', 'committee'
  final String flatNumber; // e.g. "A-402"
  final String wing; // e.g. "A"
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
    required this.societyId,
    this.societyCode,
    this.photoUrl,
    this.isApproved = true,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isMember => role == 'member';
  bool get isGuard => role == 'guard';

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
      societyId: societyId ?? this.societyId,
      societyCode: societyCode ?? this.societyCode,
      photoUrl: photoUrl ?? this.photoUrl,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt,
    );
  }
}
