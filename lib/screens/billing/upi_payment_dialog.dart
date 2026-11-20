import 'package:flutter/material.dart';
import '../../models/maintenance_bill_model.dart';
import '../../widgets/dynamic_qr_widget.dart';

class UpiPaymentDialog extends StatelessWidget {
  final MaintenanceBill bill;

  const UpiPaymentDialog({super.key, required this.bill});

  static Future<void> show(BuildContext context, MaintenanceBill bill) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UpiPaymentDialog(bill: bill),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          DynamicQrWidget(
            bill: bill,
            onPaymentCompleted: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment verified! Receipt is ready for download.'),
                  backgroundColor: Color(0xFF16A34A),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
