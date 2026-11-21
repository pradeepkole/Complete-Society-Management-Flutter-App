import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/society_model.dart';
import '../utils/date_formatter.dart';
import '../l10n/language_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/admin/society_settings_screen.dart';
import '../screens/admin/soft_admin_control_screen.dart';
import 'language_toggle_button.dart';
import 'society_logo_widget.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showLanguageToggle;
  final bool showSettings;

  const CustomAppBar({
    super.key,
    this.title,
    this.actions,
    this.showLanguageToggle = true,
    this.showSettings = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isMr = lang.isMarathi;
    final society = auth.currentSociety;
    final user = auth.currentUser;

    final societyDisplayName = society != null
        ? (isMr && society.nameMr.isNotEmpty ? society.nameMr : society.name)
        : (isMr ? 'गृहनिर्माण संस्था' : 'Housing Society');

    return AppBar(
      titleSpacing: 12,
      title: Row(
        children: [
          // Society Logo (Hidden Trigger: Long press opens SoftAdmin Master Panel ONLY if softadmin is logged in)
          GestureDetector(
            onLongPress: () {
              if (auth.isSoftAdmin) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SoftAdminControlScreen()),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: SocietyLogoWidget(
                logoUrl: society?.logoUrl,
                fallbackText: societyDisplayName,
                size: 38,
                borderRadius: 8,
              ),
            ),
          ),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title ?? societyDisplayName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user != null)
                  Text(
                    '${isMr && user.nameMr.isNotEmpty ? user.nameMr : user.name}${user.flatNumber.isNotEmpty ? " • ${user.wing.isNotEmpty ? 'Wing ${user.wing}-' : ''}${user.flatNumber}" : ""}',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (society != null)
          _buildSubscriptionBadge(context, society, isMr),
        if (actions != null) ...actions!,
        if (showLanguageToggle)
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Center(child: LanguageToggleButton(isDark: true)),
          ),
        if (showSettings && auth.isAdmin)
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 20),
            tooltip: isMr ? 'सोसायटी सेटिंग्ज' : 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SocietySettingsScreen()),
              );
            },
          ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
          tooltip: isMr ? 'साइन आऊट' : 'Sign Out',
          onPressed: () => auth.signOut(),
        ),
      ],
    );
  }

  Widget _buildSubscriptionBadge(BuildContext context, SocietyModel society, bool isMr) {
    final isPro = society.isPro;
    final days = society.remainingSubscriptionDays;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showSubscriptionInfoSheet(context, society, isMr),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            gradient: isPro
                ? const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPro ? const Color(0xFFFDE68A) : const Color(0xFFBAE6FD),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPro ? Icons.stars : Icons.bolt,
                color: isPro ? const Color(0xFFFEF3C7) : const Color(0xFFFCD34D),
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                isPro ? 'PRO • $days' : 'DEMO • $days',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubscriptionInfoSheet(BuildContext context, SocietyModel society, bool isMr) {
    final isPro = society.isPro;
    final days = society.remainingSubscriptionDays;
    final expiryStr = AppDateFormatter.formatDate(society.effectiveExpiryDate, isMarathi: isMr);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPro ? Icons.stars : Icons.bolt,
                  color: isPro ? const Color(0xFFF59E0B) : const Color(0xFF0284C7),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPro
                            ? (isMr ? '🌟 Pro परवाना (१ वर्ष)' : '🌟 Pro License (1 Year)')
                            : (isMr ? '⚡ Demo चाचणी (४५ दिवस)' : '⚡ Demo Trial (45 Days)'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isMr ? 'सोसायटी गेट प्रणाली परवाना' : 'Society Gate License',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isMr ? 'वैधता समाप्ती तारीख:' : 'Expiry Date:', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                Text(expiryStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isMr ? 'शिल्लक कालावधी:' : 'Days Remaining:', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                Text(
                  isMr ? '$days दिवस बाकी' : '$days days left',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: days <= 15 ? Colors.red : (isPro ? const Color(0xFFD97706) : const Color(0xFF0284C7)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent, color: Color(0xFF1E3A8A)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isMr
                          ? 'रिन्यूअल किंवा प्रो अपग्रेडसाठी संपर्क:\n📞 ९८२२६८१८१४ (9822681814)'
                          : 'For renewal or Pro upgrade contact:\n📞 9822681814',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackLogo(String name) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'S',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
