import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/language_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/admin/society_settings_screen.dart';
import 'language_toggle_button.dart';

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
          // Society Logo
          if (society?.logoUrl != null && society!.logoUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  society.logoUrl!,
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildFallbackLogo(societyDisplayName),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _buildFallbackLogo(societyDisplayName),
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
