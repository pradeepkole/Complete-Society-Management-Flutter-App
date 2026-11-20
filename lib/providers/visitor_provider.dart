import 'dart:async';
import 'package:flutter/material.dart';
import '../models/visitor_model.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';

class VisitorProvider extends ChangeNotifier {
  final FirebaseService _fallbackService = FirebaseService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;

  List<VisitorModel> _visitors = [];
  StreamSubscription<List<VisitorModel>>? _subscription;

  VisitorProvider() {
    _visitors = List.from(_fallbackService.visitors);
    _initLiveFirestoreStream();
  }

  void _initLiveFirestoreStream() {
    try {
      _subscription = _firestoreService.streamVisitors().listen((liveVisitors) {
        if (liveVisitors.isNotEmpty) {
          _visitors = liveVisitors;
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

  List<VisitorModel> get allVisitors => _visitors.isNotEmpty ? _visitors : _fallbackService.visitors;

  List<VisitorModel> getVisitorsForFlat(String flatNumber) {
    return allVisitors.where((v) => v.targetFlat == flatNumber).toList();
  }

  List<VisitorModel> get activeInsideVisitors {
    return allVisitors.where((v) => v.isInside).toList();
  }

  Future<void> checkInVisitor({
    required String visitorName,
    required String phoneNumber,
    required String targetWing,
    required String targetFlat,
    required String purpose,
    String vehicleNumber = '',
    required String guardName,
    String photoUrl = '',
  }) async {
    final visitor = VisitorModel(
      id: 'VIS-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      societyId: FirestoreService.currentSocietyId,
      visitorName: visitorName,
      phoneNumber: phoneNumber,
      targetWing: targetWing,
      targetFlat: targetFlat,
      purpose: purpose,
      vehicleNumber: vehicleNumber,
      checkInTime: DateTime.now(),
      guardName: guardName,
      status: 'inside',
      memberApproval: 'pendingApproval',
      photoUrl: photoUrl,
    );

    try {
      await _firestoreService.checkInVisitor(visitor);
    } catch (_) {
      await _fallbackService.checkInVisitor(visitor);
    }
    notifyListeners();
  }

  Future<void> checkOutVisitor(String visitorId) async {
    try {
      await _firestoreService.checkOutVisitor(visitorId);
    } catch (_) {
      await _fallbackService.checkOutVisitor(visitorId);
    }
    notifyListeners();
  }

  Future<void> setApproval(String visitorId, String approvalStatus) async {
    try {
      await _firestoreService.updateVisitorApproval(visitorId, approvalStatus);
    } catch (_) {
      await _fallbackService.updateVisitorApproval(visitorId, approvalStatus);
    }
    notifyListeners();
  }
}
