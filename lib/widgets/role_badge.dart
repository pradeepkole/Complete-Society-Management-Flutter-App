import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/language_provider.dart';

class RoleBadge extends StatelessWidget {
  final String role; // 'admin', 'member', 'guard'

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (role) {
      case 'admin':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1E40AF);
        label = lang.tr('admin');
        icon = Icons.admin_panel_settings;
        break;
      case 'guard':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = lang.tr('guard');
        icon = Icons.security;
        break;
      case 'member':
      default:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF047857);
        label = lang.tr('member');
        icon = Icons.home;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
