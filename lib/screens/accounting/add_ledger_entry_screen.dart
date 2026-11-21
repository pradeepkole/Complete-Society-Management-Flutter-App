import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/accounting_provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/language_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_app_bar.dart';

class AddLedgerEntryScreen extends StatefulWidget {
  final String initialType; // 'expense' or 'income'

  const AddLedgerEntryScreen({super.key, this.initialType = 'expense'});

  @override
  State<AddLedgerEntryScreen> createState() => _AddLedgerEntryScreenState();
}

class _AddLedgerEntryScreenState extends State<AddLedgerEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  late String _category;
  String _paymentMode = 'bank'; // 'bank', 'cash', 'upi'
  final _titleEnController = TextEditingController();
  final _titleMrController = TextEditingController();
  final _amountController = TextEditingController();
  final _voucherController = TextEditingController();
  final _vendorController = TextEditingController();
  final _notesController = TextEditingController();
  String _attachmentUrl = '';
  Uint8List? _pickedFileBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _category = _type == 'expense'
        ? AppConstants.expenseCategories.first
        : AppConstants.incomeCategories.first;
    _voucherController.text = '${_type == 'expense' ? 'PV' : 'RV'}-${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final accounting = Provider.of<AccountingProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    final isExpense = _type == 'expense';
    final categories = isExpense ? AppConstants.expenseCategories : AppConstants.incomeCategories;

    if (!auth.canManageExpenses) {
      return Scaffold(
        appBar: CustomAppBar(title: lang.tr('recordExpense')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 50, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  lang.isMarathi
                      ? 'खर्च नोंदवण्याचा अधिकार फक्त सुपर ॲडमिन (सचिव) आणि चेअरमन यांनाच आहे.'
                      : 'Expense recording is restricted to Super Admin and Chairman only.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: isExpense ? lang.tr('recordExpense') : lang.tr('recordIncome'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Toggle
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          lang.tr('recordExpense'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isExpense ? Colors.white : Colors.red.shade800,
                          ),
                        ),
                      ),
                      selected: isExpense,
                      selectedColor: const Color(0xFFDC2626),
                      onSelected: (val) {
                        setState(() {
                          _type = 'expense';
                          _category = AppConstants.expenseCategories.first;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          lang.tr('recordIncome'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !isExpense ? Colors.white : Colors.green.shade800,
                          ),
                        ),
                      ),
                      selected: !isExpense,
                      selectedColor: const Color(0xFF16A34A),
                      onSelected: (val) {
                        setState(() {
                          _type = 'income';
                          _category = AppConstants.incomeCategories.first;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Category Dropdown
              Text(lang.tr('category'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _category,
                isExpanded: true,
                items: categories.map((catKey) {
                  return DropdownMenuItem(
                    value: catKey,
                    child: Text(lang.tr(catKey), style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 16),

              // Title in English & Marathi
              Text(
                lang.isMarathi ? 'खर्च/जमेचे शीर्षक (English)' : 'Title (English)',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleEnController,
                decoration: const InputDecoration(hintText: 'e.g. Lift AMC Service Quarter 3'),
                validator: (val) => val == null || val.isEmpty ? lang.tr('required') : null,
              ),
              const SizedBox(height: 12),

              Text(
                lang.isMarathi ? 'खर्च/जमेचे शीर्षक (मराठी)' : 'Title (Marathi)',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleMrController,
                decoration: const InputDecoration(hintText: 'उदा. ओटिस लिफ्ट त्रैमासिक देखभाल'),
              ),
              const SizedBox(height: 16),

              // Amount & Voucher
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${lang.tr('amount')} (₹)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'e.g. 12500'),
                          validator: (val) => val == null || val.isEmpty ? lang.tr('required') : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lang.tr('voucherNo'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _voucherController,
                          decoration: const InputDecoration(hintText: 'PV-01'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Payment Mode (Cash / Bank / UPI)
              Text(lang.tr('paymentMode'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPaymentModeOption('bank', 'Bank Transfer / Cheque', Icons.account_balance),
                  const SizedBox(width: 8),
                  _buildPaymentModeOption('cash', 'Cash (रोख)', Icons.money),
                  const SizedBox(width: 8),
                  _buildPaymentModeOption('upi', 'UPI Online', Icons.qr_code_2),
                ],
              ),
              const SizedBox(height: 16),

              // Vendor / Payee Party Name
              Text(lang.tr('vendorParty'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _vendorController,
                decoration: const InputDecoration(hintText: 'e.g. Otis Elevators India / MSEDCL'),
              ),
              const SizedBox(height: 16),

              // Upload / Attach Physical Bill Document (Audit requirement)
              Text(lang.tr('uploadBillPhoto'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.attachment, color: Colors.blue.shade800),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _attachmentUrl.isNotEmpty
                                ? 'Physical voucher scan attached (Ready for Audit)'
                                : 'Attach paper receipt/tax invoice scan for audit proof',
                            style: TextStyle(
                              fontSize: 12,
                              color: _attachmentUrl.isNotEmpty ? Colors.green.shade800 : Colors.grey.shade700,
                              fontWeight: _attachmentUrl.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.camera_alt, size: 16),
                          label: const Text('Attach', style: TextStyle(fontSize: 11)),
                          onPressed: () async {
                            try {
                              final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                              if (image != null) {
                                final bytes = await image.readAsBytes();
                                setState(() {
                                  _pickedFileBytes = bytes;
                                  _attachmentUrl = image.name;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Voucher proof document attached! Ready for upload.')),
                                );
                              }
                            } catch (_) {
                              setState(() {
                                _attachmentUrl = 'https://firebasestorage.googleapis.com/v0/b/society-6ad99.firebasestorage.app/o/vouchers%2Fvoucher_sample.jpg?alt=media';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Simulated voucher attached!')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(lang.tr('save')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isExpense ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      await accounting.addLedgerEntry(
                        type: _type,
                        category: _category,
                        title: _titleEnController.text,
                        titleMr: _titleMrController.text.isNotEmpty
                            ? _titleMrController.text
                            : _titleEnController.text,
                        amount: double.tryParse(_amountController.text) ?? 0,
                        paymentMode: _paymentMode,
                        voucherNo: _voucherController.text,
                        vendorName: _vendorController.text,
                        billAttachmentUrl: _attachmentUrl,
                        documentBytes: _pickedFileBytes,
                        recordedByUid: auth.currentUser?.uid ?? 'admin',
                        notes: _notesController.text,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaction recorded in Society Ledger & Storage!')),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentModeOption(String mode, String label, IconData icon) {
    final isSelected = _paymentMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryNavy.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primaryNavy : Colors.grey.shade300,
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? AppTheme.primaryNavy : Colors.grey.shade600),
              const SizedBox(height: 2),
              Text(
                mode.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.primaryNavy : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
