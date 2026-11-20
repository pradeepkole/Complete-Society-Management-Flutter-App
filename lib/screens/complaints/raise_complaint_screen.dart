import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class RaiseComplaintScreen extends StatefulWidget {
  const RaiseComplaintScreen({super.key});

  @override
  State<RaiseComplaintScreen> createState() => _RaiseComplaintScreenState();
}

class _RaiseComplaintScreenState extends State<RaiseComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'cat_plumbing';
  String _priority = 'medium';

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final complaintProvider = Provider.of<ComplaintProvider>(context);

    final flatNumber = auth.currentUser?.flatNumber.isNotEmpty == true
        ? auth.currentUser!.flatNumber
        : 'A-402';

    return Scaffold(
      appBar: CustomAppBar(
        title: lang.tr('raiseComplaint'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAlignment.start,
            children: [
              // Flat badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.home, color: AppTheme.primaryNavy, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${lang.tr('flat')}: $flatNumber (${auth.currentUser?.name ?? "Rajesh Deshmukh"})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryNavy),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Category Selector
              Text(lang.tr('complaintCategory'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _category,
                items: [
                  DropdownMenuItem(value: 'cat_plumbing', child: Text(lang.tr('cat_plumbing'))),
                  DropdownMenuItem(value: 'cat_electrical', child: Text(lang.tr('cat_electrical'))),
                  DropdownMenuItem(value: 'cat_cleaning', child: Text(lang.tr('cat_cleaning'))),
                  DropdownMenuItem(value: 'cat_lift', child: Text(lang.tr('cat_lift'))),
                  DropdownMenuItem(value: 'cat_security', child: Text(lang.tr('cat_security'))),
                  DropdownMenuItem(value: 'cat_other', child: Text(lang.tr('cat_other'))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 16),

              // Complaint Title
              Text(
                lang.isMarathi ? 'तक्रारीचा विषय / शीर्षक' : 'Issue Summary / Headline',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: lang.isMarathi ? 'उदा. बेसिन खाली पाणी गळती' : 'e.g. Washbasin pipe leaking',
                ),
                validator: (val) => val == null || val.isEmpty ? lang.tr('required') : null,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                lang.isMarathi ? 'सविस्तर माहिती' : 'Detailed Description',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: lang.isMarathi
                      ? 'समस्या कधीपासून आहे व नेमके काय काम हवे ते लिहा...'
                      : 'Provide location and details of the problem...',
                ),
                validator: (val) => val == null || val.isEmpty ? lang.tr('required') : null,
              ),
              const SizedBox(height: 16),

              // Attach Photo
              OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: Text(lang.isMarathi ? 'समस्येचा फोटो जोडा (ऐच्छिक)' : 'Attach Photo of Issue (Optional)'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Photo attached!')),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: Text(lang.tr('submit')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      await complaintProvider.raiseComplaint(
                        flatNumber: flatNumber,
                        memberUid: auth.currentUser?.uid ?? 'usr_member_01',
                        memberName: auth.currentUser?.name ?? 'Rajesh Deshmukh',
                        category: _category,
                        title: _titleController.text,
                        description: _descController.text,
                        priority: _priority,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Helpdesk ticket raised! Society technician will be notified.')),
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
