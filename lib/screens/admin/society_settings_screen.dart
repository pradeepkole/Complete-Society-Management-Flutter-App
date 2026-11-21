import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/society_logo_widget.dart';

class SocietySettingsScreen extends StatefulWidget {
  const SocietySettingsScreen({super.key});

  @override
  State<SocietySettingsScreen> createState() => _SocietySettingsScreenState();
}

class _SocietySettingsScreenState extends State<SocietySettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameEnController;
  late TextEditingController _nameMrController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;
  late TextEditingController _upiIdController;
  late TextEditingController _upiMerchantController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNoController;
  late TextEditingController _ifscController;
  late TextEditingController _maintenanceAmountController;

  Uint8List? _newLogoBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  bool _allowMobileLogin = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final soc = auth.currentSociety;
    _allowMobileLogin = soc?.allowMobileLogin ?? false;

    _nameEnController = TextEditingController(text: soc?.name ?? '');
    _nameMrController = TextEditingController(text: soc?.nameMr ?? '');
    _addressController = TextEditingController(text: soc?.address ?? '');
    _cityController = TextEditingController(text: soc?.city ?? '');
    _pincodeController = TextEditingController(text: soc?.pincode ?? '');
    _upiIdController = TextEditingController(text: soc?.upiId ?? '');
    _upiMerchantController = TextEditingController(text: soc?.upiMerchantName ?? '');
    _bankNameController = TextEditingController(text: soc?.bankName ?? '');
    _accountNoController = TextEditingController(text: soc?.accountNo ?? '');
    _ifscController = TextEditingController(text: soc?.ifsc ?? '');
    _maintenanceAmountController = TextEditingController(text: soc?.defaultMaintenanceAmount.toStringAsFixed(0) ?? '2000');
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _newLogoBytes = bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking logo: $e')),
      );
    }
  }

  void _showLogoPickerSheet(bool isMr) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryNavy),
              title: Text(isMr ? 'गॅलरीतून लोगो निवडा' : 'Choose Logo from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickLogo(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryNavy),
              title: Text(isMr ? 'कॅमेऱ्याने फोटो काढा' : 'Take Photo with Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickLogo(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings(AuthProvider auth, bool isMr) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final success = await auth.updateSocietySettings(
      name: _nameEnController.text.trim(),
      nameMr: _nameMrController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      pincode: _pincodeController.text.trim(),
      upiId: _upiIdController.text.trim(),
      upiMerchantName: _upiMerchantController.text.trim(),
      bankName: _bankNameController.text.trim(),
      accountNo: _accountNoController.text.trim(),
      ifsc: _ifscController.text.trim(),
      defaultMaintenanceAmount: double.tryParse(_maintenanceAmountController.text) ?? 2000,
      newLogoBytes: _newLogoBytes,
      allowMobileLogin: _allowMobileLogin,
    );

    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isMr ? 'सोसायटी माहिती व सेटिंग्ज सेव्ह झाल्या!' : 'Settings updated successfully!'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Update failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final isMr = lang.isMarathi;
    final society = auth.currentSociety;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isMr ? 'सोसायटी सेटिंग्ज व माहिती' : 'Society Settings',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Society Code Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMr ? 'सोसायटी जॉइन कोड (Share with Members)' : 'Society Join Code',
                            style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            society?.societyCode ?? 'SOC-XXXXXX',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      tooltip: isMr ? 'WhatsApp वर पाठवा' : 'Share',
                      onPressed: () {
                        final msg = isMr
                            ? 'आपल्या ${society?.nameMr ?? society?.name} सोसायटीचे अधिकृत अ‍ॅप सुरू झाले आहे. जॉइन करण्यासाठी कोड: ${society?.societyCode}'
                            : 'Join our society app for ${society?.name}. Use Society Code: ${society?.societyCode}';
                        Share.share(msg);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logo Box
              Center(
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _showLogoPickerSheet(isMr),
                      borderRadius: BorderRadius.circular(50),
                      child: Stack(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEFF6FF),
                              border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                            ),
                            child: ClipOval(
                              child: _newLogoBytes != null
                                  ? Image.memory(_newLogoBytes!, fit: BoxFit.cover)
                                  : SocietyLogoWidget(
                                      logoUrl: society?.logoUrl,
                                      fallbackText: society?.name ?? 'S',
                                      size: 88,
                                      borderRadius: 44,
                                      backgroundColor: const Color(0xFF3B82F6),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E3A8A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isMr ? 'सोसायटीचा लोगो बदला (Change Logo)' : 'Change Society Logo',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic Info Section
              Text(
                isMr ? '१. सामान्य माहिती' : '1. General Information',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(height: 12),

              Text(isMr ? 'सोसायटीचे नाव (इंग्रजीत) *' : 'Society Name (English) *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _nameEnController,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              Text(isMr ? 'सोसायटीचे नाव (मराठीत)' : 'Society Name (Marathi)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _nameMrController,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              ),
              const SizedBox(height: 12),

              Text(isMr ? 'पत्ता *' : 'Address *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              // Financial & UPI Settings Section
              Text(
                isMr ? '२. देखभाल शुल्क व UPI पेमेंट सेटिंग्ज' : '2. Maintenance & UPI Settings',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              ),
              const SizedBox(height: 8),
              Text(
                isMr
                    ? 'येथे UPI ID टाकल्यास सर्व सभासदांच्या बिलांवर Dynamic UPI QR कोड आपोआप दिसेल.'
                    : 'Setting your Society UPI ID enables automated Dynamic UPI QR on member bills.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),

              Text(isMr ? 'सोसायटीचा अधिकृत UPI ID (उदा. society@sbi)' : 'Society Official UPI ID', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _upiIdController,
                decoration: InputDecoration(
                  hintText: 'mysociety@upi / sbi',
                  prefixIcon: const Icon(Icons.qr_code),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),

              Text(isMr ? 'UPI खात्याचे नाव (Merchant Name)' : 'UPI Payee / Merchant Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _upiMerchantController,
                decoration: InputDecoration(
                  hintText: 'Gokuldham CHS Maintenance',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),

              Text(isMr ? 'मासिक देखभाल शुल्क (प्रति फ्लॅट ₹)' : 'Default Monthly Maintenance (₹)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _maintenanceAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isMr ? 'बँकेचे नाव' : 'Bank Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _bankNameController,
                          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isMr ? 'IFSC कोड' : 'IFSC Code', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _ifscController,
                          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(isMr ? 'बँक खाते क्रमांक' : 'Bank Account Number', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _accountNoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              ),
              const SizedBox(height: 20),

              // Mobile Number Login Toggle (Admin Controlled)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SwitchListTile(
                  title: Text(
                    isMr ? 'मोबाईल नंबर बॅकअप लॉगिन' : 'Allow Mobile Number Login',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    isMr
                        ? 'चालू केल्यास सभासद मोबाईल नंबरनेही लॉगिन करू शकतील (बाय-डिफॉल्ट बंद)'
                        : 'Allow members to log in using their phone number as a backup',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  activeColor: AppTheme.primaryNavy,
                  value: _allowMobileLogin,
                  onChanged: (val) => setState(() => _allowMobileLogin = val),
                ),
              ),
              const SizedBox(height: 28),

              // Save Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSaving ? null : () => _saveSettings(auth, isMr),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isMr ? 'बदल सेव्ह करा ➔' : 'Save Settings ➔',
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
