import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notice_model.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';

class NoticeProvider extends ChangeNotifier {
  final FirebaseService _fallbackService = FirebaseService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;

  List<NoticeModel> _notices = [];
  StreamSubscription<List<NoticeModel>>? _subscription;

  NoticeProvider() {
    _notices = List.from(_fallbackService.notices);
    _initLiveFirestoreStream();
  }

  void _initLiveFirestoreStream() {
    try {
      _subscription = _firestoreService.streamNotices().listen((liveNotices) {
        if (liveNotices.isNotEmpty) {
          _notices = liveNotices;
          notifyListeners();
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<NoticeModel> get notices => _notices.isNotEmpty ? _notices : _fallbackService.notices;

  Future<void> postNotice({
    required String title,
    required String titleMr,
    required String content,
    required String contentMr,
    required String category,
    required String priority,
    required String issuedByName,
    String attachmentUrl = '',
  }) async {
    final notice = NoticeModel(
      id: 'NOT-${DateTime.now().millisecondsSinceEpoch}',
      societyId: FirestoreService.currentSocietyId,
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

    try {
      await _firestoreService.postNotice(notice);
    } catch (_) {
      await _fallbackService.addNotice(notice);
    }
    notifyListeners();
  }
}
