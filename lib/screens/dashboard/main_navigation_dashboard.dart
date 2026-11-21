import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/billing_provider.dart';
import '../../providers/accounting_provider.dart';
import '../../providers/notice_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/visitor_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_app_bar.dart';
import 'admin_dashboard_tab.dart';
import 'member_dashboard_tab.dart';
import 'guard_dashboard_tab.dart';
import '../billing/billing_management_screen.dart';
import '../billing/member_bills_screen.dart';
import '../accounting/balance_sheet_screen.dart';
import '../accounting/member_transparency_screen.dart';
import '../notices/notice_board_screen.dart';
import '../complaints/complaints_screen.dart';
import '../visitors/visitor_log_screen.dart';
import '../auth/login_screen.dart';
import '../onboarding/society_choice_screen.dart';
import '../onboarding/pending_approval_screen.dart';

class MainNavigationDashboard extends StatefulWidget {
  const MainNavigationDashboard({super.key});

  @override
  State<MainNavigationDashboard> createState() => _MainNavigationDashboardState();
}

class _MainNavigationDashboardState extends State<MainNavigationDashboard> {
  int _currentIndex = 0;
  bool _hasCheckedSubscription = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final societyId = auth.currentSociety?.id;
    if (societyId != null && societyId.isNotEmpty) {
      Provider.of<BillingProvider>(context, listen: false).setSocietyId(societyId);
      Provider.of<AccountingProvider>(context, listen: false).setSocietyId(societyId);
      Provider.of<NoticeProvider>(context, listen: false).setSocietyId(societyId);
      Provider.of<ComplaintProvider>(context, listen: false).setSocietyId(societyId);
      Provider.of<VisitorProvider>(context, listen: false).setSocietyId(societyId);

      _checkSubscriptionGuard(auth, lang);
    }
  }

  void _checkSubscriptionGuard(AuthProvider auth, LanguageProvider lang) {
    if (_hasCheckedSubscription) return;
    _hasCheckedSubscription = true;

    final society = auth.currentSociety;
    if (society == null) return;
    final isMr = lang.isMarathi;

    // SoftAdmin is never blocked from using the app
    if (auth.isSoftAdmin) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // 1. Subscription OFF (Disabled by Admin)
      if (society.isSubscriptionDisabled) {
        _showBlockingExitDialog(
          context: context,
          isMr: isMr,
          title: isMr ? '🚫 संपर्क करा: ॲडमिन' : '🚫 Contact Admin',
          message: isMr
              ? 'आपल्या संस्थेचे ॲप सबस्क्रिप्शन प्रशासकाकडून बंद (Disabled) करण्यात आले आहे. कृपया चालू करण्यासाठी ॲडमिनशी संपर्क साधा.\n\n📞 संपर्क: 9822681814'
              : 'App subscription has been disabled by admin. Please contact admin to activate.\n\n📞 Contact: 9822681814',
        );
        return;
      }

      // 2. Subscription Expired
      if (society.isSubscriptionExpired) {
        _showBlockingExitDialog(
          context: context,
          isMr: isMr,
          title: isMr ? '⏳ सबस्क्रिप्शन मुदत संपली!' : '⏳ Subscription Expired!',
          message: isMr
              ? 'आपल्या संस्थेचा सबस्क्रिप्शन कालावधी संपुष्टात आला आहे. ॲप सेवा पूर्ववत सुरू करण्यासाठी कृपया सबस्क्रिप्शन रिन्यू (Renew) करा.\n\n📞 रिन्यूअलसाठी संपर्क: 9822681814'
              : 'Society subscription has expired. Please renew subscription to continue.\n\n📞 Renewal Contact: 9822681814',
        );
        return;
      }

      // 3. Pro Warning (<= 45 days remaining)
      if (society.isPro && society.remainingSubscriptionDays <= 45 && society.remainingSubscriptionDays > 0) {
        _showProceedWarningDialog(
          context: context,
          isMr: isMr,
          title: isMr ? '⚠️ सबस्क्रिप्शन रिन्यूअल सूचना (Pro)' : '⚠️ Pro Renewal Notice',
          message: isMr
              ? 'आपल्या संस्थेचे Pro सबस्क्रिप्शन लवकरच समाप्त होणार आहे.\n\n📅 शेवटची तारीख: ${AppDateFormatter.formatDate(society.effectiveExpiryDate, isMarathi: isMr)}\n⏳ शिल्लक दिवस: ${society.remainingSubscriptionDays} दिवस\n\nकृपया मुदत संपण्यापूर्वी रिन्यूअल करून घ्या.\n📞 संपर्क: 9822681814'
              : 'Pro subscription will expire soon.\n\n📅 Expiry Date: ${AppDateFormatter.formatDate(society.effectiveExpiryDate, isMarathi: isMr)}\n⏳ Remaining: ${society.remainingSubscriptionDays} days\n\n📞 Contact: 9822681814',
        );
        return;
      }

      // 4. Demo Warning (<= 15 days remaining)
      if (!society.isPro && society.remainingSubscriptionDays <= 15 && society.remainingSubscriptionDays > 0) {
        _showProceedWarningDialog(
          context: context,
          isMr: isMr,
          title: isMr ? '⚠️ डेमो कालावधी समाप्ती सूचना' : '⚠️ Demo Expiry Notice',
          message: isMr
              ? 'आपल्या संस्थेचा डेमो कालावधी लवकरच समाप्त होणार आहे.\n\n📅 शेवटची तारीख: ${AppDateFormatter.formatDate(society.effectiveExpiryDate, isMarathi: isMr)}\n⏳ शिल्लक दिवस: ${society.remainingSubscriptionDays} दिवस\n\nसर्व वैशिष्ट्ये अखंडित चालू ठेवण्यासाठी कृपया १ वर्ष Pro सबस्क्रिप्शनमध्ये अपग्रेड करा.\n📞 संपर्क: 9822681814'
              : 'Demo period will expire soon.\n\n📅 Expiry Date: ${AppDateFormatter.formatDate(society.effectiveExpiryDate, isMarathi: isMr)}\n⏳ Remaining: ${society.remainingSubscriptionDays} days\n\n📞 Contact: 9822681814',
        );
        return;
      }
    });
  }

  void _showBlockingExitDialog({
    required BuildContext context,
    required bool isMr,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold))),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 13, height: 1.4)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => SystemNavigator.pop(),
              child: Text(isMr ? 'ठीक आहे (बाहेर पडा)' : 'OK (Exit App)'),
            ),
          ],
        ),
      ),
    );
  }

  void _showProceedWarningDialog({
    required BuildContext context,
    required bool isMr,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 13, height: 1.4)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: Text(isMr ? 'समजले (पुढे जा)' : 'OK (Proceed)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    // Route dynamically based on AuthStatus
    if (auth.status == AuthStatus.unauthenticated || auth.currentUser == null) {
      return const LoginScreen();
    }

    if (auth.needsOnboarding) {
      return const SocietyChoiceScreen();
    }

    if (auth.isPendingApproval) {
      return const PendingApprovalScreen();
    }

    // Role-dependent tab pages and nav items
    List<Widget> pages = [];
    List<NavigationDestination> navItems = [];

    if (auth.isAdmin) {
      pages = [
        const AdminDashboardTab(),
        const BillingManagementScreen(),
        const BalanceSheetScreen(),
        const NoticeBoardScreen(),
        const ComplaintsScreen(),
      ];
      navItems = [
        NavigationDestination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard),
          label: lang.tr('dashboard'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long),
          label: lang.tr('maintenanceBilling'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: const Icon(Icons.account_balance_wallet),
          label: lang.tr('societyAccounting'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.campaign_outlined),
          selectedIcon: const Icon(Icons.campaign),
          label: lang.tr('noticeBoard'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.support_agent_outlined),
          selectedIcon: const Icon(Icons.support_agent),
          label: lang.tr('complaintsHelpdesk'),
        ),
      ];
    } else if (auth.isGuard) {
      pages = [
        const GuardDashboardTab(),
        const VisitorLogScreen(),
        const NoticeBoardScreen(),
      ];
      navItems = [
        NavigationDestination(
          icon: const Icon(Icons.security_outlined),
          selectedIcon: const Icon(Icons.security),
          label: lang.tr('dashboard'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.badge_outlined),
          selectedIcon: const Icon(Icons.badge),
          label: lang.tr('visitorEntry'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.campaign_outlined),
          selectedIcon: const Icon(Icons.campaign),
          label: lang.tr('noticeBoard'),
        ),
      ];
    } else {
      // Flat Member
      pages = [
        const MemberDashboardTab(),
        const MemberBillsScreen(),
        const MemberTransparencyScreen(),
        const NoticeBoardScreen(),
        const ComplaintsScreen(),
      ];
      navItems = [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: lang.tr('dashboard'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.qr_code_2),
          selectedIcon: const Icon(Icons.qr_code),
          label: lang.tr('monthlyBills'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.pie_chart_outline),
          selectedIcon: const Icon(Icons.pie_chart),
          label: lang.tr('transparencyDashboard'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.campaign_outlined),
          selectedIcon: const Icon(Icons.campaign),
          label: lang.tr('noticeBoard'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.support_agent_outlined),
          selectedIcon: const Icon(Icons.support_agent),
          label: lang.tr('complaintsHelpdesk'),
        ),
      ];
    }

    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      appBar: const CustomAppBar(
        showLanguageToggle: true,
        showSettings: true,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: navItems,
      ),
    );
  }
}
