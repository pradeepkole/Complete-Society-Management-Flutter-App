import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/language_toggle_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isGoogleLoading = false;

  Future<void> _handleGoogleSignIn(AuthProvider auth, bool isMr) async {
    setState(() => _isGoogleLoading = true);
    final success = await auth.signInWithGoogle();
    if (mounted) {
      setState(() => _isGoogleLoading = false);
      if (!success) {
        _showGoogleAuthNoticeDialog(auth, isMr);
      }
    }
  }

  void _showGoogleAuthNoticeDialog(AuthProvider auth, bool isMr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF1E3A8A)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isMr ? 'Google साइन-इन माहिती' : 'Google Sign-In Notice',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMr
                  ? 'Android ॲपवर थेट Google ने साइन इन करण्यासाठी Firebase Console मध्ये खालील SHA-1 फिंगरप्रिंट जोडणे आवश्यक असते:'
                  : 'To enable Google Sign-In on Android, add this SHA-1 fingerprint in Firebase Console:',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: SelectableText(
                '76:4B:AD:25:DE:1F:B3:96:B6:30:25:3F:88:C1:E2:28:AF:30:6F:92',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Color(0xFF1E293B)),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isMr
                  ? 'तोपर्यंत आपण आत्ता लगेच खालील बटण दाबून थेट नवीन सोसायटी नोंदणी, लोगो जोडणे व सर्व फीचर्स वापरून पाहू शकता!'
                  : 'Meanwhile, you can tap below to test Society Onboarding, Logo Upload, and all features right now!',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isMr ? 'रद्द करा' : 'Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.rocket_launch, size: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              auth.signInForOnboardingTesting();
            },
            child: Text(isMr ? 'थेट चाचणी सुरू करा' : 'Continue in Test Mode'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isMr = lang.isMarathi;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Bar with Language Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_done, size: 14, color: Color(0xFF1E3A8A)),
                        const SizedBox(width: 4),
                        Text(
                          isMr ? 'क्लाउड सिस्टीम' : 'Live Cloud',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                  ),
                  const LanguageToggleButton(isDark: false),
                ],
              ),
              const SizedBox(height: 36),

              // App Logo & Branding
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  size: 52,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                isMr ? 'सोसायटी गेट' : 'Society Gate',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E3A8A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isMr ? 'गृहनिर्माण संस्था व्यवस्थापन प्रणाली' : 'Housing Society Management System',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 36),

              // Feature Highlights Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      icon: Icons.qr_code_2,
                      text: isMr ? 'NPCI Dynamic UPI QR व त्वरित पावती' : 'Dynamic UPI QR & instant receipts',
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureItem(
                      icon: Icons.account_balance_wallet,
                      text: isMr ? 'पारदर्शक ताळेबंद व व्हाउचर अपलोड' : 'Transparent ledger & voucher uploads',
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureItem(
                      icon: Icons.security,
                      text: isMr ? 'गेट व्हिजिटर नोंदवही व सुरक्षा' : 'Gate visitor register & security',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // PRIMARY 1-CLICK GOOGLE SIGN IN BUTTON
              InkWell(
                onTap: _isGoogleLoading ? null : () => _handleGoogleSignIn(auth, isMr),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isGoogleLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google 'G' Icon colored
                            Image.network(
                              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                              width: 24,
                              height: 24,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.g_mobiledata,
                                size: 32,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              isMr ? 'Google ने साइन इन करा' : 'Sign in with Google',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isMr
                    ? '🔒 सुरक्षित व १-क्लिक लॉगिन • मोबाईल नंबर ऐच्छिक'
                    : '🔒 Fast 1-click login • Mobile number is optional',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),

              // DIRECT ONBOARDING TEST BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.apartment_rounded, color: Colors.white, size: 20),
                  label: Text(
                    isMr ? '🚀 नवीन ऑनबोर्डिंग व लोगो चाचणी' : '🚀 Test Onboarding & Logo',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                  onPressed: () => auth.signInForOnboardingTesting(),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isMr
                    ? 'सोसायटी नाव, पत्ता, विंग्स व लोगो अपलोडची थेट चाचणी घ्या'
                    : 'Test society creation, address, wings & logo upload live',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 28),

              // OR Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      isMr ? 'किंवा सराव / चाचणी मोड' : 'Or Trial / Demo Mode',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),

              // Quick Demo Exploration Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.admin_panel_settings, size: 16),
                      label: Text(isMr ? 'सचिव डेमो' : 'Admin Demo', style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: Color(0xFF94A3B8)),
                      ),
                      onPressed: () => auth.signInAsDemoUser(role: 'admin'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person, size: 16),
                      label: Text(isMr ? 'सभासद डेमो' : 'Member Demo', style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: Color(0xFF94A3B8)),
                      ),
                      onPressed: () => auth.signInAsDemoUser(role: 'member'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF1E3A8A)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
