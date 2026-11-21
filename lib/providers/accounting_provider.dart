import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/ledger_entry_model.dart';
import '../services/firestore_service.dart';
import '../services/audit_export_service.dart';

class AccountingProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService.instance;

  String? _societyId;
  List<LedgerEntry> _ledger = [];
  StreamSubscription<List<LedgerEntry>>? _ledgerSubscription;

  AccountingProvider();

  void setSocietyId(String societyId) {
    if (_societyId == societyId) return;
    _societyId = societyId;
    _ledgerSubscription?.cancel();

    _ledgerSubscription = _firestoreService.streamLedgerEntries(societyId).listen((liveEntries) {
      _ledger = liveEntries;
      notifyListeners();
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _ledgerSubscription?.cancel();
    super.dispose();
  }

  List<LedgerEntry> get ledgerEntries => _ledger;
  List<LedgerEntry> get expenses => _ledger.where((e) => e.isExpense).toList();
  List<LedgerEntry> get incomes => _ledger.where((e) => e.isIncome).toList();

  double get totalIncome => incomes.fold(0.0, (sum, e) => sum + e.amount);
  double get totalExpenses => expenses.fold(0.0, (sum, e) => sum + e.amount);
  double get netSocietyBalance => totalIncome - totalExpenses;
  double get cashBalance => 0.0;
  double get bankBalance => netSocietyBalance;

  Map<String, double> getExpenseCategoryBreakdown() {
    Map<String, double> breakdown = {};
    for (var entry in expenses) {
      breakdown[entry.category] = (breakdown[entry.category] ?? 0.0) + entry.amount;
    }
    return breakdown;
  }

  Map<String, double> getIncomeCategoryBreakdown() {
    Map<String, double> breakdown = {};
    for (var entry in incomes) {
      breakdown[entry.category] = (breakdown[entry.category] ?? 0.0) + entry.amount;
    }
    return breakdown;
  }

  Future<void> addLedgerEntry({
    required LedgerEntry entry,
    Uint8List? documentBytes,
    String documentExtension = 'jpg',
  }) async {
    await _firestoreService.recordLedgerEntry(
      entry: entry,
      documentBytes: documentBytes,
      documentExtension: documentExtension,
    );
  }

  Future<Uint8List> generateAgmAuditPdf({
    required String societyNameEn,
    required String societyNameMr,
    required String registrationNo,
    required String societyAddress,
    required int financialYear,
  }) async {
    return await AuditExportService.generateAgmAuditPdf(
      entries: _ledger,
      societyNameEn: societyNameEn,
      societyNameMr: societyNameMr,
      registrationNo: registrationNo,
      societyAddress: societyAddress,
      financialYear: financialYear,
    );
  }

  String generateAuditCsv() {
    return AuditExportService.generateAuditCsv(_ledger);
  }
}
