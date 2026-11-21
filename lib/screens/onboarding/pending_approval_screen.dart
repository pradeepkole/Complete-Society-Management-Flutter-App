import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../dashboard/main_navigation_dashboard.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus(AuthProvider auth) async {
    setState(() => _isChecking = true);
    await auth.refreshProfile();
    setState(() => _isChecking = false);

    if (auth.isAuthenticated && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationDashboard()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final isMr = lang.isMarathi;
    final user = auth.currentUser;
    final society = auth.currentSociety;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isMr ? 'मंजुरी प्रलंबित' : 'Approval Pending',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: isMr ? 'साइन आऊट' : 'Sign Out',
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pending Clock Icon
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 48,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                isMr ? 'अ‍ॅडमिन मंजुरीची प्रतीक्षा आहे' : 'Awaiting Admin Approval',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                isMr
                    ? 'आपली विनंती सोसायटीच्या सचिवांकडे मंजुरीसाठी पाठवण्यात आली आहे. त्यांनी मंजूर करताच आपला डॅशबोर्ड आपोआप सुरू होईल.'
                    : 'Your membership request has been sent to the Society Secretary. Once approved, your dashboard will activate automatically.',
                style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      isMr ? 'सोसायटी' : 'Society',
                      society?.nameMr.isNotEmpty == true ? society!.nameMr : (society?.name ?? 'Society'),
                    ),
                    const Divider(height: 16),
                    _buildInfoRow(
                      isMr ? 'सोसायटी कोड' : 'Society Code',
                      user?.societyCode ?? society?.societyCode ?? '-',
                    ),
                    const Divider(height: 16),
                    _buildInfoRow(
                      isMr ? 'नाव' : 'Name',
                      user?.name ?? '-',
                    ),
                    if (user?.isMember == true) ...[
                      const Divider(height: 16),
                      _buildInfoRow(
                        isMr ? 'फ्लॅट क्रमांक' : 'Flat Number',
                        '${user?.wing.isNotEmpty == true ? "Wing ${user!.wing} - " : ""}${user?.flatNumber ?? "-"}',
                      ),
                    ],
                    const Divider(height: 16),
                    _buildInfoRow(
                      isMr ? 'भूमिका' : 'Role',
                      user?.isGuard == true
                          ? (isMr ? 'सुरक्षा रक्षक' : 'Security Guard')
                          : (isMr ? 'फ्लॅट सभासद' : 'Flat Member'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Check Status Button
              ElevatedButton.icon(
                icon: _isChecking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(
                  isMr ? 'स्थिती तपासा (Refresh)' : 'Check Approval Status',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isChecking ? null : () => _checkStatus(auth),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    );
  }
}
