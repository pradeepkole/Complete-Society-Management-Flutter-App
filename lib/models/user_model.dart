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

  AppUser({
    required this.uid,
    required this.name,
    required this.nameMr,
    required this.phoneNumber,
    required this.email,
    required this.role,
    this.residentType = 'owner',
    this.flatNumber = '',
    this.wing = '',
    required this.societyId,
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
    };
  }
}
