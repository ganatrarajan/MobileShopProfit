import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/expense_repository.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';

import '../../subscription/utils/subscription_guard.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddEditExpenseScreen({super.key, this.expense});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _refNumberController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<ExpenseCategory> _categories = [];
  ExpenseCategory? _selectedCategory;
  bool _isLoadingCategories = true;

  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = 'cash';
  bool _isRecurring = false;
  String _recurrenceType = 'monthly';

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _fetchCategories();

    if (_isEditing) {
      final exp = widget.expense!;
      _titleController.text = exp.title;
      _amountController.text = exp.amount.toString();
      _refNumberController.text = exp.referenceNumber ?? '';
      _notesController.text = exp.notes ?? '';
      _paymentMethod = exp.paymentMethod;
      _isRecurring = exp.isRecurring;
      _recurrenceType = exp.recurrenceType ?? 'monthly';
      if (exp.expenseDate.isNotEmpty) {
        _selectedDate = DateTime.tryParse(exp.expenseDate) ?? DateTime.now();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted && !_isEditing) {
        final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'create expenses');
        if (!ok && mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _refNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final res = await _expenseRepository.getExpenseCategories();
      if (mounted) {
        if (res.success && res.data != null) {
          setState(() {
            _categories = res.data!;
            _isLoadingCategories = false;

            if (_isEditing) {
              final expCatId = widget.expense!.categoryId;
              _selectedCategory = _categories.firstWhere(
                (c) => c.id == expCatId,
                orElse: () => _categories.first,
              );
            } else if (_categories.isNotEmpty) {
              _selectedCategory = _categories.first;
            }
          });
        } else {
          setState(() => _isLoadingCategories = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _showAddCustomCategoryDialog() async {
    final nameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final createdCategory = await showDialog<ExpenseCategory>(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        String? errorMsg;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Add Custom Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMsg != null) ...[
                      Text(errorMsg!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                      const SizedBox(height: 8),
                    ],
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category Name *',
                        hintText: 'e.g. Tea & Snacks, License',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter category name' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() {
                            isSaving = true;
                            errorMsg = null;
                          });

                          final res = await _expenseRepository.createExpenseCategory(nameCtrl.text.trim());
                          if (ctx.mounted) {
                            if (res.success && res.data != null) {
                              Navigator.pop(ctx, res.data);
                            } else {
                              setDialogState(() {
                                isSaving = false;
                                errorMsg = res.message;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (createdCategory != null) {
      await _fetchCategories();
      setState(() {
        _selectedCategory = _categories.firstWhere((c) => c.id == createdCategory.id, orElse: () => createdCategory);
      });
    }
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      setState(() => _errorMessage = 'Please select an expense category.');
      return;
    }

    final amt = double.tryParse(_amountController.text.trim());
    if (amt == null || amt <= 0) {
      setState(() => _errorMessage = 'Amount must be greater than 0.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final formattedDate = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    try {
      if (_isEditing) {
        final res = await _expenseRepository.updateExpense(
          widget.expense!.id,
          categoryId: _selectedCategory!.id,
          title: _titleController.text.trim(),
          amount: amt,
          expenseDate: formattedDate,
          paymentMethod: _paymentMethod,
          referenceNumber: _refNumberController.text.trim(),
          notes: _notesController.text.trim(),
          isRecurring: _isRecurring,
          recurrenceType: _isRecurring ? _recurrenceType : null,
        );

        if (mounted) {
          if (res.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Expense updated successfully!'), backgroundColor: Colors.green.shade700),
            );
            Navigator.pop(context, true);
          } else {
            setState(() {
              _errorMessage = res.message;
              _isSubmitting = false;
            });
          }
        }
      } else {
        final res = await _expenseRepository.createExpense(
          categoryId: _selectedCategory!.id,
          title: _titleController.text.trim(),
          amount: amt,
          expenseDate: formattedDate,
          paymentMethod: _paymentMethod,
          referenceNumber: _refNumberController.text.trim(),
          notes: _notesController.text.trim(),
          isRecurring: _isRecurring,
          recurrenceType: _isRecurring ? _recurrenceType : null,
        );

        if (mounted) {
          if (res.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Expense recorded successfully!'), backgroundColor: Colors.green.shade700),
            );
            Navigator.pop(context, true);
          } else {
            setState(() {
              _errorMessage = res.message;
              _isSubmitting = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(8)),
                  child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
                const SizedBox(height: 14),
              ],

              // Expense Details Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Expense Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 14),

                    // Category Selector
                    Row(
                      children: [
                        Expanded(
                          child: _isLoadingCategories
                              ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                              : DropdownButtonFormField<ExpenseCategory>(
                                  value: _selectedCategory,
                                  decoration: InputDecoration(
                                    labelText: 'Category *',
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  items: _categories.map((cat) {
                                    return DropdownMenuItem<ExpenseCategory>(
                                      value: cat,
                                      child: Text(cat.name, style: const TextStyle(fontSize: 14)),
                                    );
                                  }).toList(),
                                  onChanged: (cat) => setState(() => _selectedCategory = cat),
                                ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28),
                          tooltip: 'Add Custom Category',
                          onPressed: _showAddCustomCategoryDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Title
                    CustomTextField(
                      label: 'Title *',
                      hint: 'e.g. August Electricity Bill, Shop Rent',
                      controller: _titleController,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter expense title' : null,
                    ),
                    const SizedBox(height: 14),

                    // Amount & Date Row
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Amount (₹) *',
                            hint: 'e.g. 4850',
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter amount';
                              final d = double.tryParse(val.trim());
                              if (d == null || d <= 0) return 'Amount > 0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setState(() => _selectedDate = picked);
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date *',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                              ),
                              child: Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Payment & Reference Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPaymentChip('cash', 'Cash', Icons.payments_rounded),
                        _buildPaymentChip('upi', 'UPI', Icons.qr_code_2_rounded),
                        _buildPaymentChip('bank_transfer', 'Bank', Icons.account_balance_rounded),
                        _buildPaymentChip('card', 'Card', Icons.credit_card_rounded),
                        _buildPaymentChip('other', 'Other', Icons.more_horiz_rounded),
                      ],
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Reference Number (Optional)',
                      hint: 'e.g. Transaction ID, Check #, Invoice #',
                      controller: _refNumberController,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Notes / Remarks (Optional)',
                      hint: 'Add extra details...',
                      controller: _notesController,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Recurring Expense Foundation Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Recurring Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Flag as regular repeating cost (Rent, Internet, Salary)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      value: _isRecurring,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _isRecurring = val),
                    ),
                    if (_isRecurring) ...[
                      const Divider(),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          const Text('Recurrence Frequency:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ChoiceChip(
                                label: const Text('Monthly'),
                                selected: _recurrenceType == 'monthly',
                                onSelected: (sel) => setState(() => _recurrenceType = 'monthly'),
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(color: _recurrenceType == 'monthly' ? Colors.white : AppColors.textPrimary, fontSize: 12),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Yearly'),
                                selected: _recurrenceType == 'yearly',
                                onSelected: (sel) => setState(() => _recurrenceType = 'yearly'),
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(color: _recurrenceType == 'yearly' ? Colors.white : AppColors.textPrimary, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              CustomButton(
                text: _isEditing ? 'Update Expense' : 'Save Expense',
                isLoading: _isSubmitting,
                onPressed: _submitExpense,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentChip(String value, String label, IconData icon) {
    final isSelected = _paymentMethod == value;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primary),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _paymentMethod = value);
      },
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
    );
  }
}
