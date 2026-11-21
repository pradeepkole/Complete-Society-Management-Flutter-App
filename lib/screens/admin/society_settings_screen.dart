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
import '../../services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String _groupingType = 'wing';
  int _superAdminTermMonths = 3;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final soc = auth.currentSociety;
    _allowMobileLogin = soc?.allowMobileLogin ?? false;
    _groupingType = soc?.groupingType ?? 'wing';
    _superAdminTermMonths = soc?.superAdminTermMonths ?? 3;

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

  Future<void> _handleGroupingTypeChange(String newType, bool isMr) async {
    if (newType == _groupingType) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final soc = auth.currentSociety;
    if (soc == null) return;

    // STRICT RULE: If any dues remain pending, cannot change grouping structure!
    final hasDues = await FirestoreService.instance.hasPendingSocietyDues(soc.id);
    if (hasDues) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMr ? '⚠️ थकबाकी शिल्लक आहे!' : 'Outstanding Dues Pending!',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
              ],
            ),
            content: Text(
              isMr
                  ? 'संस्थेतील सर्व मेंटेनन्स देयके (Dues) १००% पूर्ण भरल्याशिवाय व्यवस्थापन गट पद्धत (विंग/मजला) बदलता येणार नाही. कृपया आधी सर्व थकीत बिले वसूल करा.'
                  : 'Management grouping structure (Wing/Floor) cannot be changed while there are unpaid maintenance bills. Please collect all dues first.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isMr ? 'समजले' : 'OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() => _groupingType = newType);
  }

  void _showExtendTenureDialog(AuthProvider auth, bool isMr) {
    int additionalMonths = 3;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isMr ? 'सुपर ॲडमिन कार्यकाळ वाढवा' : 'Extend Super Admin Tenure'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMr ? 'चालू सुपर ॲडमिनची मुदत किती कालावधीने वाढवायची आहे?' : 'Extend current Super Admin term by:',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: additionalMonths,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: [
                  DropdownMenuItem(value: 1, child: Text(isMr ? '१ महिना (1 Month)' : '1 Month')),
                  DropdownMenuItem(value: 3, child: Text(isMr ? '३ महिने (3 Months)' : '3 Months')),
                  DropdownMenuItem(value: 6, child: Text(isMr ? '६ महिने (6 Months)' : '6 Months')),
                  DropdownMenuItem(value: 12, child: Text(isMr ? '१ वर्ष (12 Months)' : '1 Year (12 Months)')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => additionalMonths = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isMr ? 'रद्द करा' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await auth.extendSuperAdminTerm(additionalMonths);
                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(isMr ? 'कार्यकाळ यशस्वीरीत्या वाढवण्यात आला!' : 'Tenure extended successfully!'),
                    ),
                  );
                }
              },
              child: Text(isMr ? 'मुदत वाढवा' : 'Extend Term'),
            ),
          ],
        ),
      ),
    );
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
      groupingType: _groupingType,
      superAdminTermMonths: _superAdminTermMonths,
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

              // ==========================================
              // 1. MANAGEMENT GROUPING STRUCTURE & TENURE
              // ==========================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.hub_outlined, color: Color(0xFF1E3A8A)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isMr ? '१. व्यवस्थापन गट रचना (Grouping Structure)' : '1. Management Grouping Structure',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isMr
                          ? 'संस्थेत मेंटेनन्स वसुली व प्रतिनिधी विंगनुसार करायचे की मजल्यानुसार हे ठरवा.'
                          : 'Choose whether maintenance & admins are organised Wing-wise or Floor-wise.',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: Text(
                              isMr ? 'विंग पद्धत (Wing-wise) - उदा. A, B विंग्स' : 'Wing-wise (e.g. Wing A, B)',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              isMr ? 'प्रत्येक विंगसाठी स्वतंत्र संकलन ॲडमिन' : 'Dedicated Group Admin per wing',
                              style: const TextStyle(fontSize: 11),
                            ),
                            value: 'wing',
                            groupValue: _groupingType,
                            activeColor: const Color(0xFF1E3A8A),
                            onChanged: (val) {
                              if (val != null) _handleGroupingTypeChange(val, isMr);
                            },
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            title: Text(
                              isMr ? 'मजला पद्धत (Floor-wise) - उदा. १ ला, २ रा मजला' : 'Floor-wise (e.g. 1st, 2nd Floor)',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              isMr ? 'प्रत्येक मजल्यासाठी स्वतंत्र संकलन ॲडमिन' : 'Dedicated Group Admin per floor',
                              style: const TextStyle(fontSize: 11),
                            ),
                            value: 'floor',
                            groupValue: _groupingType,
                            activeColor: const Color(0xFF1E3A8A),
                            onChanged: (val) {
                              if (val != null) _handleGroupingTypeChange(val, isMr);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Super Admin Tenure
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isMr ? 'सुपर ॲडमिन (सचिव) कार्यकाळ' : 'Super Admin Tenure',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.timer_outlined, size: 16),
                          label: Text(isMr ? 'मुदत वाढवा' : 'Extend Term', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _showExtendTenureDialog(auth, isMr),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      value: _superAdminTermMonths,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        helperText: isMr ? 'मुदत संपत आल्यावर कमिटीला सूचना येईल' : 'App alerts committee near term completion',
                      ),
                      items: [
                        DropdownMenuItem(value: 1, child: Text(isMr ? '१ महिना (1 Month)' : '1 Month')),
                        DropdownMenuItem(value: 3, child: Text(isMr ? '३ महिने (3 Months)' : '3 Months')),
                        DropdownMenuItem(value: 6, child: Text(isMr ? '६ महिने (6 Months)' : '6 Months')),
                        DropdownMenuItem(value: 12, child: Text(isMr ? '१ वर्ष (12 Months)' : '1 Year (12 Months)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _superAdminTermMonths = val);
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
              const SizedBox(height: 20),

              // Official Support Helpline Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF93C5FD)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.support_agent, color: Color(0xFF1E3A8A), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMr ? 'सोसायटी गेट अधिकृत मदत व सपोर्ट' : 'Official Help & Technical Support',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                          ),
                          const Text(
                            'हेल्पलाइन: 9822681814',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.phone, size: 14),
                      label: Text(isMr ? 'कॉल' : 'Call', style: const TextStyle(fontSize: 12)),
                      onPressed: () => launchUrl(Uri.parse('tel:9822681814'), mode: LaunchMode.externalApplication),
                    ),
                  ],
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
