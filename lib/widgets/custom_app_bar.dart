import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/language_provider.dart';
import '../providers/auth_provider.dart';
import 'language_toggle_button.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showLanguageToggle;
  final bool showRolePicker;

  const CustomAppBar({
    super.key,
    this.title,
    this.actions,
    this.showLanguageToggle = true,
    this.showRolePicker = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          Text(
            title ?? (lang.isMarathi ? 'शिवाजी पार्क हौसिंग सोसायटी' : 'Shivaji Park CHS Ltd'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (auth.currentUser != null)
            Text(
              '${lang.isMarathi ? auth.currentUser!.nameMr : auth.currentUser!.name} • ${auth.currentUser!.flatNumber.isNotEmpty ? auth.currentUser!.flatNumber : lang.tr('guard')}',
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85)),
            ),
        ],
      ),
      actions: [
        if (showLanguageToggle) const Padding(padding: EdgeInsets.only(right: 6), child: Center(child: LanguageToggleButton())),
        if (showRolePicker)
          PopupMenuButton<String>(
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            tooltip: lang.tr('switchRole'),
            onSelected: (role) => auth.switchRole(role),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'admin',
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(lang.tr('roleAdmin')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'member',
                child: Row(
                  children: [
                    const Icon(Icons.home, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(lang.tr('roleMember')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'guard',
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(lang.tr('roleGuard')),
                  ],
                ),
              ),
            ],
          ),
        if (actions != null) ...actions!,
      ],
    );
  }
}
