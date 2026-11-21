import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/billing_provider.dart';
import '../../providers/accounting_provider.dart';
import '../../providers/notice_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/visitor_provider.dart';
import '../../l10n/language_provider.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    final societyId = auth.currentSociety?.id;
    if (societyId != null && societyId.isNotEmpty) {
      Provider.of<BillingProvider>(context, listen: false).setSocietyId(societyId);
      Provider.of<AccountingProvider>(context, listen: false).setSocietyId(societyId);
      Provider.of<NoticeProvider>(context, listen: false).setSocietyId(societyId);
      Provider.of<ComplaintProvider>(context, listen: false).setSocietyId(societyId);
      Provider.of<VisitorProvider>(context, listen: false).setSocietyId(societyId);
    }
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
