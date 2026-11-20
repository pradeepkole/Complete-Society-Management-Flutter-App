import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_app_bar.dart';
import 'raise_complaint_screen.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final complaintProvider = Provider.of<ComplaintProvider>(context);

    final all = auth.isAdmin
        ? complaintProvider.allComplaints
        : complaintProvider.getComplaintsForFlat(auth.currentUser?.flatNumber ?? 'A-402');

    final filtered = all.where((c) {
      if (_selectedStatus == 'all') return true;
      return c.status == _selectedStatus;
    }).toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: lang.tr('complaintsHelpdesk'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task),
        label: Text(lang.tr('raiseComplaint')),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RaiseComplaintScreen()),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Filter Tabs
            Row(
              children: [
                _buildFilterChip('all', lang.tr('all')),
                const SizedBox(width: 8),
                _buildFilterChip('open', lang.tr('open')),
                const SizedBox(width: 8),
                _buildFilterChip('inProgress', lang.tr('inProgress')),
                const SizedBox(width: 8),
                _buildFilterChip('resolved', lang.tr('resolved')),
              ],
            ),
            const SizedBox(height: 16),

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    lang.isMarathi ? 'कोणतीही तक्रार नोंदवलेली नाही' : 'No complaints registered',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return _buildComplaintCard(context, item, lang, auth, complaintProvider);
                },
              ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedStatus == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryNavy,
      labelStyle: TextStyle(
        fontSize: 11,
        color: isSelected ? Colors.white : Colors.grey.shade800,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _selectedStatus = key),
    );
  }

  Widget _buildComplaintCard(
    BuildContext context,
    ComplaintModel item,
    LanguageProvider lang,
    AuthProvider auth,
    ComplaintProvider provider,
  ) {
    Color statusColor;
    String statusText;

    switch (item.status) {
      case 'resolved':
        statusColor = const Color(0xFF16A34A);
        statusText = lang.tr('resolved');
        break;
      case 'inProgress':
        statusColor = const Color(0xFF0284C7);
        statusText = lang.tr('inProgress');
        break;
      case 'open':
      default:
        statusColor = const Color(0xFFEA580C);
        statusText = lang.tr('open');
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.flatNumber} • ${lang.tr(item.category)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryNavy),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),

            Text(
              item.description,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 10),

            if (item.adminRemarks.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.engineering, size: 16, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Technician: ${item.adminRemarks}',
                        style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Raised on: ${AppDateFormatter.formatDate(item.createdAt, isMarathi: lang.isMarathi)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                if (auth.isAdmin && item.status != 'resolved')
                  TextButton(
                    onPressed: () => _showUpdateStatusDialog(context, item, provider, lang),
                    child: const Text('Update Status', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStatusDialog(
    BuildContext context,
    ComplaintModel item,
    ComplaintProvider provider,
    LanguageProvider lang,
  ) {
    String newStatus = item.status;
    final remarksController = TextEditingController(text: item.adminRemarks);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Complaint (${item.flatNumber})', style: const TextStyle(fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: newStatus,
              items: const [
                DropdownMenuItem(value: 'open', child: Text('Open')),
                DropdownMenuItem(value: 'inProgress', child: Text('In Progress (Technician Assigned)')),
                DropdownMenuItem(value: 'resolved', child: Text('Resolved & Closed')),
              ],
              onChanged: (val) {
                if (val != null) newStatus = val;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(labelText: 'Admin / Technician Remarks'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.tr('cancel'))),
          ElevatedButton(
            onPressed: () async {
              await provider.updateStatus(item.id, newStatus, remarksController.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(lang.tr('save')),
          ),
        ],
      ),
    );
  }
}
