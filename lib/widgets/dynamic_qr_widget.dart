import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/maintenance_bill_model.dart';
import '../providers/billing_provider.dart';
import '../l10n/language_provider.dart';
import '../services/upi_payment_service.dart';
import '../utils/date_formatter.dart';

class DynamicQrWidget extends StatelessWidget {
  final MaintenanceBill bill;
  final VoidCallback onPaymentCompleted;

  const DynamicQrWidget({
    super.key,
    required this.bill,
    required this.onPaymentCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final billingProvider = Provider.of<BillingProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final upiPayload = billingProvider.getDynamicUpiQrPayload(bill);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lang.tr('flat')} ${bill.flatNumber}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                  Text(
                    '${AppDateFormatter.getMonthName(bill.billMonth, isMarathi: lang.isMarathi)} ${bill.billYear}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppDateFormatter.formatCurrency(bill.totalAmount),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dynamic QR Code Rendering
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: QrImageView(
              data: upiPayload,
              version: QrVersions.auto,
              size: 200.0,
              gapless: true,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF1E3A8A),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            lang.tr('scanQrCode'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),

          // Copy UPI ID Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'UPI ID: shivajiparkchs@sbi',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16, color: Color(0xFF1E3A8A)),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: 'shivajiparkchs@sbi'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Society UPI ID copied to clipboard!')),
                  );
                },
                tooltip: 'Copy UPI ID',
              ),
            ],
          ),

          const Divider(height: 24),

          // Direct UPI App Launch Buttons (Google Pay, PhonePe, Paytm)
          Text(
            lang.tr('orChooseUpiApp'),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildUpiAppButton(
                context: context,
                label: 'GPay',
                color: const Color(0xFF4285F4),
                icon: Icons.account_balance_wallet,
                onTap: () => _handleUpiLaunch(context, billingProvider, upiPayload, 'gpay'),
              ),
              _buildUpiAppButton(
                context: context,
                label: 'PhonePe',
                color: const Color(0xFF5F259F),
                icon: Icons.flash_on,
                onTap: () => _handleUpiLaunch(context, billingProvider, upiPayload, 'phonepe'),
              ),
              _buildUpiAppButton(
                context: context,
                label: 'Paytm',
                color: const Color(0xFF002970),
                icon: Icons.payments,
                onTap: () => _handleUpiLaunch(context, billingProvider, upiPayload, 'paytm'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Simulation / Instant Verify Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: billingProvider.isProcessingPayment
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.verified, size: 18),
              label: Text(
                billingProvider.isProcessingPayment ? lang.tr('loading') : '${lang.tr('confirm')} ${lang.tr('paymentSuccess')}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
              ),
              onPressed: billingProvider.isProcessingPayment
                  ? null
                  : () async {
                      await billingProvider.processPayment(
                        billId: bill.id,
                        paymentMode: 'UPI Instant Verification',
                        utrRef: 'UPI-REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                      );
                      onPaymentCompleted();
                    },
            ),
          ),

          const SizedBox(height: 8),
          Text(
            lang.tr('upiNotice'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiAppButton({
    required BuildContext context,
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUpiLaunch(
    BuildContext context,
    BillingProvider provider,
    String uri,
    String app,
  ) async {
    final launched = await UpiPaymentService.launchUpiPayment(
      upiUri: uri,
      preferredApp: app,
    );

    if (!launched && context.mounted) {
      // In simulator or web, notify user and provide immediate simulation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$app UPI app not installed on device. You can verify payment with the button below.'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
