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
    LedgerEntry? entry,
    String? type,
    String? category,
    String? title,
    String? titleMr,
    double? amount,
    String? paymentMode,
    String? voucherNo,
    String? vendorName,
    String? billAttachmentUrl,
    String? recordedByUid,
    String? notes,
    Uint8List? documentBytes,
    String documentExtension = 'jpg',
  }) async {
    final finalEntry = entry ??
        LedgerEntry(
          id: '',
          societyId: _societyId ?? '',
          transactionDate: DateTime.now(),
          type: type ?? 'expense',
          category: category ?? 'General',
          title: title ?? '',
          titleMr: titleMr ?? title ?? '',
          amount: amount ?? 0.0,
          paymentMode: paymentMode ?? 'cash',
          voucherNo: voucherNo ?? 'VCH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          vendorName: vendorName ?? '',
          billAttachmentUrl: billAttachmentUrl ?? '',
          recordedByUid: recordedByUid ?? 'admin',
          notes: notes ?? '',
        );

    await _firestoreService.recordLedgerEntry(
      entry: finalEntry,
      documentBytes: documentBytes,
      documentExtension: documentExtension,
    );
  }

  /// Super Admin cancels an expense entry; triggers automatic negative contra entry
  Future<void> cancelLedgerEntry({
    required String entryId,
    required String reason,
    required String adminUid,
  }) async {
    await _firestoreService.cancelLedgerEntry(
      entryId: entryId,
      reason: reason,
      adminUid: adminUid,
    );
  }

  Future<Uint8List> exportAuditPdf({
    String? societyName,
    String? registrationNo,
    int? year,
  }) async {
    return await AuditExportService.generateAuditPdf(
      societyNameEn: societyName ?? 'Housing Society',
      registrationNo: registrationNo ?? 'REG-${_societyId ?? "MUMBAI"}',
      entries: _ledger,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netBalance: netSocietyBalance,
      bankBalance: bankBalance,
      cashBalance: cashBalance,
      year: year ?? DateTime.now().year,
    );
  }

  String exportFinancialCsv({String? societyName}) {
    return AuditExportService.generateFinancialCsv(
      societyName: societyName ?? 'Housing Society',
      entries: _ledger,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netBalance: netSocietyBalance,
      bankBalance: bankBalance,
      cashBalance: cashBalance,
    );
  }

  Future<Uint8List> generateAgmAuditPdf({
    required String societyNameEn,
    required String societyNameMr,
    required String registrationNo,
    required String societyAddress,
    required int financialYear,
  }) async {
    return await AuditExportService.generateAuditPdf(
      entries: _ledger,
      societyNameEn: societyNameEn,
      registrationNo: registrationNo,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netBalance: netSocietyBalance,
      bankBalance: bankBalance,
      cashBalance: cashBalance,
      year: financialYear,
    );
  }

  String generateAuditCsv({String? societyName}) {
    return AuditExportService.generateFinancialCsv(
      societyName: societyName ?? 'Housing Society',
      entries: _ledger,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netBalance: netSocietyBalance,
      bankBalance: bankBalance,
      cashBalance: cashBalance,
    );
  }
}
