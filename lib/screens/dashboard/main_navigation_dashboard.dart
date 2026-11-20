import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
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

class MainNavigationDashboard extends StatefulWidget {
  const MainNavigationDashboard({super.key});

  @override
  State<MainNavigationDashboard> createState() => _MainNavigationDashboardState();
}

class _MainNavigationDashboardState extends State<MainNavigationDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isAuthenticated) {
      return const LoginScreen();
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

    // Guard against index out of range when switching role
    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      appBar: CustomAppBar(
        showLanguageToggle: true,
        showRolePicker: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
            tooltip: lang.tr('logout'),
            onPressed: () => auth.logout(),
          ),
        ],
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
