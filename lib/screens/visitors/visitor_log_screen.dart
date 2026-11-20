import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/visitor_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/visitor_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_app_bar.dart';
import 'visitor_checkin_screen.dart';

class VisitorLogScreen extends StatefulWidget {
  const VisitorLogScreen({super.key});

  @override
  State<VisitorLogScreen> createState() => _VisitorLogScreenState();
}

class _VisitorLogScreenState extends State<VisitorLogScreen> {
  String _filter = 'all'; // 'all', 'inside', 'checkedOut'

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final visitorProvider = Provider.of<VisitorProvider>(context);

    final all = auth.isMember
        ? visitorProvider.getVisitorsForFlat(auth.currentUser?.flatNumber ?? 'A-402')
        : visitorProvider.allVisitors;

    final filtered = all.where((v) {
      if (_filter == 'all') return true;
      if (_filter == 'inside') return v.isInside;
      if (_filter == 'checkedOut') return !v.isInside;
      return true;
    }).toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: lang.tr('visitorEntry'),
      ),
      floatingActionButton: (auth.isGuard || auth.isAdmin)
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add),
              label: Text(lang.tr('newVisitor')),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VisitorCheckinScreen()),
                );
              },
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filter Tabs
            Row(
              children: [
                _buildFilterChip('all', lang.tr('all')),
                const SizedBox(width: 8),
                _buildFilterChip('inside', lang.tr('insideCampus')),
                const SizedBox(width: 8),
                _buildFilterChip('checkedOut', lang.tr('checkedOut')),
              ],
            ),
            const SizedBox(height: 16),

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    lang.isMarathi ? 'कोणतीही नोंद उपलब्ध नाही' : 'No visitor records found',
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
                  final visitor = filtered[index];
                  return _buildVisitorTile(context, visitor, lang, auth, visitorProvider);
                },
              ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryNavy,
      labelStyle: TextStyle(
        fontSize: 11,
        color: isSelected ? Colors.white : Colors.grey.shade800,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _filter = key),
    );
  }

  Widget _buildVisitorTile(
    BuildContext context,
    VisitorModel visitor,
    LanguageProvider lang,
    AuthProvider auth,
    VisitorProvider provider,
  ) {
    final isInside = visitor.isInside;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isInside ? Colors.amber.shade100 : Colors.grey.shade200,
                      child: Icon(
                        _getPurposeIcon(visitor.purpose),
                        color: isInside ? Colors.amber.shade900 : Colors.grey.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Text(
                          visitor.visitorName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${lang.tr('visitingFlat')}: ${visitor.targetFlat}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.primaryNavy),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isInside ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isInside ? Colors.green.shade300 : Colors.grey.shade400),
                  ),
                  child: Text(
                    isInside ? lang.tr('insideCampus') : lang.tr('checkedOut'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isInside ? Colors.green.shade800 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Metadata Row
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(visitor.phoneNumber, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                const SizedBox(width: 16),
                Icon(Icons.category, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(lang.tr(visitor.purpose), style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              ],
            ),
            if (visitor.vehicleNumber.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.directions_car, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('Vehicle: ${visitor.vehicleNumber}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                ],
              ),
            ],
            const SizedBox(height: 6),

            // Timing info
            Text(
              'Entry: ${AppDateFormatter.formatDateTime(visitor.checkInTime, isMarathi: lang.isMarathi)}${visitor.checkOutTime != null ? " • Exit: ${AppDateFormatter.formatDateTime(visitor.checkOutTime!, isMarathi: lang.isMarathi)}" : ""}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),

            // Member Approval / Guard Check-out Actions
            if (isInside) ...[
              const Divider(height: 18),
              if (auth.isMember && visitor.memberApproval == 'pendingApproval')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lang.tr('alertMember'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => provider.setApproval(visitor.id, 'denied'),
                          child: const Text('Deny', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                          onPressed: () => provider.setApproval(visitor.id, 'approved'),
                          child: const Text('Approve', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                )
              else if (auth.isGuard || auth.isAdmin)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Guard: ${visitor.guardName}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.exit_to_app, size: 14),
                      label: Text(lang.tr('checkOut'), style: const TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => provider.checkOutVisitor(visitor.id),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getPurposeIcon(String purposeKey) {
    switch (purposeKey) {
      case 'purpose_delivery':
        return Icons.local_shipping;
      case 'purpose_cab':
        return Icons.local_taxi;
      case 'purpose_maid':
        return Icons.cleaning_services;
      case 'purpose_service':
        return Icons.build;
      default:
        return Icons.person;
    }
  }
}
