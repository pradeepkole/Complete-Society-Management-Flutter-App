import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notice_model.dart';
import '../services/firestore_service.dart';

class NoticeProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService.instance;

  String? _societyId;
  List<NoticeModel> _notices = [];
  StreamSubscription<List<NoticeModel>>? _subscription;

  NoticeProvider();

  void setSocietyId(String societyId) {
    if (_societyId == societyId) return;
    _societyId = societyId;
    _subscription?.cancel();

    _subscription = _firestoreService.streamNotices(societyId).listen((liveNotices) {
      _notices = liveNotices;
      notifyListeners();
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<NoticeModel> get notices => _notices;

  Future<void> postNotice({
    String? societyId,
    required String title,
    required String titleMr,
    required String content,
    required String contentMr,
    required String category,
    required String priority,
    required String issuedByName,
    String attachmentUrl = '',
  }) async {
    final targetSocietyId = societyId ?? _societyId ?? '';
    final notice = NoticeModel(
      id: 'NOT-${DateTime.now().millisecondsSinceEpoch}',
      societyId: targetSocietyId,
      title: title,
      titleMr: titleMr,
      content: content,
      contentMr: contentMr,
      category: category,
      priority: priority,
      publishedDate: DateTime.now(),
      issuedByName: issuedByName,
      attachmentUrl: attachmentUrl,
    );

    await _firestoreService.postNotice(notice);
  }
}
