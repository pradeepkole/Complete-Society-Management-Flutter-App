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
                      decoration: InputDecoration(labelText: lang.isMarathi ? 'सूचनेचा प्रकार' : 'Category'),
                      items: [
                        DropdownMenuItem(value: 'general', child: Text(lang.isMarathi ? 'सर्वसाधारण सूचना' : 'General Notice')),
                        DropdownMenuItem(value: 'meeting_agm', child: Text(lang.isMarathi ? 'वार्षिक सभा (AGM)' : 'AGM / SGM Meeting')),
                        DropdownMenuItem(value: 'maintenance', child: Text(lang.isMarathi ? 'देखभाल सूचना' : 'Maintenance Alert')),
                        DropdownMenuItem(value: 'emergency', child: Text(lang.isMarathi ? 'तातडीचे परिपत्रक' : 'Emergency Circular')),
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
                      decoration: InputDecoration(labelText: lang.isMarathi ? 'प्राधान्य' : 'Priority'),
                      items: [
                        DropdownMenuItem(value: 'normal', child: Text(lang.isMarathi ? 'नियमित' : 'Normal')),
                        DropdownMenuItem(value: 'urgent', child: Text(lang.isMarathi ? 'तातडीची ⚠️' : 'URGENT ⚠️')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _priority = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title (Marathi)
              Text(
                lang.isMarathi ? 'सूचनेचे शीर्षक (मराठी) *' : 'Notice Title (Marathi)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleMrController,
                decoration: InputDecoration(
                  hintText: lang.isMarathi ? 'उदा. सोसायटी गच्ची स्वच्छता व पाणीपुरवठा सूचना' : 'e.g. Society Water Supply Notice',
                ),
                validator: (val) {
                  if (lang.isMarathi && (val == null || val.trim().isEmpty) && _titleEnController.text.trim().isEmpty) {
                    return lang.tr('required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Title (English - Optional if Marathi is filled)
              Text(
                lang.isMarathi ? 'सूचनेचे शीर्षक (इंग्रजी - ऐच्छिक)' : 'Notice Title (English) *',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleEnController,
                decoration: const InputDecoration(hintText: 'e.g. Society Water Supply Notice'),
                validator: (val) {
                  if (!lang.isMarathi && (val == null || val.trim().isEmpty) && _titleMrController.text.trim().isEmpty) {
                    return lang.tr('required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Message (Marathi)
              Text(
                lang.isMarathi ? 'परिपत्रक / सविस्तर मजकूर (मराठी) *' : 'Notice Body (Marathi)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contentMrController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: lang.isMarathi ? 'येथे सविस्तर सूचना किंवा परिपत्रक लिहा...' : 'Enter notice description in Marathi...',
                ),
                validator: (val) {
                  if (lang.isMarathi && (val == null || val.trim().isEmpty) && _contentEnController.text.trim().isEmpty) {
                    return lang.tr('required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Message (English - Optional if Marathi is filled)
              Text(
                lang.isMarathi ? 'परिपत्रक मजकूर (इंग्रजी - ऐच्छिक)' : 'Circular Body / Details (English) *',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contentEnController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Enter complete circular details in English...'),
                validator: (val) {
                  if (!lang.isMarathi && (val == null || val.trim().isEmpty) && _contentMrController.text.trim().isEmpty) {
                    return lang.tr('required');
                  }
                  return null;
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
                      final titleMr = _titleMrController.text.trim();
                      final titleEn = _titleEnController.text.trim();
                      final contentMr = _contentMrController.text.trim();
                      final contentEn = _contentEnController.text.trim();

                      final finalTitleMr = titleMr.isNotEmpty ? titleMr : titleEn;
                      final finalTitleEn = titleEn.isNotEmpty ? titleEn : titleMr;
                      final finalContentMr = contentMr.isNotEmpty ? contentMr : contentEn;
                      final finalContentEn = contentEn.isNotEmpty ? contentEn : contentMr;

                      await noticeProvider.postNotice(
                        title: finalTitleEn,
                        titleMr: finalTitleMr,
                        content: finalContentEn,
                        contentMr: finalContentMr,
                        category: _category,
                        priority: _priority,
                        issuedByName: auth.currentUser?.nameMr.isNotEmpty == true
                            ? auth.currentUser!.nameMr
                            : (auth.currentUser?.name ?? (lang.isMarathi ? 'सोसायटी सचिव' : 'Hon. Secretary')),
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              lang.isMarathi
                                  ? 'सूचना सर्व सदस्यांच्या सूचना फलकावर प्रसिद्ध झाली!'
                                  : 'Notice broadcasted to all flat members!',
                            ),
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
