import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/language_toggle_button.dart';
import 'create_society_screen.dart';
import 'join_society_screen.dart';

class SocietyChoiceScreen extends StatelessWidget {
  const SocietyChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final isMr = lang.isMarathi;
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isMr ? 'सोसायटी निवड' : 'Select Society',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          const LanguageToggleButton(isDark: false),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: isMr ? 'साइन आऊट' : 'Sign Out',
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // User Profile Header
              if (user != null) ...[
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.primaryNavy.withOpacity(0.1),
                  backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null || user.photoUrl!.isEmpty
                      ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  '${isMr ? "स्वागत आहे, " : "Welcome, "}${user.name}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                  textAlign: TextAlign.center,
                ),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 24),
              ],

              Text(
                isMr
                    ? 'आपण आपल्या गृहनिर्माण संस्थेशी जोडलेले नाही आहात. कृपया खालीलपैकी एक पर्याय निवडा:'
                    : 'You are not connected to a housing society yet. Please choose an option below:',
                style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Option 1: Create New Society (Admin)
              _buildChoiceCard(
                context: context,
                icon: Icons.add_business_rounded,
                iconColor: const Color(0xFF1E3A8A),
                iconBg: const Color(0xFFDBEAFE),
                title: isMr ? 'नवीन सोसायटी नोंदवा' : 'Register New Society',
                subtitle: isMr
                    ? 'तुम्ही संस्था सचिव / कमिटी सदस्य आहात? सोसायटीचे नाव, पत्ता आणि लोगो जोडून नवीन सोसायटी सुरू करा.'
                    : 'Are you the Secretary or Committee? Create a new society profile with address & logo.',
                badgeText: isMr ? 'सोसायटी सचिव / Admin' : 'Admin Setup',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateSocietyScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Option 2: Join Existing Society (Member / Guard)
              _buildChoiceCard(
                context: context,
                icon: Icons.group_add_rounded,
                iconColor: const Color(0xFF059669),
                iconBg: const Color(0xFFD1FAE5),
                title: isMr ? 'विद्यमान सोसायटीत सामील व्हा' : 'Join Existing Society',
                subtitle: isMr
                    ? 'सचिवांनी दिलेला ६-अंकी सोसायटी कोड टाकून फ्लॅट सभासद किंवा सुरक्षा रक्षक म्हणून विनंती पाठवा.'
                    : 'Enter the 6-digit Society Code to join as a Flat Member or Security Guard.',
                badgeText: isMr ? 'फ्लॅट सभासद / Guard' : 'Member Join',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JoinSocietyScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(color: iconColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
