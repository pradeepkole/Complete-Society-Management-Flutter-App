import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'l10n/language_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/billing_provider.dart';
import 'providers/accounting_provider.dart';
import 'providers/notice_provider.dart';
import 'providers/complaint_provider.dart';
import 'providers/visitor_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/society_choice_screen.dart';
import 'screens/onboarding/pending_approval_screen.dart';
import 'screens/dashboard/main_navigation_dashboard.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }

  runApp(const SocietyGateApp());
}

class SocietyGateApp extends StatelessWidget {
  const SocietyGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BillingProvider()),
        ChangeNotifierProvider(create: (_) => AccountingProvider()),
        ChangeNotifierProvider(create: (_) => NoticeProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintProvider()),
        ChangeNotifierProvider(create: (_) => VisitorProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, langProvider, _) {
          return MaterialApp(
            title: 'SocietyGate (गृहनिर्माण संस्था)',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: langProvider.locale,
            home: const AppRootGate(),
          );
        },
      ),
    );
  }
}

class AppRootGate extends StatelessWidget {
  const AppRootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    switch (auth.status) {
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticating:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      case AuthStatus.needsOnboarding:
        return const SocietyChoiceScreen();
      case AuthStatus.pendingApproval:
        return const PendingApprovalScreen();
      case AuthStatus.authenticated:
        return const MainNavigationDashboard();
    }
  }
}
