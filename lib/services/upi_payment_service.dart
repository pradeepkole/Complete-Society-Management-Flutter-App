import 'package:url_launcher/url_launcher.dart';

class UpiPaymentService {
  /// Builds the standard NPCI UPI Intent URI
  static String generateUpiUri({
    required String upiId,
    required String merchantName,
    required double amount,
    required String billId,
    required String flatNumber,
    required String monthYear,
  }) {
    final cleanUpiId = Uri.encodeComponent(upiId);
    final cleanName = Uri.encodeComponent(merchantName);
    final formattedAmount = amount.toStringAsFixed(2);
    final note = Uri.encodeComponent('Maintenance $flatNumber for $monthYear');
    final transactionRef = Uri.encodeComponent(billId);

    return 'upi://pay?pa=$cleanUpiId&pn=$cleanName&am=$formattedAmount&cu=INR&tn=$note&tr=$transactionRef';
  }

  /// Launch the general UPI Intent or specific app intent
  static Future<bool> launchUpiPayment({
    String? upiUri,
    String? payeeVpa,
    String? payeeName,
    String? transactionNote,
    double? amount,
    String? preferredApp,
  }) async {
    String finalUri = upiUri ?? '';

    if (finalUri.isEmpty && payeeVpa != null) {
      final cleanUpiId = Uri.encodeComponent(payeeVpa);
      final cleanName = Uri.encodeComponent(payeeName ?? '');
      final formattedAmount = (amount ?? 0.0).toStringAsFixed(2);
      final note = Uri.encodeComponent(transactionNote ?? 'Society Maintenance');
      finalUri = 'upi://pay?pa=$cleanUpiId&pn=$cleanName&am=$formattedAmount&cu=INR&tn=$note';
    }

    if (preferredApp != null) {
      if (preferredApp == 'phonepe') {
        finalUri = finalUri.replaceFirst('upi://', 'phonepe://');
      } else if (preferredApp == 'paytm') {
        finalUri = finalUri.replaceFirst('upi://', 'paytmmp://');
      }
    }

    final uri = Uri.parse(finalUri);

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final genericUri = Uri.parse(finalUri.startsWith('upi://') ? finalUri : 'upi://${uri.path}');
        if (await canLaunchUrl(genericUri)) {
          return await launchUrl(genericUri, mode: LaunchMode.externalApplication);
        }
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
