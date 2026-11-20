class NoticeModel {
  final String id;
  final String societyId;
  final String title;
  final String titleMr;
  final String content;
  final String contentMr;
  final String category; // 'meeting_agm', 'maintenance', 'emergency', 'general'
  final String priority; // 'urgent', 'normal'
  final DateTime publishedDate;
  final String issuedByName;
  final String attachmentUrl;

  NoticeModel({
    required this.id,
    required this.societyId,
    required this.title,
    required this.titleMr,
    required this.content,
    required this.contentMr,
    this.category = 'general',
    this.priority = 'normal',
    required this.publishedDate,
    required this.issuedByName,
    this.attachmentUrl = '',
  });

  bool get isUrgent => priority == 'urgent';

  factory NoticeModel.fromMap(Map<String, dynamic> data, String id) {
    return NoticeModel(
      id: id,
      societyId: data['societyId'] ?? '',
      title: data['title'] ?? '',
      titleMr: data['titleMr'] ?? data['title'] ?? '',
      content: data['content'] ?? '',
      contentMr: data['contentMr'] ?? data['content'] ?? '',
      category: data['category'] ?? 'general',
      priority: data['priority'] ?? 'normal',
      publishedDate: data['publishedDate'] != null
          ? DateTime.parse(data['publishedDate'])
          : DateTime.now(),
      issuedByName: data['issuedByName'] ?? 'Secretary',
      attachmentUrl: data['attachmentUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'societyId': societyId,
      'title': title,
      'titleMr': titleMr,
      'content': content,
      'contentMr': contentMr,
      'category': category,
      'priority': priority,
      'publishedDate': publishedDate.toIso8601String(),
      'issuedByName': issuedByName,
      'attachmentUrl': attachmentUrl,
    };
  }
}
