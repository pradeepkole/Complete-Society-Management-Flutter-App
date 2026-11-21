import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../dashboard/main_navigation_dashboard.dart';

class CreateSocietyScreen extends StatefulWidget {
  const CreateSocietyScreen({super.key});

  @override
  State<CreateSocietyScreen> createState() => _CreateSocietyScreenState();
}

class _CreateSocietyScreenState extends State<CreateSocietyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameEnController = TextEditingController();
  final _nameMrController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Pune');
  final _pincodeController = TextEditingController();
  final _regNoController = TextEditingController();
  final _wingsController = TextEditingController(text: 'A, B');
  final _flatsController = TextEditingController(text: '30');

  String _groupingType = 'wing'; // 'wing' or 'floor'
  int _superAdminTermMonths = 3;

  Uint8List? _logoBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 75,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _logoBytes = bytes;
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
              title: Text(isMr ? 'गॅलरीतून निवडा' : 'Choose from Gallery'),
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
            if (_logoBytes != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(isMr ? 'लोगो हटवा' : 'Remove Logo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _logoBytes = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm(AuthProvider auth, bool isMr) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final wingsList = _wingsController.text
        .split(',')
        .map((w) => w.trim().toUpperCase())
        .where((w) => w.isNotEmpty)
        .toList();

    final totalFlats = int.tryParse(_flatsController.text) ?? 30;

    final success = await auth.createNewSociety(
      name: _nameEnController.text.trim(),
      nameMr: _nameMrController.text.trim().isNotEmpty
          ? _nameMrController.text.trim()
          : _nameEnController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      pincode: _pincodeController.text.trim(),
      registrationNo: _regNoController.text.trim(),
      wings: wingsList.isNotEmpty ? wingsList : ['A', 'B'],
      totalFlats: totalFlats,
      logoBytes: _logoBytes,
      groupingType: _groupingType,
      superAdminTermMonths: _superAdminTermMonths,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      final society = auth.currentSociety;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF059669), size: 28),
              const SizedBox(width: 10),
              Text(
                isMr ? 'सोसायटी यशस्वीपणे नोंदवली!' : 'Society Registered!',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMr
                    ? 'आपली संस्था तयार झाली आहे. सभासदांना अ‍ॅपमध्ये जोडण्यासाठी खालील युनिक कोड द्या:'
                    : 'Your society is ready. Share this 6-digit code with residents to join:',
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
                  ),
                  child: Text(
                    society?.societyCode ?? 'SOC-XXXXXX',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), letterSpacing: 2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                icon: const Icon(Icons.share, size: 18),
                label: Text(isMr ? 'WhatsApp वर कोड शेअर करा' : 'Share Code on WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
                onPressed: () {
                  final msg = isMr
                      ? 'नमस्कार, आपल्या ${society?.nameMr ?? society?.name} सोसायटीचे अधिकृत अ‍ॅप सुरू झाले आहे. अ‍ॅप डाऊनलोड करून जॉइन करण्यासाठी कोड: ${society?.societyCode} वापरा.'
                      : 'Hello, our society app for ${society?.name} is live. Download the app and enter Society Code: ${society?.societyCode} to join.';
                  Share.share(msg);
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
              ),
              child: Text(isMr ? 'डॅशबोर्डवर जा ➔' : 'Go to Dashboard ➔'),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainNavigationDashboard()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Failed to create society'), backgroundColor: Colors.red),
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
          isMr ? 'नवीन सोसायटी नोंदणी' : 'Register Society',
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
              // Logo Attachment Box
              Center(
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _showLogoPickerSheet(isMr),
                      borderRadius: BorderRadius.circular(50),
                      child: Stack(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEFF6FF),
                              border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                              image: _logoBytes != null
                                  ? DecorationImage(image: MemoryImage(_logoBytes!), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: _logoBytes == null
                                ? const Icon(Icons.apartment_rounded, size: 48, color: Color(0xFF3B82F6))
                                : null,
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
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isMr ? 'सोसायटी लोगो जोडा (ऐच्छिक)' : 'Attach Society Logo (Optional)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                    ),
                    Text(
                      isMr ? 'हा लोगो पावत्या व ऑडिट रिपोर्टवर दिसेल' : 'Logo appears on receipts & audit reports',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Society Name (English)
              Text(isMr ? 'सोसायटीचे नाव (इंग्रजीत) *' : 'Society Name (English) *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameEnController,
                decoration: InputDecoration(
                  hintText: isMr ? 'उदा. Shivneri Co-op Housing Society' : 'e.g. Shivneri Co-op Housing Society',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? (isMr ? 'सोसायटीचे नाव आवश्यक आहे' : 'Name is required') : null,
              ),
              const SizedBox(height: 16),

              // Society Name (Marathi)
              Text(isMr ? 'सोसायटीचे नाव (मराठीत)' : 'Society Name (Marathi)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameMrController,
                decoration: InputDecoration(
                  hintText: isMr ? 'उदा. शिवनेरी सहकारी गृहनिर्माण संस्था मर्यादित' : 'e.g. शिवनेरी सहकारी गृहनिर्माण संस्था मर्यादित',
                  prefixIcon: const Icon(Icons.translate),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),

              // Address
              Text(isMr ? 'संपूर्ण पत्ता *' : 'Complete Address *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: isMr ? 'उदा. प्लॉट नं. १२, संभाजी चौक, बाणेर' : 'e.g. Plot No 12, Sambhaji Chowk, Baner',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? (isMr ? 'पत्ता आवश्यक आहे' : 'Address is required') : null,
              ),
              const SizedBox(height: 16),

              // City & Pincode
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isMr ? 'शहर *' : 'City *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            hintText: 'Pune / Mumbai',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'City required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isMr ? 'पिनकोड' : 'Pincode', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '411045',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Registration No.
              Text(isMr ? 'नोंदणी क्रमांक (Registration No.)' : 'Registration Number (Optional)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _regNoController,
                decoration: InputDecoration(
                  hintText: 'MUM/PHE/CHS/1234/2021',
                  prefixIcon: const Icon(Icons.assignment),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),

              // Wings & Total Flats
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isMr ? 'विंग्स (कॉमाने वेगळे करा)' : 'Wings (Comma separated)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _wingsController,
                          decoration: InputDecoration(
                            hintText: 'A, B, C',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isMr ? 'एकूण फ्लॅट्स' : 'Total Flats', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _flatsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '30',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Grouping Type (Wing vs Floor)
              Text(
                isMr ? 'व्यवस्थापन गट पद्धत (Grouping Structure) *' : 'Management Grouping Structure *',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Text(isMr ? 'विंग पद्धत (Wing-wise) - उदा. A, B, C विंग्स' : 'Wing-wise (e.g. Wing A, B, C)'),
                      subtitle: Text(isMr ? 'प्रत्येक विंगसाठी स्वतंत्र ग्रुप ॲडमिन राहील' : 'Each wing will have its own Group Admin'),
                      value: 'wing',
                      groupValue: _groupingType,
                      onChanged: (val) {
                        if (val != null) setState(() => _groupingType = val);
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: Text(isMr ? 'मजला पद्धत (Floor-wise) - उदा. १ ला, २ रा मजला' : 'Floor-wise (e.g. 1st, 2nd, 3rd Floor)'),
                      subtitle: Text(isMr ? 'प्रत्येक मजल्यासाठी स्वतंत्र ग्रुप ॲडमिन राहील' : 'Each floor will have its own Group Admin'),
                      value: 'floor',
                      groupValue: _groupingType,
                      onChanged: (val) {
                        if (val != null) setState(() => _groupingType = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Super Admin Term
              Text(
                isMr ? 'सुपर ॲडमिन (सचिव) कार्यकाळ *' : 'Super Admin Tenure *',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: _superAdminTermMonths,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.timer),
                  helperText: isMr
                      ? 'मुदत संपत आल्यावर ॲपमध्ये कमिटीला सूचना येईल'
                      : 'App will alert committee when term is near completion',
                ),
                items: [
                  DropdownMenuItem(value: 1, child: Text(isMr ? '१ महिना (1 Month)' : '1 Month')),
                  DropdownMenuItem(value: 3, child: Text(isMr ? '३ महिने (3 Months - शिफारस केलेले)' : '3 Months (Recommended)')),
                  DropdownMenuItem(value: 6, child: Text(isMr ? '६ महिने (6 Months)' : '6 Months')),
                  DropdownMenuItem(value: 12, child: Text(isMr ? '१ वर्ष (12 Months)' : '1 Year (12 Months)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _superAdminTermMonths = val);
                },
              ),
              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : () => _submitForm(auth, isMr),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isMr ? 'सोसायटी तयार करा व कोड मिळवा ➔' : 'Create Society & Get Code ➔',
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
