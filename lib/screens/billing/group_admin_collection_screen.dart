import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/maintenance_bill_model.dart';
import '../../models/collection_handover_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/billing_provider.dart';
import '../../services/firestore_service.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_app_bar.dart';

class GroupAdminCollectionScreen extends StatefulWidget {
  const GroupAdminCollectionScreen({super.key});

  @override
  State<GroupAdminCollectionScreen> createState() => _GroupAdminCollectionScreenState();
}

class _GroupAdminCollectionScreenState extends State<GroupAdminCollectionScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final billing = Provider.of<BillingProvider>(context);
    final isMr = lang.isMarathi;
    final currentUser = auth.currentUser;
    final society = auth.currentSociety;

    final assignedGroup = currentUser?.assignedGroup ?? (currentUser?.wing.isNotEmpty == true ? 'Wing ${currentUser!.wing}' : 'My Group');

    // Filter bills belonging to this Group Admin's wing or floor
    final groupBills = billing.allBills.where((b) {
      if (currentUser?.assignedGroup != null && currentUser!.assignedGroup!.isNotEmpty) {
        final g = currentUser.assignedGroup!.toLowerCase();
        if (g.contains('wing')) {
          final wingLetter = g.replaceAll('wing', '').trim().toUpperCase();
          if (b.wing.toUpperCase() == wingLetter) return true;
        } else if (g.contains('floor')) {
          final floorDigit = g.replaceAll(RegExp(r'[^0-9]'), '');
          if (floorDigit.isNotEmpty && b.flatNumber.contains(floorDigit)) return true;
        }
      }
      if (currentUser?.wing.isNotEmpty == true) {
        return b.wing == currentUser?.wing;
      }
      return true;
    }).toList();

    final paidBills = groupBills.where((b) => b.isPaid).toList();
    final unpaidBills = groupBills.where((b) => !b.isPaid).toList();
    final totalCollected = paidBills.fold(0.0, (sum, b) => sum + b.totalAmount);
    final totalPending = unpaidBills.fold(0.0, (sum, b) => sum + b.totalAmount);

    return Scaffold(
      appBar: CustomAppBar(
        title: isMr ? '$assignedGroup - मेंटेनन्स संकलन' : '$assignedGroup - Collection',
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.send_to_mobile),
        label: Text(isMr ? 'सुपर ॲडमिनकडे जमा करा' : 'Handover to Super Admin'),
        onPressed: () => _showHandoverDialog(context, totalCollected, assignedGroup, isMr),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMr ? 'ग्रुप ॲडमिन (संकलन प्रतिनिधी)' : 'Group Collection Admin',
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                        child: Text(assignedGroup, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppDateFormatter.formatCurrency(totalCollected),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isMr ? 'आपल्या गटाकडून गोळा झालेली एकूण रक्कम' : 'Total collected in your group',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pending vs Collected Stats
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isMr ? 'जमा पावती झाली' : 'Paid Bills', style: const TextStyle(fontSize: 11, color: Color(0xFF065F46))),
                        Text('${paidBills.length} / ${groupBills.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isMr ? 'थकबाकी बाकी' : 'Pending', style: const TextStyle(fontSize: 11, color: Color(0xFF92400E))),
                        Text(AppDateFormatter.formatCurrency(totalPending), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Collection Instruction Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppTheme.primaryNavy, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isMr
                          ? 'कॅश दिल्यास पावतीचा फोटो आणि UPI केल्यास सदस्याकडून आलेला स्क्रीनशॉट अपलोड करा.'
                          : 'Upload cash receipt photo for cash, or member UPI screenshot for UPI.',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Group Members' Bills List
            Text(
              isMr ? 'फ्लॅटनिहाय देयके यादी' : 'Group Flat Bills',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryNavy),
            ),
            const SizedBox(height: 8),

            if (groupBills.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Text(
                    isMr ? 'या गटासाठी कोणतीही देयके उपलब्ध नाहीत.' : 'No bills found for this group.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...groupBills.map((bill) => _buildBillTile(context, bill, billing, auth, isMr)),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildBillTile(
    BuildContext context,
    MaintenanceBill bill,
    BillingProvider billing,
    AuthProvider auth,
    bool isMr,
  ) {
    final isPaid = bill.isPaid;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              child: Icon(
                isPaid ? Icons.check_circle : Icons.pending,
                color: isPaid ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${bill.flatNumber} (${bill.wing})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPaid ? (isMr ? 'भरले' : 'PAID') : (isMr ? 'थकीत' : 'UNPAID'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPaid ? const Color(0xFF15803D) : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${bill.memberName} • ${bill.billMonth}/${bill.billYear}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  if (bill.adjustments > 0)
                    Text(
                      '${isMr ? "खर्च रद्द वजावट" : "Reversal Credit"}: -₹${bill.adjustments.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppDateFormatter.formatCurrency(bill.netPayable),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryNavy),
                ),
                const SizedBox(height: 6),
                if (!isPaid)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => _showRecordPaymentDialog(context, bill, billing, auth, isMr),
                    child: Text(isMr ? 'जमा नोंदवा' : 'Collect'),
                  )
                else
                  Text(
                    bill.paymentMode.toUpperCase(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordPaymentDialog(
    BuildContext context,
    MaintenanceBill bill,
    BillingProvider billing,
    AuthProvider auth,
    bool isMr,
  ) {
    String paymentMode = 'cash';
    final refController = TextEditingController(text: 'REC-${bill.flatNumber}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    Uint8List? proofBytes;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('${isMr ? "शुल्क जमा नोंदवा" : "Record Collection"} (${bill.flatNumber})'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${isMr ? "रक्कम" : "Amount"}: ${AppDateFormatter.formatCurrency(bill.netPayable)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                Text(isMr ? 'पेमेंट प्रकार *' : 'Payment Mode *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text(isMr ? 'रोख (Cash)' : 'Cash'),
                      selected: paymentMode == 'cash',
                      onSelected: (_) => setState(() => paymentMode = 'cash'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(isMr ? 'UPI पेमेंट' : 'UPI'),
                      selected: paymentMode == 'upi',
                      onSelected: (_) => setState(() => paymentMode = 'upi'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refController,
                  decoration: InputDecoration(
                    labelText: paymentMode == 'cash' ? (isMr ? 'पावती क्रमांक / Ref' : 'Receipt No') : (isMr ? 'UPI UTR क्रमांक' : 'UPI UTR No'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Photo Proof Upload
                Text(
                  paymentMode == 'cash'
                      ? (isMr ? 'कॅश पावतीचा फोटो जोडा *' : 'Upload Cash Receipt Photo *')
                      : (isMr ? 'सदस्याचा UPI स्क्रीनशॉट जोडा *' : 'Upload Member UPI Screenshot *'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final XFile? file = await _picker.pickImage(
                      source: paymentMode == 'cash' ? ImageSource.camera : ImageSource.gallery,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 80,
                    );
                    if (file != null) {
                      final bytes = await file.readAsBytes();
                      setState(() => proofBytes = bytes);
                    }
                  },
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    child: proofBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(proofBytes!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(paymentMode == 'cash' ? Icons.camera_alt : Icons.screenshot, color: Colors.grey.shade600),
                              const SizedBox(height: 4),
                              Text(
                                isMr ? 'फोटो काढण्यासाठी किंवा गॅलरीतून निवडण्यासाठी टॅप करा' : 'Tap to capture / select screenshot',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(isMr ? 'रद्द' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
              onPressed: () async {
                await billing.recordMemberPaymentByAdmin(
                  bill: bill,
                  paymentMode: paymentMode,
                  utrRef: refController.text.trim(),
                  proofBytes: proofBytes,
                  adminUid: auth.currentUser?.uid ?? 'group_admin',
                );

                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isMr ? '${bill.flatNumber} चे शुल्क जमा झाले व पावती तयार झाली!' : 'Payment recorded & receipt issued!',
                      ),
                    ),
                  );
                }
              },
              child: Text(isMr ? 'जमा करा' : 'Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHandoverDialog(BuildContext context, double totalCollected, String assignedGroup, bool isMr) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final amountController = TextEditingController(text: totalCollected > 0 ? totalCollected.toStringAsFixed(0) : '0');
    final notesController = TextEditingController();
    String paymentMode = 'cash';
    Uint8List? proofBytes;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(isMr ? 'सुपर ॲडमिनकडे रक्कम सुपूर्द करा' : 'Handover to Super Admin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMr
                      ? 'आपल्या विंग/मजल्याची गोळा झालेली रक्कम सुपर ॲडमिनकडे (सचिव/चेअरमनकडे) जमा करताना पुरावा फोटो जोडा:'
                      : 'Hand over collected maintenance to Super Admin with proof photo:',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isMr ? 'हस्तांतरण रक्कम (₹) *' : 'Handover Amount (₹) *',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text(isMr ? 'रोख दिली (Cash)' : 'Cash'),
                      selected: paymentMode == 'cash',
                      onSelected: (_) => setState(() => paymentMode = 'cash'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(isMr ? 'UPI ट्रान्सफर केले' : 'UPI Transfer'),
                      selected: paymentMode == 'upi',
                      onSelected: (_) => setState(() => paymentMode = 'upi'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: isMr ? 'तपशील / टीप' : 'Notes',
                    hintText: isMr ? 'उदा. ऑगस्ट महिना संकलन जमा' : 'e.g. August collection handover',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Proof photo upload
                Text(
                  paymentMode == 'cash'
                      ? (isMr ? 'कॅश पावतीचा फोटो जोडा *' : 'Upload Cash Voucher Photo *')
                      : (isMr ? 'UPI ट्रान्सफर स्क्रीनशॉट जोडा *' : 'Upload UPI Screenshot *'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final XFile? file = await _picker.pickImage(
                      source: paymentMode == 'cash' ? ImageSource.camera : ImageSource.gallery,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 80,
                    );
                    if (file != null) {
                      final bytes = await file.readAsBytes();
                      setState(() => proofBytes = bytes);
                    }
                  },
                  child: Container(
                    height: 90,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    child: proofBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(proofBytes!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.grey.shade600),
                              const SizedBox(height: 4),
                              Text(isMr ? 'फोटो अपलोड करा' : 'Upload Photo', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(isMr ? 'रद्द' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              onPressed: () async {
                final amt = double.tryParse(amountController.text) ?? 0;
                if (amt <= 0) return;

                final handover = CollectionHandover(
                  id: '',
                  societyId: auth.currentSociety?.id ?? '',
                  groupAdminUid: auth.currentUser?.uid ?? '',
                  groupAdminName: auth.currentUser?.nameMr.isNotEmpty == true ? auth.currentUser!.nameMr : (auth.currentUser?.name ?? 'Admin'),
                  assignedGroup: assignedGroup,
                  totalAmount: amt,
                  paymentMode: paymentMode,
                  handoverDate: DateTime.now(),
                  notes: notesController.text.trim(),
                );

                await FirestoreService.instance.recordCollectionHandover(
                  handover: handover,
                  proofBytes: proofBytes,
                );

                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isMr
                            ? 'रक्कम हस्तांतरण नोंद यशस्वी झाली! सुपर ॲडमिन पडताळणी करतील.'
                            : 'Handover recorded! Super admin will verify.',
                      ),
                    ),
                  );
                }
              },
              child: Text(isMr ? 'सुपूर्द करा' : 'Submit Handover'),
            ),
          ],
        ),
      ),
    );
  }
}
