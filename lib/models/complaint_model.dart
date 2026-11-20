class ComplaintModel {
  final String id;
  final String societyId;
  final String flatNumber;
  final String memberUid;
  final String memberName;
  final String category; // 'cat_plumbing', 'cat_electrical', 'cat_cleaning', 'cat_lift', 'cat_security', 'cat_other'
  final String title;
  final String description;
  final String photoUrl;
  final String status; // 'open', 'inProgress', 'resolved'
  final String priority; // 'low', 'medium', 'high'
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String adminRemarks;

  ComplaintModel({
    required this.id,
    required this.societyId,
    required this.flatNumber,
    required this.memberUid,
    required this.memberName,
    required this.category,
    required this.title,
    required this.description,
    this.photoUrl = '',
    this.status = 'open',
    this.priority = 'medium',
    required this.createdAt,
    this.resolvedAt,
    this.adminRemarks = '',
  });

  ComplaintModel copyWith({
    String? status,
    DateTime? resolvedAt,
    String? adminRemarks,
  }) {
    return ComplaintModel(
      id: id,
      societyId: societyId,
      flatNumber: flatNumber,
      memberUid: memberUid,
      memberName: memberName,
      category: category,
      title: title,
      description: description,
      photoUrl: photoUrl,
      status: status ?? this.status,
      priority: priority,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminRemarks: adminRemarks ?? this.adminRemarks,
    );
  }

  factory ComplaintModel.fromMap(Map<String, dynamic> data, String id) {
    return ComplaintModel(
      id: id,
      societyId: data['societyId'] ?? '',
      flatNumber: data['flatNumber'] ?? '',
      memberUid: data['memberUid'] ?? '',
      memberName: data['memberName'] ?? '',
      category: data['category'] ?? 'cat_other',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      status: data['status'] ?? 'open',
      priority: data['priority'] ?? 'medium',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      resolvedAt: data['resolvedAt'] != null
          ? DateTime.parse(data['resolvedAt'])
          : null,
      adminRemarks: data['adminRemarks'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'flatNumber': flatNumber,
      'memberUid': memberUid,
      'memberName': memberName,
      'category': category,
      'title': title,
      'description': description,
      'photoUrl': photoUrl,
      'status': status,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'adminRemarks': adminRemarks,
    };
  }
}
