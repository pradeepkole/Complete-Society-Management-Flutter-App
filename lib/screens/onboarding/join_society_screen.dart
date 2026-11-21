import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import 'pending_approval_screen.dart';

class JoinSocietyScreen extends StatefulWidget {
  const JoinSocietyScreen({super.key});

  @override
  State<JoinSocietyScreen> createState() => _JoinSocietyScreenState();
}

class _JoinSocietyScreenState extends State<JoinSocietyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _flatController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = 'member'; // 'member' or 'guard'
  String _selectedWing = 'A';
  String _residentType = 'owner'; // 'owner' or 'tenant'
  bool _isSubmitting = false;

  Future<void> _submitJoin(AuthProvider auth, bool isMr) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    String code = _codeController.text.trim().toUpperCase();
    if (!code.startsWith('SOC-') && code.length == 6) {
      code = 'SOC-$code';
    }

    final success = await auth.joinSocietyWithCode(
      societyCode: code,
      role: _selectedRole,
      wing: _selectedRole == 'member' ? _selectedWing : '',
      flatNumber: _selectedRole == 'member' ? _flatController.text.trim() : '',
      phoneNumber: _phoneController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? (isMr ? 'सोसायटी कोड सापडला नाही!' : 'Invalid Society Code!')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final isMr = lang.isMarathi;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isMr ? 'सोसायटीत सामील व्हा' : 'Join Society',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.vpn_key_rounded, color: Color(0xFF1E3A8A), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isMr
                            ? 'आपल्या सोसायटी सचिवांनी दिलेला ६-अंकी कोड टाकून विनंती पाठवा.'
                            : 'Enter the 6-digit Society Code provided by your Secretary.',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF1E40AF)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Society Code Field
              Text(
                isMr ? 'सोसायटी कोड (Society Code) *' : 'Society Code *',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'उदा. SOC-849201 किंवा 849201',
                  prefixIcon: const Icon(Icons.tag),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? (isMr ? 'सोसायटी कोड आवश्यक आहे' : 'Society code is required')
                    : null,
              ),
              const SizedBox(height: 20),

              // Role Selection (Member or Guard)
              Text(
                isMr ? 'आपली भूमिका निवडा (Role) *' : 'Select Your Role *',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedRole = 'member'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedRole == 'member' ? const Color(0xFF1E3A8A) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedRole == 'member' ? const Color(0xFF1E3A8A) : const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.home,
                              color: _selectedRole == 'member' ? Colors.white : const Color(0xFF64748B),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isMr ? 'फ्लॅट सभासद' : 'Flat Member',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _selectedRole == 'member' ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedRole = 'guard'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedRole == 'guard' ? const Color(0xFF1E3A8A) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedRole == 'guard' ? const Color(0xFF1E3A8A) : const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.security,
                              color: _selectedRole == 'guard' ? Colors.white : const Color(0xFF64748B),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isMr ? 'सुरक्षा रक्षक' : 'Security Guard',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _selectedRole == 'guard' ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // If Member: Wing & Flat Number
              if (_selectedRole == 'member') ...[
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isMr ? 'विंग (Wing)' : 'Wing', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedWing,
                            items: ['A', 'B', 'C', 'D', 'E'].map((w) {
                              return DropdownMenuItem(value: w, child: Text('Wing $w'));
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedWing = val ?? 'A'),
                            decoration: OutlineInputBorder(borderRadius: BorderRadius.circular(10)).copyWith(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isMr ? 'फ्लॅट क्रमांक *' : 'Flat Number *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _flatController,
                            decoration: InputDecoration(
                              hintText: 'उदा. 101, 202',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty
                                ? (isMr ? 'फ्लॅट क्रमांक आवश्यक' : 'Flat required')
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Resident Type: Owner / Tenant
                Text(isMr ? 'रहिवासी प्रकार (Resident Type)' : 'Resident Type', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Radio<String>(
                      value: 'owner',
                      groupValue: _residentType,
                      onChanged: (val) => setState(() => _residentType = val!),
                    ),
                    Text(isMr ? 'फ्लॅट मालक (Owner)' : 'Flat Owner'),
                    const SizedBox(width: 20),
                    Radio<String>(
                      value: 'tenant',
                      groupValue: _residentType,
                      onChanged: (val) => setState(() => _residentType = val!),
                    ),
                    Text(isMr ? 'भाडेकरू (Tenant)' : 'Tenant'),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Mobile Number (Optional)
              Text(
                isMr ? 'मोबाईल नंबर (ऐच्छिक - Notifications साठी)' : 'Mobile Number (Optional)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '+91 98XXXXXXXX',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : () => _submitJoin(auth, isMr),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isMr ? 'सामील होण्याची विनंती पाठवा ➔' : 'Submit Join Request ➔',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
