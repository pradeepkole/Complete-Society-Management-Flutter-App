import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notice_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class AddNoticeScreen extends StatefulWidget {
  const AddNoticeScreen({super.key});

  @override
  State<AddNoticeScreen> createState() => _AddNoticeScreenState();
}

class _AddNoticeScreenState extends State<AddNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleEnController = TextEditingController();
  final _titleMrController = TextEditingController();
  final _contentEnController = TextEditingController();
  final _contentMrController = TextEditingController();
  String _category = 'general';
  String _priority = 'normal';

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final noticeProvider = Provider.of<NoticeProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: lang.tr('postNotice'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice Category & Priority
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: const [
                        DropdownMenuItem(value: 'general', child: Text('General Notice')),
                        DropdownMenuItem(value: 'meeting_agm', child: Text('AGM / SGM Meeting')),
                        DropdownMenuItem(value: 'maintenance', child: Text('Maintenance Alert')),
                        DropdownMenuItem(value: 'emergency', child: Text('Emergency Circular')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: const [
                        DropdownMenuItem(value: 'normal', child: Text('Normal')),
                        DropdownMenuItem(value: 'urgent', child: Text('URGENT ⚠️')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _priority = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title (English)
              const Text('Notice Title (English)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleEnController,
                decoration: const InputDecoration(hintText: 'e.g. Society Terrace Cleaning Drive'),
                validator: (val) => val == null || val.isEmpty ? lang.tr('required') : null,
              ),
              const SizedBox(height: 12),

              // Title (Marathi)
              const Text('सूचनेचे शीर्षक (मराठी)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleMrController,
                decoration: const InputDecoration(hintText: 'उदा. सोसायटी गच्ची स्वच्छता मोहीम'),
              ),
              const SizedBox(height: 16),

              // Message (English)
              const Text('Circular Body / Details (English)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contentEnController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Enter complete circular details...'),
                validator: (val) => val == null || val.isEmpty ? lang.tr('required') : null,
              ),
              const SizedBox(height: 12),

              // Message (Marathi)
              const Text('परिपत्रक मजकूर (मराठी)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contentMrController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'सविस्तर सूचना येथे लिहा...'),
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
                      await noticeProvider.postNotice(
                        title: _titleEnController.text,
                        titleMr: _titleMrController.text.isNotEmpty ? _titleMrController.text : _titleEnController.text,
                        content: _contentEnController.text,
                        contentMr: _contentMrController.text.isNotEmpty ? _contentMrController.text : _contentEnController.text,
                        category: _category,
                        priority: _priority,
                        issuedByName: auth.currentUser?.name ?? 'Hon. Secretary',
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notice broadcasted to all flat members!')),
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
