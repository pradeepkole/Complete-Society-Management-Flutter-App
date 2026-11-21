import 'dart:async';
import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../services/firestore_service.dart';

class ComplaintProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService.instance;

  String? _societyId;
  List<ComplaintModel> _complaints = [];
  StreamSubscription<List<ComplaintModel>>? _subscription;

  ComplaintProvider();

  void setSocietyId(String societyId) {
    if (_societyId == societyId) return;
    _societyId = societyId;
    _subscription?.cancel();

    _subscription = _firestoreService.streamComplaints(societyId).listen((liveComplaints) {
      _complaints = liveComplaints;
      notifyListeners();
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<ComplaintModel> get allComplaints => _complaints;

  List<ComplaintModel> getComplaintsForFlat(String flatNumber) {
    return _complaints.where((c) => c.flatNumber == flatNumber).toList();
  }

  Future<void> raiseComplaint({
    required String societyId,
    required String flatNumber,
    required String memberUid,
    required String memberName,
    required String category,
    required String title,
    required String description,
    String photoUrl = '',
    String priority = 'medium',
  }) async {
    final complaint = ComplaintModel(
      id: 'CMP-${DateTime.now().millisecondsSinceEpoch}',
      societyId: societyId,
      flatNumber: flatNumber,
      memberUid: memberUid,
      memberName: memberName,
      category: category,
      title: title,
      description: description,
      photoUrl: photoUrl,
      priority: priority,
      createdAt: DateTime.now(),
    );

    await _firestoreService.addComplaint(complaint);
  }

  Future<void> updateStatus(String id, String status, String remarks) async {
    await _firestoreService.updateComplaintStatus(id, status, remarks);
  }
}
