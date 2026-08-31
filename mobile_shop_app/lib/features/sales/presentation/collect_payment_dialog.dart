import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/sale_repository.dart';
import '../models/sale.dart';

class CollectPaymentDialog extends StatefulWidget {
  final Sale sale;
  const CollectPaymentDialog({super.key, required this.sale});

  @override
  State<CollectPaymentDialog> createState() => _CollectPaymentDialogState();
}

class _CollectPaymentDialogState extends State<CollectPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _saleRepository = SaleRepository();

  String _paymentMethod = 'cash';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.sale.amountDue.toStringAsFixed(2);
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

    if (amount > widget.sale.amountDue) {
      setState(() => _errorMessage = 'Amount cannot exceed remaining due (₹${widget.sale.amountDue.toStringAsFixed(2)}).');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _saleRepository.collectPayment(
        saleId: widget.sale.id,
        amount: amount,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        if (response.success && response.data != null) {
          Navigator.pop(context, response.data);
        } else {
          setState(() => _errorMessage = response.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.payments_rounded, color: AppColors.accent, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Collect Payment',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Invoice: ${widget.sale.invoiceNumber}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Remaining Due:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      Text(
                        '₹ ${widget.sale.amountDue.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade900),
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
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                CustomTextField(
                  label: 'Collecting Amount (₹)',
                  hint: 'Enter amount',
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.currency_rupee_rounded,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter amount';
                    final num = double.tryParse(val);
                    if (num == null || num <= 0) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'Payment Method',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI / GPay / PhonePe')),
                    DropdownMenuItem(value: 'card', child: Text('Credit / Debit Card')),
                    DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _paymentMethod = val);
                  },
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Payment Notes (Optional)',
                  hint: 'e.g. Received via GPay, Ref #12345',
                  controller: _notesController,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Record Payment',
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
