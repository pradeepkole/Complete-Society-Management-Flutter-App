import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/society_model.dart';
import '../../models/ledger_entry_model.dart';
import '../../models/maintenance_bill_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_app_bar.dart';

class SoftAdminControlScreen extends StatefulWidget {
  const SoftAdminControlScreen({super.key});

  @override
  State<SoftAdminControlScreen> createState() => _SoftAdminControlScreenState();
}

class _SoftAdminControlScreenState extends State<SoftAdminControlScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestore = FirestoreService.instance;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isMr = lang.isMarathi;
    final currentSoc = auth.currentSociety;

    if (!auth.isSoftAdmin) {
      return Scaffold(
        appBar: CustomAppBar(title: isMr ? 'मास्टर पॅनल' : 'Master Panel'),
        body: const Center(
          child: Text('Unauthorized / परवानगी नाही', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: isMr ? 'मास्टर कंट्रोल (SoftAdmin)' : 'Master Control (SoftAdmin)',
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            tooltip: isMr ? 'सोसायटी बदला' : 'Switch Society',
            onPressed: () => _showSocietyPickerModal(context, auth, isMr),
          ),
        ],
      ),
      body: currentSoc == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('कोणतीही सोसायटी निवडलेली नाही.'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _showSocietyPickerModal(context, auth, isMr),
                    child: const Text('सोसायटी निवडा'),
                  ),
                ],
              ),
            )
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SoftAdmin Identity Banner
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.shield, color: Color(0xFF38BDF8), size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isMr ? 'SoftAdmin मास्टर पॅनल (पूर्णपणे गुप्त)' : 'SoftAdmin Master Panel (Hidden)',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0284C7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('ROOT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isMr
                                    ? 'चालू संस्था: ${currentSoc.nameMr} (${currentSoc.societyCode})'
                                    : 'Active Society: ${currentSoc.name} (${currentSoc.societyCode})',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isMr
                                    ? 'ईमेल: pradeepkole@gmail • अधिकृत नंबर: 9822681814 / 9623458653'
                                    : 'Auth Email: pradeepkole@gmail • Phone: 9822681814 / 9623458653',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Master Action Card: Blank All Transactions
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFEF4444)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isMr ? 'डेटाबेस व्यवहार ब्लँक / रिसेट करा' : 'Blank / Reset All Transactions',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF991B1B)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isMr
                                    ? 'या सोसायटीच्या सर्व लेजर एन्ट्रीज (+ve व -ve), मेंटेनन्स बिले आणि हँडओव्हर नोंदी पुसून शून्य (०) केल्या जातील. नवीन सुरुवात किंवा चाचणी डेटा स्वच्छ करण्यासाठी वापरावे.'
                                    : 'Wipes all ledger transactions, bills, and handovers for this society. Flats & members remain safe.',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D), height: 1.3),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  icon: _isResetting
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Icon(Icons.delete_sweep, size: 18),
                                  label: Text(
                                    isMr ? '⚠️ सर्व व्यवहार ब्लँक करा (Blank Transactions)' : '⚠️ Blank All Transactions',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: _isResetting ? null : () => _confirmBlankAllTransactions(context, currentSoc, isMr),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tab Bar
                        TabBar(
                          controller: _tabController,
                          labelColor: AppTheme.primaryNavy,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: AppTheme.primaryNavy,
                          tabs: [
                            Tab(icon: const Icon(Icons.account_balance_wallet, size: 18), text: isMr ? 'लेजर व्यवहार' : 'Ledger Entries'),
                            Tab(icon: const Icon(Icons.receipt_long, size: 18), text: isMr ? 'सर्व बिले' : 'Bills'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildLedgerTab(currentSoc.id, isMr),
                  _buildBillsTab(currentSoc.id, isMr),
                ],
              ),
            ),
    );
  }

  Widget _buildLedgerTab(String societyId, bool isMr) {
    return StreamBuilder<List<LedgerEntry>>(
      stream: _firestore.streamLedgerEntries(societyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return Center(
            child: Text(
              isMr ? 'कोणतेही लेजर व्यवहार उपलब्ध नाहीत (ब्लँक).' : 'No ledger entries (Blank).',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final isNegative = entry.amount < 0 || entry.isReversal;
            final isIncome = entry.isIncome;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isNegative ? Colors.orange.shade300 : (entry.isCancelled ? Colors.red.shade200 : Colors.grey.shade200),
                ),
              ),
              child: ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isMr ? entry.titleMr : entry.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          decoration: entry.isCancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (entry.isReversal)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange)),
                        child: Text(isMr ? 'रिव्हर्सल (-)' : 'Reversal (-)', style: const TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold)),
                      )
                    else if (entry.isCancelled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red)),
                        child: Text(isMr ? 'रद्द' : 'Cancelled', style: const TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                subtitle: Text(
                  '${entry.voucherNo} • ${AppDateFormatter.formatDate(entry.transactionDate, isMarathi: isMr)} • ${AppDateFormatter.formatCurrency(entry.amount)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isIncome ? Colors.green.shade700 : (isNegative ? Colors.orange.shade900 : Colors.red.shade700),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit Button
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: Color(0xFF1E3A8A)),
                      tooltip: isMr ? 'एडिट करा' : 'Edit',
                      onPressed: () => _showEditEntryDialog(context, entry, isMr),
                    ),
                    // Hard Delete Button
                    IconButton(
                      icon: const Icon(Icons.delete_forever, size: 20, color: Color(0xFFDC2626)),
                      tooltip: isMr ? 'कायमचे डिलीट करा' : 'Hard Delete',
                      onPressed: () => _confirmHardDeleteEntry(context, entry, isMr),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBillsTab(String societyId, bool isMr) {
    return StreamBuilder<List<MaintenanceBill>>(
      stream: _firestore.streamMaintenanceBills(societyId: societyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bills = snapshot.data ?? [];
        if (bills.isEmpty) {
          return Center(
            child: Text(
              isMr ? 'कोणतीही बिले उपलब्ध नाहीत (ब्लँक).' : 'No bills found.',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bills.length,
          itemBuilder: (context, index) {
            final bill = bills[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  'फ्लॅट ${bill.flatNumber} (विंग ${bill.wing}) - ${bill.memberName}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${AppDateFormatter.getMonthName(bill.billMonth, isMarathi: isMr)} ${bill.billYear} • ${AppDateFormatter.formatCurrency(bill.totalAmount)} • ${bill.isPaid ? (isMr ? "भरले" : "Paid") : (isMr ? "प्रलंबित" : "Pending")}',
                  style: TextStyle(fontSize: 11, color: bill.isPaid ? Colors.green : Colors.orange),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_forever, size: 20, color: Colors.red),
                  tooltip: isMr ? 'बिल कायमचे हटवा' : 'Delete Bill',
                  onPressed: () => _confirmHardDeleteBill(context, bill, isMr),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- ACTIONS & DIALOGS ---

  void _showSocietyPickerModal(BuildContext context, AuthProvider auth, bool isMr) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return FutureBuilder<List<SocietyModel>>(
          future: _firestore.getAllSocieties(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }

            final societies = snapshot.data ?? [];
            if (societies.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(isMr ? 'कोणतीही सोसायटी नोंदणीकृत नाही.' : 'No societies found.')),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.apartment, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 8),
                      Text(
                        isMr ? 'व्यवस्थापनासाठी सोसायटी निवडा' : 'Switch Society to Manage',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: societies.length,
                      itemBuilder: (context, i) {
                        final soc = societies[i];
                        final isSelected = soc.id == auth.currentSociety?.id;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade200,
                            child: Icon(Icons.business, color: isSelected ? Colors.white : Colors.black54),
                          ),
                          title: Text(isMr ? soc.nameMr : soc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('कोड: ${soc.societyCode} • फ्लॅट्स: ${soc.totalFlats} • ${soc.city}'),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                          onTap: () {
                            auth.switchSocietyForSoftAdmin(soc);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isMr ? '${soc.nameMr} सक्रिय झाली!' : '${soc.name} activated!')),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmHardDeleteEntry(BuildContext context, LedgerEntry entry, bool isMr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isMr ? 'कायमचे डिलीट करा?' : 'Hard Delete Record?'),
        content: Text(
          isMr
              ? 'आपण "${entry.titleMr}" (${AppDateFormatter.formatCurrency(entry.amount)}) ही एन्ट्री डेटाबेसमधून कायमची पुसून टाकत आहात. ही कृती परत करता येणार नाही.'
              : 'Permanently remove this entry from Firestore database?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isMr ? 'रद्द करा' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await _firestore.softAdminHardDeleteLedgerEntry(entry.id);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isMr ? 'एन्ट्री कायमची डिलीट झाली!' : 'Entry hard deleted!')),
                );
              }
            },
            child: Text(isMr ? 'होय, डिलीट करा' : 'Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showEditEntryDialog(BuildContext context, LedgerEntry entry, bool isMr) {
    final titleController = TextEditingController(text: isMr ? entry.titleMr : entry.title);
    final amountController = TextEditingController(text: entry.amount.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isMr ? 'एन्ट्री एडिट करा (SoftAdmin)' : 'Edit Entry (SoftAdmin)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: isMr ? 'शीर्षक / तपशील' : 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: isMr ? 'रक्कम (+ve किंवा -ve टाका)' : 'Amount (supports +ve or -ve)',
                helperText: isMr ? 'उदा. ५०० किंवा -५००' : 'e.g. 500 or -500',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isMr ? 'रद्द करा' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
            onPressed: () async {
              final newAmount = double.tryParse(amountController.text.trim()) ?? entry.amount;
              final newTitle = titleController.text.trim();

              await _firestore.softAdminUpdateLedgerEntry(
                entryId: entry.id,
                data: {
                  'title': newTitle,
                  'titleMr': newTitle,
                  'amount': newAmount,
                },
              );

              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isMr ? 'एन्ट्री यशस्वीरीत्या अपडेट केली!' : 'Entry updated!')),
                );
              }
            },
            child: Text(isMr ? 'जतन करा' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _confirmHardDeleteBill(BuildContext context, MaintenanceBill bill, bool isMr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isMr ? 'बिल डिलीट करा?' : 'Delete Bill?'),
        content: Text(isMr ? 'फ्लॅट ${bill.flatNumber} चे हे बिल डेटाबेसमधून कायमचे हटवायचे का?' : 'Delete this bill?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isMr ? 'रद्द करा' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await _firestore.softAdminHardDeleteBill(bill.id);
              if (context.mounted) {
                Navigator.pop(ctx);
              }
            },
            child: Text(isMr ? 'डिलीट करा' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmBlankAllTransactions(BuildContext context, SocietyModel society, bool isMr) {
    final pinController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isMr ? '⚠️ पुष्टी करा: सर्व व्यवहार ब्लँक' : 'Confirm: Blank Transactions',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMr
                    ? 'आपण "${society.nameMr}" या संस्थेचा संपूर्ण लेजर हिशोब, सर्व मेंटेनन्स बिले व हँडओव्हर डेटा पुसून शून्य करत आहात.\n\nपुष्टी करण्यासाठी आपला ६-अंकी मास्टर कोड (458653 किंवा 681814) प्रविष्ट करा:'
                    : 'Enter master PIN (458653 or 681814) to confirm wiping all ledger & bills:',
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '••••••',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  counterText: '',
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 6),
                Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isMr ? 'रद्द करा' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                final pin = pinController.text.trim();
                if (pin != '458653' && pin != '681814') {
                  setModalState(() => errorText = isMr ? 'चुकीचा मास्टर कोड!' : 'Invalid PIN!');
                  return;
                }

                Navigator.pop(ctx);
                setState(() => _isResetting = true);

                await _firestore.softAdminBlankAllTransactions(society.id);

                if (mounted) {
                  setState(() => _isResetting = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green.shade800,
                      content: Text(
                        isMr
                            ? 'या सोसायटीचे सर्व व्यवहार यशस्वीरीत्या ब्लँक करण्यात आले आहेत!'
                            : 'All transactions for this society have been wiped clean!',
                      ),
                    ),
                  );
                }
              },
              child: Text(isMr ? 'पुष्टी करा व ब्लँक करा' : 'Confirm & Wipe'),
            ),
          ],
        ),
      ),
    );
  }
}
