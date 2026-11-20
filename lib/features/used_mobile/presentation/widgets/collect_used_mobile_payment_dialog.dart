import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/used_mobile_repository.dart';
import '../../models/used_mobile.dart';

class CollectUsedMobilePaymentDialog extends StatefulWidget {
  final UsedMobile mobile;
  const CollectUsedMobilePaymentDialog({super.key, required this.mobile});

  static Future<UsedMobile?> show(
    BuildContext context, {
    required UsedMobile mobile,
    VoidCallback? onPaymentRecorded,
  }) async {
    final result = await showModalBottomSheet<UsedMobile?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: CollectUsedMobilePaymentDialog(mobile: mobile),
      ),
    );
    if (result != null) {
      onPaymentRecorded?.call();
    }
    return result;
  }

  @override
  State<CollectUsedMobilePaymentDialog> createState() => _CollectUsedMobilePaymentDialogState();
}

class _CollectUsedMobilePaymentDialogState extends State<CollectUsedMobilePaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _repo = UsedMobileRepository();

  String _paymentMethod = 'Cash';
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _paymentMethods = [
    'Cash',
    'UPI / GPay / PhonePe',
    'Debit/Credit Card',
    'Bank Transfer',
  ];

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.mobile.amountDue.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid payment amount.');
      return;
    }

    if (amount > widget.mobile.amountDue + 0.01) {
      setState(() => _errorMessage = 'Amount cannot exceed remaining due (₹${widget.mobile.amountDue.toStringAsFixed(2)}).');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _repo.addPayment(
        id: widget.mobile.id,
        amount: amount,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        if (response.success && response.data != null) {
          Navigator.pop(context, response.data);
        } else {
          setState(() {
            _errorMessage = response.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_card_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Collect Due Payment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${widget.mobile.brand} ${widget.mobile.model} • #${widget.mobile.saleInvoiceNumber ?? widget.mobile.purchaseRefNumber}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Due status summary banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Selling Price', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text('₹${(widget.mobile.sellingPrice ?? 0.0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Paid So Far', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text('₹${widget.mobile.amountPaid.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Remaining Due', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text('₹${widget.mobile.amountDue.toStringAsFixed(2)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.red.shade700)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.error, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                CustomTextField(
                  label: 'Payment Amount (₹) *',
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.currency_rupee_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter amount';
                    final n = double.tryParse(val.trim());
                    if (n == null || n <= 0) return 'Enter a valid amount';
                    if (n > widget.mobile.amountDue + 0.01) {
                      return 'Cannot exceed remaining due of ₹${widget.mobile.amountDue.toStringAsFixed(2)}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                const Text('Payment Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _paymentMethods.map((mode) {
                    final isSelected = _paymentMethod == mode;
                    return ChoiceChip(
                      label: Text(mode),
                      selected: isSelected,
                      onSelected: (sel) {
                        if (sel) setState(() => _paymentMethod = mode);
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'Notes / Remarks (Optional)',
                  hint: 'e.g. Received via GPay from buyer',
                  controller: _notesController,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                CustomButton(
                  text: 'Save Payment',
                  isLoading: _isLoading,
                  onPressed: _submitPayment,
                  icon: Icons.check_circle_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
