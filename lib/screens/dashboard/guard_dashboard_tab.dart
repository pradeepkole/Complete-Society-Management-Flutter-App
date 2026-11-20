import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/visitor_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/summary_card.dart';
import '../visitors/visitor_checkin_screen.dart';
import '../visitors/visitor_log_screen.dart';

class GuardDashboardTab extends StatelessWidget {
  const GuardDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final visitorProvider = Provider.of<VisitorProvider>(context);

    final insideVisitors = visitorProvider.activeInsideVisitors;
    final totalToday = visitorProvider.allVisitors.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security Guard Gate Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB45309), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.security, color: Color(0xFFB45309), size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.isMarathi ? 'मुख्य सुरक्षा गेट (Gate 1)' : 'Main Security Gate #1',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'On Duty: ${auth.currentUser?.name ?? "Ramesh Shinde"}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Shift: Day Shift (8:00 AM - 8:00 PM)',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Log New Visitor Big Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add_alt_1, size: 22),
              label: Text(
                lang.tr('newVisitor'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorCheckinScreen()));
              },
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: lang.tr('insideCampus'),
                  value: '${insideVisitors.length}',
                  subtitle: lang.isMarathi ? 'सोसायटी परिसरात उपस्थित' : 'Currently inside',
                  icon: Icons.groups,
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: lang.isMarathi ? 'आजच्या एकूण नोंदी' : "Today's Visitors",
                  value: '$totalToday',
                  subtitle: lang.isMarathi ? 'अभ्यागत नोंदी' : 'Total check-ins',
                  icon: Icons.badge,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Active Inside Visitors List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.isMarathi ? 'सध्या आवारात असलेले पाहुणे / डिलिव्हरी:' : 'Currently Inside Premises:',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorLogScreen()));
                },
                child: Text(lang.tr('viewDetails'), style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (insideVisitors.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                lang.isMarathi ? 'सध्या परिसरात कोणीही पाहुणे नाहीत' : 'No outside visitors currently inside',
                style: const TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: insideVisitors.length,
              itemBuilder: (context, index) {
                final visitor = insideVisitors[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFEF3C7),
                      child: Icon(Icons.person, color: Color(0xFFB45309)),
                    ),
                    title: Text(
                      '${visitor.visitorName} • ${visitor.targetFlat}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      '${lang.tr(visitor.purpose)} • In: ${AppDateFormatter.formatDateTime(visitor.checkInTime, isMarathi: lang.isMarathi)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () => visitorProvider.checkOutVisitor(visitor.id),
                      child: Text(lang.tr('checkOut'), style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 20),

          // Emergency Helpline box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emergency, color: Colors.red.shade800, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      lang.isMarathi ? 'आपत्कालीन संपर्क क्रमांक' : 'Emergency Contacts',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red.shade900),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Secretary (अनिल जोशी): +91 98200 11223', style: TextStyle(fontSize: 11, color: Colors.red.shade800)),
                Text('Police Station (दादर): 100 / 022-24301234', style: TextStyle(fontSize: 11, color: Colors.red.shade800)),
                Text('Ambulance (रुग्णवाहिका): 108', style: TextStyle(fontSize: 11, color: Colors.red.shade800)),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
