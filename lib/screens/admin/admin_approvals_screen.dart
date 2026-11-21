import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';

class AdminApprovalsScreen extends StatelessWidget {
  const AdminApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final isMr = lang.isMarathi;
    final society = auth.currentSociety;

    if (society == null) {
      return Scaffold(
        appBar: AppBar(title: Text(isMr ? 'सदस्य मंजुरी' : 'Member Approvals')),
        body: const Center(child: Text('No active society found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isMr ? 'नवीन सदस्य मंजुरी विनंत्या' : 'Pending Member Approvals',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: FirestoreService.instance.streamPendingApprovals(society.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pendingUsers = snapshot.data ?? [];

          if (pendingUsers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF059669)),
                    const SizedBox(height: 16),
                    Text(
                      isMr ? 'कोणतीही प्रलंबित विनंती नाही' : 'No Pending Requests',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isMr
                          ? 'सोसायटी कोड टाकून नवीन सदस्यांनी विनंती पाठवल्यास ती येथे दिसेल.'
                          : 'When new residents enter your Society Code, their requests will appear here.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pendingUsers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = pendingUsers[index];
              return _buildPendingCard(context, user, isMr);
            },
          );
        },
      ),
    );
  }

  Widget _buildPendingCard(BuildContext context, AppUser user, bool isMr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFDBEAFE),
                backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null || user.photoUrl!.isEmpty
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: user.isGuard ? const Color(0xFFFEF3C7) : const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user.isGuard ? (isMr ? 'गार्ड' : 'Guard') : (isMr ? 'सभासद' : 'Member'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: user.isGuard ? const Color(0xFF92400E) : const Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Details row
          Row(
            children: [
              if (user.isMember) ...[
                const Icon(Icons.meeting_room, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  '${isMr ? "फ्लॅट: " : "Flat: "}Wing ${user.wing} - ${user.flatNumber}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(width: 16),
              ],
              if (user.phoneNumber.isNotEmpty) ...[
                const Icon(Icons.phone, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  user.phoneNumber,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  label: Text(isMr ? 'नाकारा' : 'Reject', style: const TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await FirestoreService.instance.rejectMember(user.uid);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isMr ? 'विनंती नाकारली' : 'Request Rejected')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(isMr ? 'मंजूर करा' : 'Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await FirestoreService.instance.approveMember(user.uid);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isMr ? '${user.name} यांना प्रवेश दिला!' : 'Approved ${user.name}!'), backgroundColor: const Color(0xFF059669)),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
