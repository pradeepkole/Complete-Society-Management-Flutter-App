import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/language_provider.dart';

class LanguageToggleButton extends StatelessWidget {
  final bool isDark;
  const LanguageToggleButton({super.key, this.isDark = true});

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isMarathi = langProvider.isMarathi;

    return InkWell(
      onTap: () => langProvider.toggleLanguage(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.18) : const Color(0xFF1E3A8A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF1E3A8A).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.translate,
              size: 15,
              color: isDark ? Colors.white : const Color(0xFF1E3A8A),
            ),
            const SizedBox(width: 5),
            Text(
              isMarathi ? 'मराठी / ENG' : 'ENG / मराठी',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
