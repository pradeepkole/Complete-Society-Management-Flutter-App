import 'dart:async';
import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';

class ComplaintProvider extends ChangeNotifier {
  final FirebaseService _fallbackService = FirebaseService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;

  List<ComplaintModel> _complaints = [];
  StreamSubscription<List<ComplaintModel>>? _subscription;

  ComplaintProvider() {
    _complaints = List.from(_fallbackService.complaints);
    _initLiveFirestoreStream();
  }

  void _initLiveFirestoreStream() {
    try {
      _subscription = _firestoreService.streamComplaints().listen((liveComplaints) {
        if (liveComplaints.isNotEmpty) {
          _complaints = liveComplaints;
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

  List<ComplaintModel> get allComplaints => _complaints.isNotEmpty ? _complaints : _fallbackService.complaints;

  List<ComplaintModel> getComplaintsForFlat(String flatNumber) {
    return allComplaints.where((c) => c.flatNumber == flatNumber).toList();
  }

  Future<void> raiseComplaint({
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
      id: 'TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      societyId: FirestoreService.currentSocietyId,
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

    try {
      await _firestoreService.addComplaint(complaint);
    } catch (_) {
      await _fallbackService.addComplaint(complaint);
    }
    notifyListeners();
  }

  Future<void> updateStatus(String complaintId, String newStatus, String remarks) async {
    try {
      await _firestoreService.updateComplaintStatus(complaintId, newStatus, remarks);
    } catch (_) {
      await _fallbackService.updateComplaintStatus(complaintId, newStatus, remarks);
    }
    notifyListeners();
  }
}
