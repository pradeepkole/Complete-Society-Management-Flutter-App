import '../models/user_model.dart';
import '../models/society_model.dart';
import '../models/maintenance_bill_model.dart';
import '../models/ledger_entry_model.dart';
import '../models/notice_model.dart';
import '../models/complaint_model.dart';
import '../models/visitor_model.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();
  FirebaseService._internal();

  final List<AppUser> users = [];
  final List<MaintenanceBill> bills = [];
  final List<LedgerEntry> ledger = [];
  final List<NoticeModel> notices = [];
  final List<ComplaintModel> complaints = [];
  final List<VisitorModel> visitors = [];
}
