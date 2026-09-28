import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/purchase_repository.dart';
import '../models/purchase.dart';

class RecordPurchasePaymentDialog extends StatefulWidget {
  final Purchase purchase;

  const RecordPurchasePaymentDialog({
    super.key,
    required this.purchase,
  });

  static Future<bool?> show(BuildContext context, Purchase purchase) {
    return showDialog<bool>(
      context: context,
      builder: (_) => RecordPurchasePaymentDialog(purchase: purchase),
    );
  }

  @override
  State<RecordPurchasePaymentDialog> createState() => _RecordPurchasePaymentDialogState();
}

class _RecordPurchasePaymentDialogState extends State<RecordPurchasePaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  DateTime _paymentDate = DateTime.now();
  String _paymentMethod = 'cash';
  bool _isLoading = false;
  final PurchaseRepository _repository = PurchaseRepository();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.purchase.outstandingAmount.toStringAsFixed(2),
    );
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payment amount.')),
      );
      return;
    }

    if (amount > widget.purchase.outstandingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Amount paid cannot exceed outstanding balance (?${widget.purchase.outstandingAmount.toStringAsFixed(2)}).'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await _repository.recordPurchasePayment(
      purchaseId: widget.purchase.id,
      amount: amount,
      paymentDate: _paymentDate.toIso8601String().split('T')[0],
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (response.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('? Payment Recorded. ?${amount.toStringAsFixed(2)} payment recorded successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message.isNotEmpty ? response.message : 'Failed to record payment.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Add Payment for #${widget.purchase.purchaseNumber}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        Text('?${widget.purchase.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Already Paid:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        Text('?${widget.purchase.amountPaid.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Outstanding:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('?${widget.purchase.outstandingAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _amountController,
                label: 'Payment Amount (?) *',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter payment amount.';
                  final amt = double.tryParse(val.trim());
                  if (amt == null || amt <= 0) return 'Enter a valid payment amount.';
                  if (amt > widget.purchase.outstandingAmount) return 'Amount cannot exceed outstanding balance.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'online', child: Text('Online / UPI')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _paymentMethod = val);
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'e.g. Reference / Transaction ID',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save Payment', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}


