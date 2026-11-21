import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/collection_handover_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_app_bar.dart';

class HandoverApprovalScreen extends StatelessWidget {
  const HandoverApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isMr = lang.isMarathi;
    final society = auth.currentSociety;

    if (society == null) {
      return Scaffold(
        appBar: CustomAppBar(title: isMr ? 'हस्तांतरण पडताळणी' : 'Handover Approvals'),
        body: const Center(child: Text('No society found')),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: isMr ? 'कलेक्शन हस्तांतरण पडताळणी' : 'Collection Handover Verification',
      ),
      body: StreamBuilder<List<CollectionHandover>>(
        stream: FirestoreService.instance.streamCollectionHandovers(society.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final handovers = snapshot.data ?? [];
          final pendingHandovers = handovers.where((h) => h.isPending).toList();
          final approvedHandovers = handovers.where((h) => h.isApproved).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user, color: Color(0xFF1D4ED8), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isMr
                              ? 'विंग/मजला प्रतिनिधींनी मेंटेनन्स जमा करून आपल्याकडे सुपूर्द केलेल्या रकमांची पडताळणी व पुरावा फोटो येथे तपासा.'
                              : 'Verify maintenance collections handed over by Group Admins with proof photos.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Pending Handovers
                Text(
                  '${isMr ? "प्रलंबित हस्तांतरणे" : "Pending Approvals"} (${pendingHandovers.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryNavy),
                ),
                const SizedBox(height: 10),

                if (pendingHandovers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        isMr ? 'कोणतेही प्रलंबित हस्तांतरण नाही.' : 'No pending handovers.',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  )
                else
                  ...pendingHandovers.map((h) => _buildHandoverCard(context, h, auth, isMr, isPending: true)),

                const SizedBox(height: 24),

                // Approved Handovers
                Text(
                  '${isMr ? "यापूर्वी मंजूर हस्तांतरणे" : "Approved Handovers"} (${approvedHandovers.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryNavy),
                ),
                const SizedBox(height: 10),

                if (approvedHandovers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        isMr ? 'मंजूर हस्तांतरणे उपलब्ध नाहीत.' : 'No approved handovers yet.',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  )
                else
                  ...approvedHandovers.map((h) => _buildHandoverCard(context, h, auth, isMr, isPending: false)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandoverCard(
    BuildContext context,
    CollectionHandover h,
    AuthProvider auth,
    bool isMr, {
    required bool isPending,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    h.assignedGroup,
                    style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPending ? (isMr ? 'पडताळणी बाकी' : 'PENDING') : (isMr ? 'मंजूर केले' : 'APPROVED'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPending ? const Color(0xFFB45309) : const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppDateFormatter.formatCurrency(h.totalAmount),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                      ),
                      Text(
                        '${isMr ? "हस्तांतरणकर्ता" : "From"}: ${h.groupAdminName} (${h.paymentMode.toUpperCase()})',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${isMr ? "दिनांक" : "Date"}: ${AppDateFormatter.formatDate(h.handoverDate, isMarathi: isMr)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      if (h.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${isMr ? "टीप" : "Notes"}: ${h.notes}',
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF334155)),
                        ),
                      ],
                    ],
                  ),
                ),
                // Proof Photo thumbnail
                if (h.proofPhotoUrl.isNotEmpty)
                  InkWell(
                    onTap: () => _showPhotoPreview(context, h.proofPhotoUrl, isMr),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: h.proofPhotoUrl.startsWith('data:image')
                            ? Image.memory(base64Decode(h.proofPhotoUrl.split(',').last), fit: BoxFit.cover)
                            : Image.network(h.proofPhotoUrl, fit: BoxFit.cover),
                      ),
                    ),
                  ),
              ],
            ),
            if (isPending) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: Text(isMr ? 'रक्कम मिळाली (मंजूर करा)' : 'Verify & Approve'),
                    onPressed: () async {
                      await FirestoreService.instance.approveCollectionHandover(
                        handoverId: h.id,
                        superAdminUid: auth.currentUser?.uid ?? 'super_admin',
                        superAdminName: auth.currentUser?.nameMr.isNotEmpty == true
                            ? auth.currentUser!.nameMr
                            : (auth.currentUser?.name ?? 'Super Admin'),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isMr ? 'हस्तांतरण रक्कम यशस्वीपणे मंजूर झाली!' : 'Handover verified & approved!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPhotoPreview(BuildContext context, String photoUrl, bool isMr) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(isMr ? 'हस्तांतरण पावती / स्क्रीनशॉट' : 'Proof Photo', style: const TextStyle(fontSize: 14)),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 450),
              child: photoUrl.startsWith('data:image')
                  ? Image.memory(base64Decode(photoUrl.split(',').last), fit: BoxFit.contain)
                  : Image.network(photoUrl, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }
}
