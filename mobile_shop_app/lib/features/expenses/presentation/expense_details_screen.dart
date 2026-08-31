import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/expense_repository.dart';
import '../models/expense.dart';

class ExpenseDetailsScreen extends StatefulWidget {
  final Expense expense;

  const ExpenseDetailsScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailsScreen> createState() => _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen> {
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  late Expense _expense;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
    _refreshDetails();
  }

  Future<void> _refreshDetails() async {
    setState(() => _isLoading = true);
    try {
      final res = await _expenseRepository.getExpenseDetails(_expense.id);
      if (mounted) {
        if (res.success && res.data != null) {
          setState(() {
            _expense = res.data!;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDeleteExpense() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
              SizedBox(width: 8),
              Text('Delete Expense'),
            ],
          ),
          content: Text('Are you sure you want to delete expense "${_expense.title}" of ₹${_expense.amount.toStringAsFixed(2)}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final res = await _expenseRepository.deleteExpense(_expense.id);
      if (mounted) {
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Expense "${_expense.title}" deleted successfully.'),
              backgroundColor: Colors.green.shade700,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = _expense.category?.name ?? 'Expense';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Expense Details'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshDetails,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.editExpense,
                arguments: _expense,
              );
              if (result == true) _refreshDetails();
            },
            tooltip: 'Edit Expense',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            onPressed: _confirmDeleteExpense,
            tooltip: 'Delete Expense',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Header Card
                  CustomCard(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                categoryName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            if (_expense.isRecurring)
                              StatusBadge(
                                label: '${_expense.recurrenceType?.toUpperCase() ?? 'RECURRING'}',
                                backgroundColor: Colors.amber.shade900,
                                textColor: Colors.white,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _expense.title,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${_expense.amount.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Recorded on ${_expense.expenseDate}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Information Details Card
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Transaction Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 14),
                        _buildDetailRow(Icons.category_outlined, 'Category', categoryName),
                        const Divider(height: 20),
                        _buildDetailRow(Icons.payment_rounded, 'Payment Method', _expense.paymentMethod.toUpperCase().replaceAll('_', ' ')),
                        if (_expense.referenceNumber != null && _expense.referenceNumber!.isNotEmpty) ...[
                          const Divider(height: 20),
                          _buildDetailRow(Icons.numbers_rounded, 'Reference #', _expense.referenceNumber!),
                        ],
                        if (_expense.creatorName != null && _expense.creatorName!.isNotEmpty) ...[
                          const Divider(height: 20),
                          _buildDetailRow(Icons.person_outline_rounded, 'Created By', _expense.creatorName!),
                        ],
                        if (_expense.notes != null && _expense.notes!.isNotEmpty) ...[
                          const Divider(height: 20),
                          _buildDetailRow(Icons.notes_rounded, 'Notes / Remarks', _expense.notes!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }
}
