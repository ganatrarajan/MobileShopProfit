import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/used_mobile_repository.dart';
import '../../models/used_mobile.dart';

class AddRepairExpenseModal extends StatefulWidget {
  final UsedMobile mobile;
  final VoidCallback? onExpenseAdded;

  const AddRepairExpenseModal({
    super.key,
    required this.mobile,
    this.onExpenseAdded,
  });

  static Future<bool?> show(BuildContext context, UsedMobile mobile, {VoidCallback? onExpenseAdded}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRepairExpenseModal(
        mobile: mobile,
        onExpenseAdded: onExpenseAdded,
      ),
    );
  }

  @override
  State<AddRepairExpenseModal> createState() => _AddRepairExpenseModalState();
}

class _AddRepairExpenseModalState extends State<AddRepairExpenseModal> {
  final _formKey = GlobalKey<FormState>();
  final _costController = TextEditingController();
  final _detailsController = TextEditingController();
  final UsedMobileRepository _repo = UsedMobileRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.mobile.repairCost > 0) {
      _costController.text = widget.mobile.repairCost.toStringAsFixed(0);
    }
    if (widget.mobile.repairDetails != null) {
      _detailsController.text = widget.mobile.repairDetails!;
    }
  }

  @override
  void dispose() {
    _costController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  double get _enteredCost => double.tryParse(_costController.text.trim()) ?? 0.0;
  double get _newTotalInvestment => widget.mobile.purchasePrice + _enteredCost;

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _repo.addRepairExpense(
      widget.mobile.id,
      _enteredCost,
      _detailsController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result.success) {
      if (!mounted) return;
      Navigator.pop(context, true);
      widget.onExpenseAdded?.call();
      AppFeedback.showSuccess(
        context,
        title: '🔧 Repair Logged',
        message: result.message.isNotEmpty ? result.message : 'Repair expense added successfully.',
      );
    } else {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        title: '❌ Failed to Log Repair',
        message: result.message.isNotEmpty ? result.message : 'Failed to save repair cost. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 50),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardPadding),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.build_circle_rounded, color: Colors.orange, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Log Repair / Refurbish Cost',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Device: ${widget.mobile.deviceDisplayName}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Investment Breakdown Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Purchase Price', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text('₹${widget.mobile.purchasePrice.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Text('+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                      Column(
                        children: [
                          const Text('Repair Expense', style: TextStyle(fontSize: 11, color: Colors.orange)),
                          const SizedBox(height: 2),
                          Text('₹${_enteredCost.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                      const Text('=', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                      Column(
                        children: [
                          const Text('Total Investment', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                          const SizedBox(height: 2),
                          Text('₹${_newTotalInvestment.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: _costController,
                  label: 'Repair / Parts Cost (₹) *',
                  hint: 'e.g. 1500 for Display or Battery',
                  prefixIcon: Icons.currency_rupee_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter repair cost';
                    final n = double.tryParse(val.trim());
                    if (n == null || n < 0) return 'Enter valid amount';
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                CustomTextField(
                  controller: _detailsController,
                  label: 'Repair Description / Parts Used',
                  hint: 'e.g. New OG Display + Battery Replacement',
                  prefixIcon: Icons.build_rounded,
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                CustomButton(
                  text: _isLoading ? 'Saving...' : 'Save Repair Expense',
                  icon: Icons.check_rounded,
                  isLoading: _isLoading,
                  backgroundColor: Colors.orange.shade700,
                  onPressed: _isLoading ? null : _submitExpense,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

