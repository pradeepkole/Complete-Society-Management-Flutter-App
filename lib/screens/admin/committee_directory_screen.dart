import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/society_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_app_bar.dart';

class CommitteeDirectoryScreen extends StatelessWidget {
  const CommitteeDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final society = auth.currentSociety;
    final isMr = lang.isMarathi;

    if (society == null) {
      return Scaffold(
        appBar: CustomAppBar(title: isMr ? 'समिती पद फलक' : 'Committee Directory'),
        body: const Center(child: Text('No society found')),
      );
    }

    final isWingWise = society.isWingWise;

    return Scaffold(
      appBar: CustomAppBar(
        title: isMr ? 'समिती पद फलक व प्रतिनिधी' : 'Committee & Group Admins',
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: FirestoreService.instance.streamSocietyMembers(society.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = (snapshot.data ?? []).where((m) => !m.isSoftAdmin).toList();
          final chairman = members.where((m) => m.isChairman).firstOrNull;
          final superAdmin = members.where((m) => m.isSuperAdmin).firstOrNull;
          final groupAdmins = members.where((m) => m.isGroupAdmin).toList();
          final regularMembers = members.where((m) => !m.isChairman && !m.isSuperAdmin && !m.isGroupAdmin && !m.isGuard).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Term Alert Banner for Super Admin
                if (society.isSuperAdminTermDue)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.alarm, color: Colors.red, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isMr
                                    ? '⚠️ सूचना: सुपर ॲडमिन पदाचा कार्यकाळ पूर्ण होत आला आहे!'
                                    : '⚠️ Notice: Super Admin tenure is near completion!',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF991B1B)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isMr
                              ? 'सोसायटी नियमानुसार कार्यकाळ संपत आल्याने कमिटी बैठकीनुसार नवीन सुपर ॲडमिनची निवड करा.'
                              : 'As per society tenure policy, please select and appoint the new Super Admin.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
                        ),
                        if (auth.canManageExpenses) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                icon: const Icon(Icons.person_add, size: 16),
                                label: Text(isMr ? 'नवीन सुपर ॲडमिन नियुक्त करा' : 'Appoint New Super Admin'),
                                onPressed: () => _showAppointSuperAdminDialog(context, society, members, isMr),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade900,
                                  side: BorderSide(color: Colors.red.shade700),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                icon: const Icon(Icons.timer_outlined, size: 16),
                                label: Text(isMr ? 'कार्यकाळ वाढवा (Extend)' : 'Extend Tenure'),
                                onPressed: () => _showExtendTenureModal(context, auth, isMr),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                // Grouping Structure Mode Bar (With strict dues check)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      Icon(isWingWise ? Icons.apartment : Icons.stairs, color: const Color(0xFF1E3A8A), size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMr ? 'व्यवस्थापन रचना:' : 'Grouping Mode:',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            Text(
                              isWingWise
                                  ? (isMr ? '🏢 विंग पद्धत (Wing-wise)' : '🏢 Wing-wise Mode')
                                  : (isMr ? '🏬 मजला पद्धत (Floor-wise)' : '🏬 Floor-wise Mode'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                      if (auth.canManageExpenses)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _toggleGroupingMode(context, auth, society, isMr),
                          child: Text(isMr ? 'पद्धत बदला' : 'Change Mode'),
                        ),
                    ],
                  ),
                ),

                // Transparency Info Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF1D4ED8), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isMr
                              ? 'पारदर्शकता फलक: सर्व सदस्यांना संस्थेतील अधिकृत पदे, चेअरमन, सचिव व विंग/मजला प्रतिनिधींची माहिती येथे दिसते.'
                              : 'Transparency Board: All members can see society designations, Chairman, Secretary, and Wing/Floor collection reps.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Executive Leaders: Chairman & Super Admin
                Text(
                  isMr ? '👑 मुख्य पदाधिकारी (Executive Body)' : '👑 Executive Committee',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryNavy),
                ),
                const SizedBox(height: 10),

                // Chairman Tile
                _buildRoleCard(
                  context: context,
                  title: isMr ? 'चेअरमन / अध्यक्ष (Chairman)' : 'Chairman / President',
                  badgeColor: const Color(0xFF1E3A8A),
                  user: chairman,
                  defaultName: isMr ? 'चेअरमन नियुक्त नाही' : 'No Chairman Appointed',
                  isMr: isMr,
                  canEdit: auth.canManageExpenses,
                  onAssign: () => _showAssignRoleDialog(context, 'chairman', isMr ? 'चेअरमन' : 'Chairman', members, isMr),
                ),
                const SizedBox(height: 10),

                // Super Admin (Secretary) Tile
                _buildRoleCard(
                  context: context,
                  title: isMr ? 'सुपर ॲडमिन (सचिव / Secretary)' : 'Super Admin (Secretary)',
                  badgeColor: const Color(0xFF0D9488),
                  user: superAdmin,
                  defaultName: isMr ? 'सुपर ॲडमिन नियुक्त नाही' : 'No Super Admin Appointed',
                  isMr: isMr,
                  canEdit: auth.canManageExpenses,
                  onAssign: () => _showAppointSuperAdminDialog(context, society, members, isMr),
                  extraSubtitle: society.superAdminNextDueDate != null
                      ? '${isMr ? "कार्यकाळ मुदत तारीख" : "Term Due Date"}: ${AppDateFormatter.formatDate(society.superAdminNextDueDate!, isMarathi: isMr)} (${society.superAdminTermMonths} ${isMr ? "महिन्यांसाठी" : "months"})'
                      : null,
                ),
                const SizedBox(height: 24),

                // 2. Group Admins (Wing or Floor Collection Representatives)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isWingWise
                          ? (isMr ? '🏢 विंग प्रतिनिधी (Wing Group Admins)' : '🏢 Wing Group Admins')
                          : (isMr ? '🏢 मजला प्रतिनिधी (Floor Group Admins)' : '🏢 Floor Group Admins'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryNavy),
                    ),
                    if (auth.canManageExpenses)
                      TextButton.icon(
                        icon: const Icon(Icons.add_circle, size: 16),
                        label: Text(isMr ? 'नवीन प्रतिनिधी जोडा' : 'Assign Rep', style: const TextStyle(fontSize: 12)),
                        onPressed: () => _showAssignGroupAdminDialog(context, society, members, isMr),
                      ),
                  ],
                ),
                Text(
                  isMr
                      ? 'हे पद फक्त विंग/मजल्याचे मेंटेनन्स कलेक्शन करण्यापुरते मर्यादित आहे.'
                      : 'This post is strictly for maintenance collection of respective wing/floor.',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),

                if (groupAdmins.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        isMr ? 'कोणताही ग्रुप ॲडमिन नियुक्त केलेला नाही.' : 'No group admins appointed yet.',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  )
                else
                  ...groupAdmins.map(
                    (ga) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: Icon(isWingWise ? Icons.apartment : Icons.layers, color: AppTheme.primaryNavy),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(4)),
                                      child: Text(
                                        ga.assignedGroup ?? (isMr ? 'गट' : 'Group'),
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isMr ? ga.nameMr : ga.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${isMr ? "फ्लॅट क्र." : "Flat"}: ${ga.flatNumber} • ${ga.phoneNumber.isNotEmpty ? ga.phoneNumber : ga.email}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          if (auth.canManageExpenses)
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                              onPressed: () => _showAssignGroupAdminDialog(context, society, members, isMr, defaultUser: ga),
                            ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // 3. All Society Members Count
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMr ? 'एकूण नोंदणीकृत सभासद संख्या:' : 'Total Registered Members:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        '${members.length} / ${society.totalFlats} ${isMr ? "फ्लॅट्स" : "flats"}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required Color badgeColor,
    required AppUser? user,
    required String defaultName,
    required bool isMr,
    required bool canEdit,
    required VoidCallback onAssign,
    String? extraSubtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: badgeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(title, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              if (canEdit)
                TextButton(
                  onPressed: onAssign,
                  child: Text(isMr ? 'बदला / नियुक्त करा' : 'Change / Appoint', style: const TextStyle(fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (user != null) ...[
            Text(
              isMr ? user.nameMr : user.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
            ),
            const SizedBox(height: 2),
            Text(
              '${isMr ? "फ्लॅट क्र." : "Flat"}: ${user.flatNumber} (${user.wing}) • 📞 ${user.phoneNumber.isNotEmpty ? user.phoneNumber : user.email}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            if (extraSubtitle != null) ...[
              const SizedBox(height: 4),
              Text(extraSubtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
            ],
          ] else ...[
            Text(defaultName, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  void _showAppointSuperAdminDialog(BuildContext context, SocietyModel society, List<AppUser> members, bool isMr) {
    String? selectedUid = members.firstOrNull?.uid;
    int termMonths = society.superAdminTermMonths;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(isMr ? 'नवीन सुपर ॲडमिन (सचिव) नियुक्ती' : 'Appoint New Super Admin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMr
                    ? 'सोसायटीतील सभासदांपैकी पुढील व्यक्तीला सुपर ॲडमिन पदावर नियुक्त करा:'
                    : 'Select a member to appoint as the new Super Admin (Secretary):',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedUid,
                decoration: InputDecoration(
                  labelText: isMr ? 'सभासद निवडा' : 'Select Member',
                  border: const OutlineInputBorder(),
                ),
                items: members
                    .map((m) => DropdownMenuItem(
                          value: m.uid,
                          child: Text('${isMr ? m.nameMr : m.name} (${m.flatNumber})', overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => selectedUid = val),
              ),
              const SizedBox(height: 14),
              Text(isMr ? 'कार्यकाळ मुदत (Tenure)' : 'Tenure Term', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: termMonths,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: 1, child: Text(isMr ? '१ महिना (1 Month)' : '1 Month')),
                  DropdownMenuItem(value: 3, child: Text(isMr ? '३ महिने (3 Months)' : '3 Months')),
                  DropdownMenuItem(value: 6, child: Text(isMr ? '६ महिने (6 Months)' : '6 Months')),
                  DropdownMenuItem(value: 12, child: Text(isMr ? '१ वर्ष (12 Months)' : '1 Year')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => termMonths = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(isMr ? 'रद्द' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
              onPressed: () async {
                if (selectedUid == null) return;
                await FirestoreService.instance.appointNewSuperAdmin(
                  societyId: society.id,
                  newSuperAdminUid: selectedUid!,
                  termMonths: termMonths,
                  appointedByUid: society.adminUid,
                );
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isMr ? 'नवीन सुपर ॲडमिन यशस्वीरीत्या नियुक्त झाले!' : 'New Super Admin appointed!')),
                  );
                }
              },
              child: Text(isMr ? 'नियुक्त करा' : 'Appoint'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignRoleDialog(BuildContext context, String role, String roleTitle, List<AppUser> members, bool isMr) {
    String? selectedUid = members.firstOrNull?.uid;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(isMr ? '$roleTitle नियुक्ती' : 'Assign $roleTitle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedUid,
                decoration: InputDecoration(
                  labelText: isMr ? 'सभासद निवडा' : 'Select Member',
                  border: const OutlineInputBorder(),
                ),
                items: members
                    .map((m) => DropdownMenuItem(
                          value: m.uid,
                          child: Text('${isMr ? m.nameMr : m.name} (${m.flatNumber})', overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => selectedUid = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(isMr ? 'रद्द' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
              onPressed: () async {
                if (selectedUid == null) return;
                await FirestoreService.instance.assignMemberRole(
                  uid: selectedUid!,
                  role: role,
                  designation: roleTitle,
                );
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isMr ? '$roleTitle यशस्वीपणे नियुक्त झाले!' : '$roleTitle assigned!')),
                  );
                }
              },
              child: Text(isMr ? 'नियुक्त करा' : 'Assign'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignGroupAdminDialog(
    BuildContext context,
    SocietyModel society,
    List<AppUser> members,
    bool isMr, {
    AppUser? defaultUser,
  }) {
    String? selectedUid = defaultUser?.uid ?? members.firstOrNull?.uid;
    final isWingWise = society.isWingWise;
    final groupController = TextEditingController(text: defaultUser?.assignedGroup ?? (isWingWise ? 'Wing A' : '1st Floor'));

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(isMr ? 'ग्रुप ॲडमिन (कलेक्शन प्रतिनिधी) नियुक्ती' : 'Assign Group Admin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMr
                    ? 'हा प्रतिनिधी फक्त दिलेल्या विंग/मजल्याचे मेंटेनन्स कलेक्शन करेल:'
                    : 'This representative will only collect maintenance for this wing/floor:',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedUid,
                decoration: InputDecoration(
                  labelText: isMr ? 'सभासद निवडा' : 'Select Member',
                  border: const OutlineInputBorder(),
                ),
                items: members
                    .map((m) => DropdownMenuItem(
                          value: m.uid,
                          child: Text('${isMr ? m.nameMr : m.name} (${m.flatNumber})', overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => selectedUid = val),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: groupController,
                decoration: InputDecoration(
                  labelText: isWingWise ? (isMr ? 'विंगचे नाव (उदा. Wing A)' : 'Wing Name') : (isMr ? 'मजल्याचे नाव (उदा. 1st Floor)' : 'Floor Name'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text(isMr ? 'रद्द' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
              onPressed: () async {
                if (selectedUid == null) return;
                final groupName = groupController.text.trim();
                await FirestoreService.instance.assignMemberRole(
                  uid: selectedUid!,
                  role: 'group_admin',
                  assignedGroup: groupName,
                  designation: isMr ? '$groupName प्रतिनिधी (कलेक्शन)' : '$groupName Rep (Collection)',
                );
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isMr ? 'ग्रुप ॲडमिन यशस्वीपणे नियुक्त झाले!' : 'Group admin assigned!')),
                  );
                }
              },
              child: Text(isMr ? 'नियुक्त करा' : 'Assign'),
            ),
          ],
        ),
      ),
    );
  void _showExtendTenureModal(BuildContext context, AuthProvider auth, bool isMr) {
    int additionalMonths = 3;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isMr ? 'सुपर ॲडमिन कार्यकाळ वाढवा' : 'Extend Super Admin Tenure'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMr ? 'चालू सुपर ॲडमिनची मुदत किती कालावधीने वाढवायची आहे?' : 'Extend current Super Admin term by:',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: additionalMonths,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: [
                  DropdownMenuItem(value: 1, child: Text(isMr ? '१ महिना (1 Month)' : '1 Month')),
                  DropdownMenuItem(value: 3, child: Text(isMr ? '३ महिने (3 Months)' : '3 Months')),
                  DropdownMenuItem(value: 6, child: Text(isMr ? '६ महिने (6 Months)' : '6 Months')),
                  DropdownMenuItem(value: 12, child: Text(isMr ? '१ वर्ष (12 Months)' : '1 Year (12 Months)')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => additionalMonths = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isMr ? 'रद्द करा' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await auth.extendSuperAdminTerm(additionalMonths);
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green,
                      content: Text(isMr ? 'कार्यकाळ यशस्वीरीत्या वाढवण्यात आला!' : 'Tenure extended successfully!'),
                    ),
                  );
                }
              },
              child: Text(isMr ? 'मुदत वाढवा' : 'Extend Term'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleGroupingMode(BuildContext context, AuthProvider auth, SocietyModel society, bool isMr) async {
    // STRICT RULE: If any dues remain pending, cannot change grouping structure!
    final hasDues = await FirestoreService.instance.hasPendingSocietyDues(society.id);
    if (hasDues) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMr ? '⚠️ थकबाकी शिल्लक आहे!' : 'Outstanding Dues Pending!',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
              ],
            ),
            content: Text(
              isMr
                  ? 'संस्थेतील सर्व मेंटेनन्स देयके (Dues) १००% पूर्ण भरल्याशिवाय व्यवस्थापन गट पद्धत (विंग/मजला) बदलता येणार नाही. कृपया आधी सर्व थकीत बिले वसूल करा.'
                  : 'Management grouping structure (Wing/Floor) cannot be changed while there are unpaid maintenance bills. Please collect all dues first.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isMr ? 'समजले' : 'OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    final newType = society.isWingWise ? 'floor' : 'wing';
    final typeName = newType == 'wing' ? (isMr ? 'विंग पद्धत' : 'Wing-wise') : (isMr ? 'मजला पद्धत' : 'Floor-wise');

    final success = await auth.updateSocietySettings(groupingType: newType);
    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(isMr ? 'व्यवस्थापन रचना बदलून $typeName झाली!' : 'Grouping mode updated to $typeName!'),
        ),
      );
    }
  }
}
