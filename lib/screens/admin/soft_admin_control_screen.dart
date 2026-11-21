import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/society_model.dart';
import '../../models/ledger_entry_model.dart';
import '../../models/maintenance_bill_model.dart';
import '../../models/notice_model.dart';
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
  final TextEditingController _activeDaysController = TextEditingController();
  int _societiesReloadTrigger = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _activeDaysController.dispose();
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

                        // Subscription Management Card (SoftAdmin Exclusive)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    currentSoc.isPro ? Icons.stars : Icons.bolt,
                                    color: currentSoc.isPro ? const Color(0xFFD97706) : const Color(0xFF0284C7),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isMr ? 'सबस्क्रिप्शन व परवाना नियंत्रण' : 'Subscription & License Control',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: currentSoc.isSubscriptionDisabled
                                          ? Colors.red.shade700
                                          : (currentSoc.isPro ? const Color(0xFFD97706) : const Color(0xFF0284C7)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      currentSoc.isSubscriptionDisabled
                                          ? (isMr ? '🔴 बंद (OFF)' : 'OFF')
                                          : (currentSoc.isPro ? '⭐ PRO' : '⚡ DEMO'),
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isMr
                                    ? 'वैधता समाप्ती: ${AppDateFormatter.formatDate(currentSoc.effectiveExpiryDate, isMarathi: isMr)} • ${currentSoc.remainingSubscriptionDays} दिवस शिल्लक'
                                    : 'Valid Until: ${AppDateFormatter.formatDate(currentSoc.effectiveExpiryDate, isMarathi: isMr)} • ${currentSoc.remainingSubscriptionDays} days left',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: currentSoc.remainingSubscriptionDays <= 15 ? Colors.red.shade700 : const Color(0xFF14532D),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF15803D),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    icon: const Icon(Icons.add_task, size: 16),
                                    label: Text(isMr ? '⭐ +१ वर्ष Pro टॉप-अप' : '⭐ +1 Year Pro Renew'),
                                    onPressed: () async {
                                      final ok = await auth.renewSocietyProYear(currentSoc.id);
                                      if (context.mounted && ok) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: Colors.green,
                                            content: Text(isMr ? '१ वर्ष Pro सबस्क्रिप्शन यशस्वीरित्या सक्रिय झाले!' : 'Pro subscription renewed for 1 year!'),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF166534),
                                      side: const BorderSide(color: Color(0xFF166534)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    icon: const Icon(Icons.edit_calendar, size: 16),
                                    label: Text(isMr ? 'दिवस बदला (+/-)' : 'Adjust Days'),
                                    onPressed: () => _showAdjustSubscriptionDialog(context, currentSoc, auth, isMr),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: currentSoc.isSubscriptionDisabled ? Colors.green.shade800 : Colors.red.shade800,
                                      side: BorderSide(color: currentSoc.isSubscriptionDisabled ? Colors.green : Colors.red),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    icon: Icon(currentSoc.isSubscriptionDisabled ? Icons.check_circle_outline : Icons.power_settings_new, size: 16),
                                    label: Text(
                                      currentSoc.isSubscriptionDisabled
                                          ? (isMr ? 'सबस्क्रिप्शन चालू करा (ON)' : 'Enable (ON)')
                                          : (isMr ? 'सबस्क्रिप्शन बंद करा (OFF)' : 'Disable (OFF)'),
                                    ),
                                    onPressed: () async {
                                      final enable = currentSoc.isSubscriptionDisabled;
                                      final ok = await auth.toggleSocietySubscription(currentSoc.id, enable);
                                      if (context.mounted && ok) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: enable ? Colors.green : Colors.red,
                                            content: Text(
                                              enable
                                                  ? (isMr ? 'सबस्क्रिप्शन चालू केले!' : 'Subscription Enabled!')
                                                  : (isMr ? 'सबस्क्रिप्शन बंद केले (OFF)!' : 'Subscription Disabled (OFF)!'),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isMr ? 'शिल्लक दिवस थेट सेट करा (मागील दिवस न मोजता):' : 'Set Exact Remaining Days (Direct):',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 38,
                                      child: TextFormField(
                                        controller: _activeDaysController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          hintText: isMr ? 'उदा. 365, 45, 60' : 'e.g. 365, 45, 60',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          suffixText: isMr ? 'दिवस' : 'days',
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF15803D),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.check, size: 16),
                                    label: Text(isMr ? 'लागू करा' : 'Apply'),
                                    onPressed: () async {
                                      final days = int.tryParse(_activeDaysController.text.trim());
                                      if (days == null || days < 0) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(isMr ? 'कृपया योग्य दिवस टाका (० किंवा अधिक)' : 'Enter valid days (0 or more)')),
                                        );
                                        return;
                                      }
                                      final ok = await auth.setExactSubscriptionDays(currentSoc.id, days);
                                      if (context.mounted && ok) {
                                        setState(() => _societiesReloadTrigger++);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: Colors.green,
                                            content: Text(isMr ? 'सबस्क्रिप्शन अचूक $days दिवस सेट झाले!' : 'Subscription set to $days days!'),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
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
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: AppTheme.primaryNavy,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: AppTheme.primaryNavy,
                          tabs: [
                            Tab(icon: const Icon(Icons.domain, size: 18), text: isMr ? 'सर्व संस्था परवाने' : 'All Societies'),
                            Tab(icon: const Icon(Icons.account_balance_wallet, size: 18), text: isMr ? 'लेजर व्यवहार' : 'Ledger Entries'),
                            Tab(icon: const Icon(Icons.receipt_long, size: 18), text: isMr ? 'सर्व बिले' : 'Bills'),
                            Tab(icon: const Icon(Icons.campaign, size: 18), text: isMr ? 'सूचना फलक' : 'Notices'),
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
                  _buildAllSocietiesTab(auth, isMr),
                  _buildLedgerTab(currentSoc.id, isMr),
                  _buildBillsTab(currentSoc.id, isMr),
                  _buildNoticesTab(currentSoc.id, isMr),
                ],
              ),
            ),
    );
  }

  Widget _buildAllSocietiesTab(AuthProvider auth, bool isMr) {
    return FutureBuilder<List<SocietyModel>>(
      key: ValueKey(_societiesReloadTrigger),
      future: _firestore.getAllSocieties(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final societies = snapshot.data ?? [];
        if (societies.isEmpty) {
          return Center(
            child: Text(
              isMr ? 'कोणतीही संस्था नोंदणीकृत नाही.' : 'No societies found.',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: societies.length,
          itemBuilder: (context, index) {
            final soc = societies[index];
            return _buildSocietySubscriptionCard(soc, auth, isMr);
          },
        );
      },
    );
  }

  Widget _buildSocietySubscriptionCard(SocietyModel soc, AuthProvider auth, bool isMr) {
    final isSelected = soc.id == auth.currentSociety?.id;
    final daysCtrl = TextEditingController(text: '${soc.remainingSubscriptionDays}');

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade200,
                  child: Icon(Icons.apartment, color: isSelected ? Colors.white : Colors.black87),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMr ? soc.nameMr : soc.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'कोड: ${soc.societyCode} • ${soc.city} • ${soc.totalFlats} फ्लॅट्स',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: soc.isSubscriptionDisabled
                        ? Colors.red.shade700
                        : (soc.isPro ? const Color(0xFFD97706) : const Color(0xFF0284C7)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    soc.isSubscriptionDisabled
                        ? (isMr ? '🔴 बंद (OFF)' : 'OFF')
                        : (soc.isPro ? '⭐ PRO' : '⚡ DEMO'),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),

            // Subscription Dates & Shillak Days Display
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMr ? 'खरेदी / सुरू तारीख:' : 'Start / Purchase Date:',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                      Text(
                        AppDateFormatter.formatDate(soc.subscriptionStartDate ?? soc.createdAt ?? DateTime.now(), isMarathi: isMr),
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMr ? 'वैधता समाप्ती तारीख:' : 'Validity Expiry Date:',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                      Text(
                        AppDateFormatter.formatDate(soc.effectiveExpiryDate, isMarathi: isMr),
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMr ? 'शिल्लक कालावधी:' : 'Remaining Days:',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                      Text(
                        isMr ? '${soc.remainingSubscriptionDays} दिवस शिल्लक' : '${soc.remainingSubscriptionDays} days left',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: soc.remainingSubscriptionDays <= 15 ? Colors.red.shade700 : const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // User's Requested Textbox for Exact Remaining Days
            Text(
              isMr ? 'शिल्लक दिवस थेट सेट करा (मागील दिवस न मोजता):' : 'Set Exact Remaining Days (Direct):',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextFormField(
                      controller: daysCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        hintText: isMr ? 'उदा. 365, 45, 60' : 'e.g. 365, 45, 60',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        suffixText: isMr ? 'दिवस' : 'days',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(isMr ? 'लागू करा' : 'Set'),
                  onPressed: () async {
                    final parsedDays = int.tryParse(daysCtrl.text.trim());
                    if (parsedDays == null || parsedDays < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isMr ? 'कृपया योग्य दिवस टाका (० किंवा अधिक)' : 'Enter valid days (0 or more)')),
                      );
                      return;
                    }
                    final ok = await auth.setExactSubscriptionDays(soc.id, parsedDays);
                    if (context.mounted && ok) {
                      setState(() => _societiesReloadTrigger++);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.green,
                          content: Text(isMr ? '${soc.nameMr} चे सबस्क्रिप्शन अचूक $parsedDays दिवस सेट झाले!' : 'Subscription set to exactly $parsedDays days!'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Action Shortcuts
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    foregroundColor: const Color(0xFF15803D),
                    side: const BorderSide(color: Color(0xFF15803D)),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  icon: const Icon(Icons.add_task, size: 14),
                  label: Text(isMr ? '⭐ +१ वर्ष Pro' : '⭐ +1 Year Pro'),
                  onPressed: () async {
                    final ok = await auth.renewSocietyProYear(soc.id);
                    if (context.mounted && ok) {
                      setState(() => _societiesReloadTrigger++);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.green,
                          content: Text(isMr ? '${soc.nameMr} ला +१ वर्ष Pro सबस्क्रिप्शन जोडले!' : '+1 Year Pro added!'),
                        ),
                      );
                    }
                  },
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    foregroundColor: soc.isSubscriptionDisabled ? Colors.green.shade800 : Colors.red.shade800,
                    side: BorderSide(color: soc.isSubscriptionDisabled ? Colors.green : Colors.red),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  icon: Icon(soc.isSubscriptionDisabled ? Icons.check_circle_outline : Icons.power_settings_new, size: 14),
                  label: Text(soc.isSubscriptionDisabled ? (isMr ? 'चालू करा (ON)' : 'Enable') : (isMr ? 'बंद करा (OFF)' : 'Disable')),
                  onPressed: () async {
                    final enable = soc.isSubscriptionDisabled;
                    final ok = await auth.toggleSocietySubscription(soc.id, enable);
                    if (context.mounted && ok) {
                      setState(() => _societiesReloadTrigger++);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: enable ? Colors.green : Colors.red,
                          content: Text(enable ? (isMr ? 'सबस्क्रिप्शन चालू केले!' : 'Enabled!') : (isMr ? 'सबस्क्रिप्शन बंद केले (OFF)!' : 'Disabled!')),
                        ),
                      );
                    }
                  },
                ),
                if (!isSelected)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      foregroundColor: const Color(0xFF1E3A8A),
                      side: const BorderSide(color: Color(0xFF1E3A8A)),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.swap_horiz, size: 14),
                    label: Text(isMr ? 'व्यवस्थापनासाठी निवडा' : 'Select'),
                    onPressed: () {
                      auth.switchSocietyForSoftAdmin(soc);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isMr ? '${soc.nameMr} सक्रिय झाली!' : '${soc.name} activated!')),
                      );
                    },
                  ),
              ],
            ),
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

  Widget _buildNoticesTab(String societyId, bool isMr) {
    return StreamBuilder<List<NoticeModel>>(
      stream: _firestore.streamNotices(societyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final notices = snapshot.data ?? [];
        if (notices.isEmpty) {
          return Center(
            child: Text(
              isMr ? 'कोणतीही सूचना उपलब्ध नाही (ब्लँक).' : 'No notices found.',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notices.length,
          itemBuilder: (context, index) {
            final notice = notices[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  isMr ? notice.titleMr : notice.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${notice.category} • ${AppDateFormatter.formatDate(notice.publishedDate, isMarathi: isMr)} • ${notice.issuedByName}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_forever, size: 20, color: Colors.red),
                  tooltip: isMr ? 'सूचना कायमची हटवा' : 'Delete Notice',
                  onPressed: () => _confirmHardDeleteNotice(context, notice, isMr),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmHardDeleteNotice(BuildContext context, NoticeModel notice, bool isMr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isMr ? 'सूचना डिलीट करा?' : 'Delete Notice?'),
        content: Text(
          isMr
              ? 'आपण "${notice.titleMr.isNotEmpty ? notice.titleMr : notice.title}" ही सूचना कायमची पुसून टाकू इच्छिता का?'
              : 'Delete this notice permanently?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isMr ? 'रद्द' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await _firestore.deleteNotice(notice.id);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isMr ? 'सूचना डिलीट झाली!' : 'Notice deleted!')),
                );
              }
            },
            child: Text(isMr ? 'हटवा' : 'Delete'),
          ),
        ],
      ),
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
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(isMr ? soc.nameMr : soc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: soc.isSubscriptionDisabled
                                      ? Colors.red.shade700
                                      : (soc.isPro ? const Color(0xFFD97706) : const Color(0xFF0284C7)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  soc.isSubscriptionDisabled
                                      ? 'OFF'
                                      : (soc.isPro ? 'PRO • ${soc.remainingSubscriptionDays}d' : 'DEMO • ${soc.remainingSubscriptionDays}d'),
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('कोड: ${soc.societyCode} • ${soc.city} • ${soc.totalFlats} फ्लॅट्स'),
                              const SizedBox(height: 2),
                              Text(
                                'खरेदी: ${AppDateFormatter.formatDate(soc.subscriptionStartDate ?? soc.createdAt ?? DateTime.now(), isMarathi: isMr)} • मुदत: ${AppDateFormatter.formatDate(soc.effectiveExpiryDate, isMarathi: isMr)}',
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                              ),
                              Text(
                                'शिल्लक दिवस: ${soc.remainingSubscriptionDays} दिवस',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: soc.remainingSubscriptionDays <= 15 ? Colors.red : const Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_calendar, color: Color(0xFF1E3A8A), size: 18),
                                tooltip: isMr ? 'थेट दिवस सेट करा' : 'Set Exact Days',
                                onPressed: () => _showDirectDaysDialog(context, soc, auth, isMr),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_task, color: Color(0xFF15803D), size: 18),
                                tooltip: isMr ? '+१ वर्ष Pro रिन्यू करा' : '+1 Year Pro Renew',
                                onPressed: () async {
                                  await auth.renewSocietyProYear(soc.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.green,
                                        content: Text(isMr ? '${soc.nameMr} ला +१ वर्ष Pro सबस्क्रिप्शन जोडले!' : '+1 Year Pro renewed for ${soc.name}!'),
                                      ),
                                    );
                                  }
                                },
                              ),
                              if (isSelected) const Icon(Icons.check_circle, color: Colors.green),
                            ],
                          ),
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

  void _showAdjustSubscriptionDialog(BuildContext context, SocietyModel society, AuthProvider auth, bool isMr) {
    int daysToAdd = 30;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isMr ? 'सबस्क्रिप्शन दिवस वाढवा / कमी करा' : 'Adjust Subscription Days'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMr
                    ? 'चालू मुदत: ${AppDateFormatter.formatDate(society.effectiveExpiryDate, isMarathi: isMr)} (${society.remainingSubscriptionDays} दिवस बाकी)'
                    : 'Current Expiry: ${AppDateFormatter.formatDate(society.effectiveExpiryDate, isMarathi: isMr)} (${society.remainingSubscriptionDays} days remaining)',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              Text(isMr ? 'बदल करायचे दिवस निवडा:' : 'Select days to adjust:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: daysToAdd,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: [
                  DropdownMenuItem(value: 365, child: Text(isMr ? '+३६५ दिवस (+१ वर्ष Pro)' : '+365 Days (+1 Year Pro)')),
                  DropdownMenuItem(value: 180, child: Text(isMr ? '+१८० दिवस (+६ महिने)' : '+180 Days (+6 Months)')),
                  DropdownMenuItem(value: 90, child: Text(isMr ? '+९० दिवस (+३ महिने)' : '+90 Days (+3 Months)')),
                  DropdownMenuItem(value: 45, child: Text(isMr ? '+४५ दिवस (Demo Top-up)' : '+45 Days (Demo Top-up)')),
                  DropdownMenuItem(value: 30, child: Text(isMr ? '+३० दिवस (+१ महिना)' : '+30 Days (+1 Month)')),
                  DropdownMenuItem(value: -15, child: Text(isMr ? '-१५ दिवस (कमी करा)' : '-15 Days (Reduce)')),
                  DropdownMenuItem(value: -30, child: Text(isMr ? '-३० दिवस (कमी करा)' : '-30 Days (Reduce)')),
                ],
                onChanged: (val) {
                  if (val != null) setDlgState(() => daysToAdd = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isMr ? 'रद्द' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await auth.adjustSocietySubscriptionDays(society.id, daysToAdd);
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(isMr ? 'सबस्क्रिप्शन दिवस यशस्वीरित्या बदलले!' : 'Subscription days updated!'),
                    ),
                  );
                }
              },
              child: Text(isMr ? 'बदल लागू करा' : 'Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDirectDaysDialog(BuildContext context, SocietyModel soc, AuthProvider auth, bool isMr) {
    final ctrl = TextEditingController(text: '${soc.remainingSubscriptionDays}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isMr ? '${soc.nameMr} - थेट दिवस सेट करा' : 'Set Exact Days for ${soc.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMr
                  ? 'चालू मुदत: ${AppDateFormatter.formatDate(soc.effectiveExpiryDate, isMarathi: isMr)} (${soc.remainingSubscriptionDays} दिवस बाकी)'
                  : 'Current: ${AppDateFormatter.formatDate(soc.effectiveExpiryDate, isMarathi: isMr)} (${soc.remainingSubscriptionDays} days left)',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              isMr ? 'नवीन शिल्लक दिवस (मागील दिवस न मोजता थेट):' : 'Direct remaining days (without previous calculation):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: isMr ? 'उदा. 365, 45, 60' : 'e.g. 365, 45, 60',
                suffixText: isMr ? 'दिवस' : 'days',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isMr ? 'रद्द' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () async {
              final d = int.tryParse(ctrl.text.trim());
              if (d == null || d < 0) return;
              Navigator.pop(ctx);
              final ok = await auth.setExactSubscriptionDays(soc.id, d);
              if (context.mounted && ok) {
                setState(() => _societiesReloadTrigger++);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.green,
                    content: Text(isMr ? '${soc.nameMr} चे सबस्क्रिप्शन अचूक $d दिवस सेट झाले!' : 'Subscription set to $d days!'),
                  ),
                );
              }
            },
            child: Text(isMr ? 'लागू करा' : 'Apply'),
          ),
        ],
      ),
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
