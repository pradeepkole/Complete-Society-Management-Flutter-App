import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/ledger_entry_model.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';
import '../services/audit_export_service.dart';

class AccountingProvider extends ChangeNotifier {
  final FirebaseService _fallbackService = FirebaseService.instance;
  final FirestoreService _firestoreService = FirestoreService.instance;

  List<LedgerEntry> _ledger = [];
  StreamSubscription<List<LedgerEntry>>? _ledgerSubscription;

  AccountingProvider() {
    _ledger = List.from(_fallbackService.ledger);
    _initLiveFirestoreStream();
  }

  void _initLiveFirestoreStream() {
    try {
      _ledgerSubscription = _firestoreService.streamLedgerEntries().listen((liveEntries) {
        if (liveEntries.isNotEmpty) {
          _ledger = liveEntries;
          notifyListeners();
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _ledgerSubscription?.cancel();
    super.dispose();
  }

  List<LedgerEntry> get ledgerEntries => _ledger.isNotEmpty ? _ledger : _fallbackService.ledger;

  List<LedgerEntry> get expenses => ledgerEntries.where((e) => e.isExpense).toList();
  List<LedgerEntry> get incomes => ledgerEntries.where((e) => e.isIncome).toList();

  double get totalIncome => incomes.fold(0.0, (sum, e) => sum + e.amount);
  double get totalExpenses => expenses.fold(0.0, (sum, e) => sum + e.amount);
  double get netSocietyBalance => totalIncome - totalExpenses + 150000; // Baseline corpus ₹1.5L
  double get cashBalance => 14250.0;
  double get bankBalance => netSocietyBalance - cashBalance;

  /// Calculate breakdown by category for charts
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

  /// Adds ledger entry with optional physical voucher upload to Firebase Storage
  Future<void> addLedgerEntry({
    required String type,
    required String category,
    required String title,
    required String titleMr,
    required double amount,
    required String paymentMode,
    required String voucherNo,
    required String vendorName,
    String billAttachmentUrl = '',
    Uint8List? documentBytes,
    String documentExtension = 'jpg',
    required String recordedByUid,
    String notes = '',
  }) async {
    final entry = LedgerEntry(
      id: 'LED-${DateTime.now().millisecondsSinceEpoch}',
      societyId: FirestoreService.currentSocietyId,
      transactionDate: DateTime.now(),
      type: type,
      category: category,
      title: title,
      titleMr: titleMr,
      amount: amount,
      paymentMode: paymentMode,
      voucherNo: voucherNo,
      vendorName: vendorName,
      billAttachmentUrl: billAttachmentUrl,
      recordedByUid: recordedByUid,
      notes: notes,
    );

    try {
      await _firestoreService.recordLedgerEntry(
        entry: entry,
        documentBytes: documentBytes,
        documentExtension: documentExtension,
      );
    } catch (_) {
      await _fallbackService.addLedgerEntry(entry);
    }
    notifyListeners();
  }

  /// Export Excel (CSV)
  String exportFinancialCsv() {
    return AuditExportService.generateFinancialCsv(
      societyName: _fallbackService.activeSociety.name,
      entries: ledgerEntries,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netBalance: netSocietyBalance,
      bankBalance: bankBalance,
      cashBalance: cashBalance,
    );
  }

  /// Export PDF Statement
  Future<Uint8List> exportAuditPdf() async {
    return await AuditExportService.generateAuditPdf(
      societyNameEn: _fallbackService.activeSociety.name,
      registrationNo: _fallbackService.activeSociety.registrationNo,
      entries: ledgerEntries,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netBalance: netSocietyBalance,
      bankBalance: bankBalance,
      cashBalance: cashBalance,
      year: DateTime.now().year,
    );
  }
}
