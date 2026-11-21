import 'dart:async';
import 'package:flutter/material.dart';
import '../models/visitor_model.dart';
import '../services/firestore_service.dart';

class VisitorProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService.instance;

  String? _societyId;
  List<VisitorModel> _visitors = [];
  StreamSubscription<List<VisitorModel>>? _subscription;

  VisitorProvider();

  void setSocietyId(String societyId) {
    if (_societyId == societyId) return;
    _societyId = societyId;
    _subscription?.cancel();

    _subscription = _firestoreService.streamVisitors(societyId).listen((liveVisitors) {
      _visitors = liveVisitors;
      notifyListeners();
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<VisitorModel> get allVisitors => _visitors;

  List<VisitorModel> getVisitorsForFlat(String flatNumber) {
    return _visitors.where((v) => v.targetFlat == flatNumber).toList();
  }

  List<VisitorModel> get activeInsideVisitors {
    return _visitors.where((v) => v.isInside).toList();
  }

  Future<void> checkInVisitor({
    String? societyId,
    required String visitorName,
    required String phoneNumber,
    required String targetWing,
    required String targetFlat,
    required String purpose,
    String vehicleNumber = '',
    String guardName = 'Security Guard',
    String? visitorType,
    String? recordedByGuardUid,
  }) async {
    final visitor = VisitorModel(
      id: 'VIS-${DateTime.now().millisecondsSinceEpoch}',
      societyId: societyId ?? _societyId ?? '',
      visitorName: visitorName,
      phoneNumber: phoneNumber,
      targetWing: targetWing,
      targetFlat: targetFlat,
      purpose: purpose,
      vehicleNumber: vehicleNumber,
      guardName: guardName,
      checkInTime: DateTime.now(),
      status: 'inside',
      memberApproval: 'pendingApproval',
    );

    await _firestoreService.checkInVisitor(visitor);
  }

  Future<void> checkOutVisitor(String visitorId) async {
    await _firestoreService.checkOutVisitor(visitorId);
  }

  Future<void> setApproval(String visitorId, String approvalStatus) async {
    await _firestoreService.updateVisitorApproval(visitorId, approvalStatus);
  }

  Future<void> updateApproval(String visitorId, String approvalStatus) async {
    await _firestoreService.updateVisitorApproval(visitorId, approvalStatus);
  }
}
