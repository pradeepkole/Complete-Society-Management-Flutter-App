import 'package:url_launcher/url_launcher.dart';

class UpiPaymentService {
  /// Builds the standard NPCI UPI Intent URI
  /// Format: upi://pay?pa={upiId}&pn={merchantName}&am={amount}&cu=INR&tn={note}&tr={referenceId}
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
    required String upiUri,
    String? preferredApp, // 'gpay', 'phonepe', 'paytm'
  }) async {
    String finalUri = upiUri;

    if (preferredApp != null) {
      if (preferredApp == 'phonepe') {
        finalUri = upiUri.replaceFirst('upi://', 'phonepe://');
      } else if (preferredApp == 'paytm') {
        finalUri = upiUri.replaceFirst('upi://', 'paytmmp://');
      }
    }

    final uri = Uri.parse(finalUri);

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to generic upi://
        final genericUri = Uri.parse(upiUri);
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
