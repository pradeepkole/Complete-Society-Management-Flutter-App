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
  // Method: 'email' or 'phone'
  String _authMethod = 'email';

  // Email controllers
  final _emailController = TextEditingController(text: 'rajesh.deshmukh@gmail.com');
  final _passwordController = TextEditingController(text: 'Password@123');
  final _nameController = TextEditingController();
  final _flatController = TextEditingController(text: 'A-402');
  final _wingController = TextEditingController(text: 'A');

  // Phone controllers
  final _phoneController = TextEditingController(text: '+91 98203 34455');
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  String _verificationId = '';

  bool _isSignUp = false;
  bool _obscurePassword = true;
  String _selectedRole = 'member'; // 'admin', 'member', 'guard'

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAlignment.start,
            children: [
              // Header Language Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const LanguageToggleButton(isDark: false),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Live Firebase: society-6ad99',
                      style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Society Emblem / App Title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryNavy,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryNavy.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.apartment, color: Colors.white, size: 38),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lang.tr('appName'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lang.isMarathi
                          ? 'शिवाजी पार्क सहकारी गृहनिर्माण संस्था'
                          : 'Shivaji Park Co-op Housing Society Ltd.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Error Banner
              if (auth.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: TextStyle(color: Colors.red.shade900, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Auth Method Segment (Email vs Mobile OTP)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _buildMethodTab('email', 'Email & Password', Icons.email),
                    _buildMethodTab('phone', 'Mobile Phone OTP', Icons.phone_android),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Role Selector Tabs
              Text(
                '${lang.tr('selectLanguage') == 'भाषा निवडा' ? 'आपली भूमिका निवडा' : 'Select Your Role'}:',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),

              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _buildRoleTab('member', lang.tr('member'), Icons.home),
                    _buildRoleTab('admin', lang.tr('admin'), Icons.admin_panel_settings),
                    _buildRoleTab('guard', lang.tr('guard'), Icons.security),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // =================== EMAIL FLOW ===================
              if (_authMethod == 'email') ...[
                if (_isSignUp) ...[
                  Text(
                    lang.isMarathi ? 'पूर्ण नाव' : 'Full Name',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person, size: 20),
                      hintText: lang.isMarathi ? 'उदा. राजेश देशमुख' : 'e.g. Rajesh Deshmukh',
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAlignment.start,
                          children: [
                            Text(lang.tr('wing'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(controller: _wingController, decoration: const InputDecoration(hintText: 'A')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAlignment.start,
                          children: [
                            Text(lang.tr('flat'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(controller: _flatController, decoration: const InputDecoration(hintText: 'A-402')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                Text(
                  lang.isMarathi ? 'ईमेल पत्ता' : 'Email Address',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email, size: 20),
                    hintText: 'user@example.com',
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  lang.isMarathi ? 'पासवर्ड' : 'Password',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock, size: 20),
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),

                if (!_isSignUp) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showForgotPasswordDialog(context, auth, lang),
                      child: Text(
                        lang.isMarathi ? 'पासवर्ड विसरलात?' : 'Forgot Password?',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ] else
                  const SizedBox(height: 16),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            if (_isSignUp) {
                              await auth.registerWithEmailPassword(
                                email: _emailController.text,
                                password: _passwordController.text,
                                name: _nameController.text.isNotEmpty ? _nameController.text : 'Member',
                                role: _selectedRole,
                                flatNumber: _flatController.text,
                                wing: _wingController.text,
                              );
                            } else {
                              await auth.signInWithEmailPassword(
                                email: _emailController.text,
                                password: _passwordController.text,
                              );
                            }
                          },
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isSignUp ? (lang.isMarathi ? 'नोंदणी करा (Sign Up)' : 'Sign Up') : lang.tr('login'),
                          ),
                  ),
                ),

                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? (lang.isMarathi ? 'आधीच खाते आहे? लॉगिन करा' : 'Already have an account? Sign In')
                          : (lang.isMarathi ? 'नवीन खाते तयार करा (Sign Up)' : "Don't have an account? Sign Up"),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ]

              // =================== PHONE OTP FLOW ===================
              else ...[
                Text(
                  lang.isMarathi ? 'मोबाईल नंबर (E.164)' : 'Mobile Phone Number',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone, size: 20),
                    hintText: '+91 98200 12345',
                    suffixIcon: TextButton(
                      onPressed: auth.isLoading
                          ? null
                          : () {
                              auth.sendPhoneOtp(
                                phoneNumber: _phoneController.text,
                                onCodeSent: (vId) {
                                  setState(() {
                                    _verificationId = vId;
                                    _isOtpSent = true;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('OTP sent to phone via SMS!')),
                                  );
                                },
                                onError: (err) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(err), backgroundColor: Colors.red),
                                  );
                                },
                              );
                            },
                      child: Text(
                        _isOtpSent ? (lang.isMarathi ? 'पुन्हा पाठवा' : 'Resend') : (lang.isMarathi ? 'OTP पाठवा' : 'Send OTP'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                if (_isOtpSent) ...[
                  Text(
                    lang.isMarathi ? 'एसएमएस द्वारे आलेला ओटीपी (6-Digit OTP)' : 'Enter 6-Digit SMS OTP',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.sms, size: 20),
                      hintText: '123456',
                    ),
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              await auth.verifyPhoneOtpAndSignIn(
                                verificationId: _verificationId,
                                smsCode: _otpController.text,
                                role: _selectedRole,
                              );
                            },
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(lang.tr('login')),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 16),

              // Quick Demo One-Click Access
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bolt, size: 16, color: Colors.amber.shade900),
                        const SizedBox(width: 6),
                        Text(
                          lang.isMarathi ? 'चाचणीसाठी एका क्लिकवर थेट प्रवेश:' : 'Quick Demo One-Click Access:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _demoButton('Admin (सचिव)', 'admin', Colors.blue, 'secretary.shivaji@chs.in'),
                        _demoButton('Member (A-402)', 'member', Colors.green, 'rajesh.deshmukh@gmail.com'),
                        _demoButton('Guard (गेट)', 'guard', Colors.orange, 'security.gate@chs.in'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodTab(String method, String label, IconData icon) {
    final isSelected = _authMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _authMethod = method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSelected ? AppTheme.primaryNavy : Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryNavy : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? AppTheme.primaryNavy : Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryNavy : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _demoButton(String label, String role, Color color, String email) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return InkWell(
      onTap: () {
        setState(() {
          _authMethod = 'email';
          _emailController.text = email;
          _selectedRole = role;
        });
        auth.switchRole(role);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context, AuthProvider auth, LanguageProvider lang) {
    final resetController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.isMarathi ? 'पासवर्ड रीसेट करा' : 'Reset Password', style: const TextStyle(fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang.isMarathi
                  ? 'आपला ईमेल प्रविष्ट करा. आम्ही पासवर्ड रीसेट लिंक पाठवू.'
                  : 'Enter your email address to receive a password reset link.',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(controller: resetController, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.tr('cancel'))),
          ElevatedButton(
            onPressed: () async {
              await auth.sendPasswordReset(resetController.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset email sent! Check your inbox.')),
                );
              }
            },
            child: Text(lang.tr('submit')),
          ),
        ],
      ),
    );
  }
}
