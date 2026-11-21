import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notice_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notice_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_app_bar.dart';
import 'add_notice_screen.dart';

class NoticeBoardScreen extends StatelessWidget {
  const NoticeBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final noticeProvider = Provider.of<NoticeProvider>(context);

    final notices = noticeProvider.notices;

    return Scaffold(
      appBar: CustomAppBar(
        title: lang.tr('noticeBoard'),
      ),
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_comment),
              label: Text(lang.tr('postNotice')),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddNoticeScreen()),
                );
              },
            )
          : null,
      body: notices.isEmpty
          ? Center(
              child: Text(
                lang.isMarathi ? 'कोणतीही सूचना उपलब्ध नाही' : 'No notices posted',
                style: const TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notices.length,
              itemBuilder: (context, index) {
                final notice = notices[index];
                return _buildNoticeCard(context, notice, lang);
              },
            ),
    );
  }

  Widget _buildNoticeCard(BuildContext context, NoticeModel notice, LanguageProvider lang) {
    final isUrgent = notice.isUrgent;
    final isMr = lang.isMarathi;

    // Guaranteed fallback so Marathi or English text is NEVER missing or blank
    final displayTitle = isMr
        ? (notice.titleMr.trim().isNotEmpty ? notice.titleMr : notice.title)
        : (notice.title.trim().isNotEmpty ? notice.title : notice.titleMr);

    final displayContent = isMr
        ? (notice.contentMr.trim().isNotEmpty ? notice.contentMr : notice.content)
        : (notice.content.trim().isNotEmpty ? notice.content : notice.contentMr);

    String categoryLabel;
    switch (notice.category) {
      case 'meeting_agm':
        categoryLabel = isMr ? 'वार्षिक सभा (AGM)' : 'AGM Meeting';
        break;
      case 'maintenance':
        categoryLabel = isMr ? 'देखभाल सूचना' : 'Maintenance Alert';
        break;
      case 'emergency':
        categoryLabel = isMr ? 'तातडीचे परिपत्रक' : 'Emergency Notice';
        break;
      default:
        categoryLabel = isMr ? 'सर्वसाधारण सूचना' : 'General Notice';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isUrgent ? const Color(0xFFDC2626) : Colors.transparent,
          width: isUrgent ? 1.5 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFDC2626)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
                        const SizedBox(width: 4),
                        Text(
                          isMr ? 'तातडीची सूचना' : 'URGENT',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      categoryLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    ),
                  ),
                Text(
                  AppDateFormatter.formatDate(notice.publishedDate, isMarathi: isMr),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Notice Title
            Text(
              displayTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),

            // Notice Content
            Text(
              displayContent,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),

            // Footer / Issuer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${isMr ? "जारीकर्ता" : "Issued by"}: ${notice.issuedByName}',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                ),
                Icon(Icons.mark_email_read, size: 16, color: Colors.blue.shade800),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
