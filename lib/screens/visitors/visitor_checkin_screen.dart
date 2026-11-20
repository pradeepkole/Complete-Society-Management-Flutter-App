import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/visitor_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class VisitorCheckinScreen extends StatefulWidget {
  const VisitorCheckinScreen({super.key});

  @override
  State<VisitorCheckinScreen> createState() => _VisitorCheckinScreenState();
}

class _VisitorCheckinScreenState extends State<VisitorCheckinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _flatController = TextEditingController(text: 'A-402');
  final _vehicleController = TextEditingController();
  String _targetWing = 'A';
  String _purpose = 'purpose_delivery';

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final visitorProvider = Provider.of<VisitorProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: lang.tr('newVisitor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAlignment.start,
            children: [
              // Visitor Name
              Text(lang.tr('visitorName'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person, size: 20),
                  hintText: lang.isMarathi ? 'उदा. सचिन साळुंखे (झोमॅटो)' : 'e.g. Sachin Salunkhe (Zomato)',
                ),
                validator: (val) => val == null || val.isEmpty ? lang.tr('required') : null,
              ),
              const SizedBox(height: 16),

              // Phone Number
              Text(lang.tr('visitorPhone'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone, size: 20),
                  hintText: '+91 98200 12345',
                ),
                validator: (val) => val == null || val.isEmpty ? lang.tr('required') : null,
              ),
              const SizedBox(height: 16),

              // Visiting Flat & Wing
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Text(lang.tr('wing'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _targetWing,
                          items: const [
                            DropdownMenuItem(value: 'A', child: Text('Wing A')),
                            DropdownMenuItem(value: 'B', child: Text('Wing B')),
                            DropdownMenuItem(value: 'C', child: Text('Wing C')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _targetWing = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Text(lang.tr('visitingFlat'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _flatController,
                          decoration: const InputDecoration(hintText: 'A-402'),
                          validator: (val) => val == null || val.isEmpty ? lang.tr('required') : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Purpose of Visit
              Text(lang.tr('purpose'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _purpose,
                items: [
                  DropdownMenuItem(value: 'purpose_delivery', child: Text(lang.tr('purpose_delivery'))),
                  DropdownMenuItem(value: 'purpose_guest', child: Text(lang.tr('purpose_guest'))),
                  DropdownMenuItem(value: 'purpose_maid', child: Text(lang.tr('purpose_maid'))),
                  DropdownMenuItem(value: 'purpose_cab', child: Text(lang.tr('purpose_cab'))),
                  DropdownMenuItem(value: 'purpose_service', child: Text(lang.tr('purpose_service'))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _purpose = val);
                },
              ),
              const SizedBox(height: 16),

              // Vehicle Number
              Text(lang.tr('vehicleNo'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _vehicleController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.two_wheeler, size: 20),
                  hintText: 'MH 01 CW 1234',
                ),
              ),
              const SizedBox(height: 16),

              // Photo Capture Button (Guard Camera)
              OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: Text(lang.isMarathi ? 'अभ्यागताचा फोटो घ्या (Camera)' : 'Capture Visitor Face Photo'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Visitor facial photo captured!')),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Check-in Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.security),
                  label: Text(lang.tr('checkIn')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      await visitorProvider.checkInVisitor(
                        visitorName: _nameController.text,
                        phoneNumber: _phoneController.text,
                        targetWing: _targetWing,
                        targetFlat: _flatController.text,
                        purpose: _purpose,
                        vehicleNumber: _vehicleController.text,
                        guardName: auth.currentUser?.name ?? 'Ramesh Shinde (Guard)',
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Visitor checked in! Alert sent to Flat ${_flatController.text}.'),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
