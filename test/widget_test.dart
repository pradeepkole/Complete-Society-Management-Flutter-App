import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:society_gate/l10n/language_provider.dart';
import 'package:society_gate/widgets/language_toggle_button.dart';
import 'package:society_gate/widgets/role_badge.dart';

void main() {
  testWidgets('LanguageToggleButton toggles between Marathi and English', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: const MaterialApp(
          home: Scaffold(
            body: LanguageToggleButton(isDark: false),
          ),
        ),
      ),
    );

    // Initial language is Marathi ('mr')
    expect(find.text('मराठी / ENG'), findsOneWidget);

    // Tap toggle button
    await tester.tap(find.byType(LanguageToggleButton));
    await tester.pumpAndSettle();

    // Now should be English ('en')
    expect(find.text('ENG / मराठी'), findsOneWidget);
  });

  testWidgets('RoleBadge displays appropriate badge for Admin, Member, Guard', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RoleBadge(role: 'admin'),
                RoleBadge(role: 'member'),
                RoleBadge(role: 'guard'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.admin_panel_settings), findsOneWidget);
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.security), findsOneWidget);
  });
}
