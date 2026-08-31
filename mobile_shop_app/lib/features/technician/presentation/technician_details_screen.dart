import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../repair/models/repair.dart';
import '../data/technician_repository.dart';
import '../models/technician.dart';
import '../models/technician_payment.dart';
import 'add_edit_technician_dialog.dart';

class TechnicianDetailsScreen extends StatefulWidget {
  final Technician technician;
  const TechnicianDetailsScreen({super.key, required this.technician});

  @override
  State<TechnicianDetailsScreen> createState() => _TechnicianDetailsScreenState();
}

class _TechnicianDetailsScreenState extends State<TechnicianDetailsScreen> {
  final TechnicianRepository _repository = TechnicianRepository();

  late Technician _tech;
  bool _isLoading = true;
  bool _isLoadingPayments = false;
  String _jobFilter = 'all'; // all, pending, in_progress, completed
  List<TechnicianPayment> _paymentHistory = [];

  @override
  void initState() {
    super.initState();
    _tech = widget.technician;
    _fetchDetails();
    _fetchPaymentHistory();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);

    try {
      final response = await _repository.getTechnicianDetails(_tech.id);

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _tech = response.data!;
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

  Future<void> _fetchPaymentHistory() async {
    setState(() => _isLoadingPayments = true);
    try {
      final res = await _repository.getPaymentHistory(_tech.id);
      if (mounted && res.success && res.data != null) {
        setState(() {
          _paymentHistory = res.data!;
          _isLoadingPayments = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingPayments = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPayments = false);
    }
  }

  Future<void> _showPayTechnicianDialog() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedMethod = 'cash';
    DateTime selectedDate = DateTime.now();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.payments_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Pay ${_tech.name}'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Payable:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(
                        '\u{20B9}${_tech.workload.totalPayable.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Payment Amount (\u{20B9}) *',
                  hint: 'e.g. 1000',
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.currency_rupee_rounded,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration: InputDecoration(
                    labelText: 'Payment Method',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI / GPay / PhonePe')),
                    DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedMethod = val);
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Note / Reference (Optional)',
                  hint: 'e.g. Weekly repair payout',
                  controller: noteController,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Payment'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      final amt = double.tryParse(amountController.text) ?? 0.0;
      final maxPayable = _tech.workload.totalPayable;

      if (amt <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid payment amount'), backgroundColor: Colors.red),
        );
        return;
      }

      if (amt > maxPayable && maxPayable > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment amount (\u{20B9}${amt.toStringAsFixed(2)}) cannot exceed total payable amount (\u{20B9}${maxPayable.toStringAsFixed(2)})'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final res = await _repository.recordPayment(
          technicianId: _tech.id,
          amount: amt,
          paymentDate: selectedDate,
          paymentMethod: selectedMethod,
          notes: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
        );

        if (mounted) {
          if (res.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment recorded successfully!')),
            );
            _fetchDetails();
            _fetchPaymentHistory();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res.message), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _editTechnician() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AddEditTechnicianDialog(technician: _tech),
    );

    if (result == true) {
      _fetchDetails();
    }
  }

  Future<void> _toggleActiveStatus() async {
    final newStatus = !_tech.isActive;
    try {
      final response = await _repository.updateTechnician(
        id: _tech.id,
        isActive: newStatus,
      );

      if (mounted) {
        if (response.success) {
          final statusStr = newStatus ? 'Active' : 'Inactive';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Technician marked as $statusStr')),
          );
          _fetchDetails();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Technician'),
        content: Text('Are you sure you want to delete ${_tech.name}? If they have active repair jobs, deletion will be blocked.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await _repository.deleteTechnician(_tech.id);

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Technician deleted successfully')),
          );
          Navigator.pop(context, true);
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Action Required'),
              content: Text(response.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _toggleActiveStatus();
                  },
                  child: const Text('Deactivate Instead'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Repair> get _filteredJobs {
    final jobs = _tech.recentJobs;
    if (_jobFilter == 'pending') {
      return jobs.where((j) => ['received', 'diagnosing', 'waiting_customer', 'waiting_parts', 'pending_approval'].contains(j.repairStatus)).toList();
    } else if (_jobFilter == 'in_progress') {
      return jobs.where((j) => ['repairing', 'in_progress'].contains(j.repairStatus)).toList();
    } else if (_jobFilter == 'completed') {
      return jobs.where((j) => ['ready', 'delivered'].contains(j.repairStatus)).toList();
    }
    return jobs;
  }

  @override
  Widget build(BuildContext context) {
    final wl = _tech.workload;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_tech.name),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: _editTechnician,
            tooltip: 'Edit Technician',
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'toggle') _toggleActiveStatus();
              if (val == 'delete') _confirmDelete();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(_tech.isActive ? Icons.block_rounded : Icons.check_circle_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(_tech.isActive ? 'Deactivate Technician' : 'Activate Technician'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_rounded, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Delete Technician', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchDetails();
          await _fetchPaymentHistory();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Card with Pay Technician Action
              CustomCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: _tech.isActive ? AppColors.primary : Colors.grey,
                          child: const Icon(Icons.engineering_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _tech.name,
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _tech.isActive ? Colors.green.shade50 : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _tech.isActive ? Colors.green.shade300 : Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      _tech.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _tech.isActive ? Colors.green.shade900 : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _tech.specialization != null && _tech.specialization!.isNotEmpty
                                    ? _tech.specialization!
                                    : 'General Technician',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showPayTechnicianDialog,
                        icon: const Icon(Icons.payments_rounded, size: 18),
                        label: Text('Pay Technician (Payable: \u{20B9}${wl.totalPayable.toStringAsFixed(2)})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Financial Summary Cards (Money)
              const Text(
                'Earnings & Payout Summary',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Earnings',
                      value: '\u{20B9}${wl.totalEarnings.toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Paid',
                      value: '\u{20B9}${wl.totalPaid.toStringAsFixed(2)}',
                      icon: Icons.check_circle_rounded,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Amount Payable',
                      value: '\u{20B9}${wl.totalPayable.toStringAsFixed(2)}',
                      icon: Icons.pending_actions_rounded,
                      color: wl.totalPayable > 0 ? Colors.orange : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Repair Value',
                      value: '\u{20B9}${wl.totalValueHandled.toStringAsFixed(2)}',
                      icon: Icons.build_rounded,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Workload Summary Section (Jobs)
              const Text(
                'Workload Summary',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Pending Jobs',
                      value: '${wl.pendingJobs}',
                      icon: Icons.hourglass_empty_rounded,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'In Progress',
                      value: '${wl.inProgressJobs}',
                      icon: Icons.engineering_rounded,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Completed',
                      value: '${wl.completedJobs}',
                      icon: Icons.task_alt_rounded,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Payment History Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payment History',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  Text(
                    '${_paymentHistory.length} Payments',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_isLoadingPayments)
                const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
              else if (_paymentHistory.isEmpty)
                CustomCard(
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No payout records found yet',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ),
                )
              else
                CustomCard(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: _paymentHistory.map((p) {
                      final formattedDate = p.paymentDate.split('T').first;
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.green.shade50,
                          child: Icon(Icons.call_made_rounded, size: 16, color: Colors.green.shade800),
                        ),
                        title: Text(
                          '\u{20B9}${p.amount.toStringAsFixed(2)} | ${p.paymentMethod.toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(
                          p.notes != null && p.notes!.isNotEmpty
                              ? '$formattedDate - ${p.notes}'
                              : formattedDate,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 20),

              // 5. Assigned Jobs Header & Filters
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Assigned Repair Jobs',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  Text(
                    '${_filteredJobs.length} Jobs',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All'),
                    _buildFilterChip('pending', 'Pending'),
                    _buildFilterChip('in_progress', 'In Progress'),
                    _buildFilterChip('completed', 'Completed'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 6. Jobs List
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_filteredJobs.isEmpty)
                CustomCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.build_circle_outlined, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          const Text(
                            'No repair jobs found for this filter',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredJobs.length,
                  itemBuilder: (context, index) {
                    final repair = _filteredJobs[index];
                    final customerName = repair.customer != null ? repair.customer!.name : 'Customer #${repair.customerId}';
                    final deviceStr = repair.device != null
                        ? '${repair.device!.brand} ${repair.device!.model}'.trim()
                        : 'Mobile Device';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CustomCard(
                        onTap: () async {
                          final res = await Navigator.pushNamed(
                            context,
                            AppRoutes.repairDetails,
                            arguments: repair,
                          );
                          if (res == true) {
                            _fetchDetails();
                            _fetchPaymentHistory();
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  repair.jobNumber.isNotEmpty ? repair.jobNumber : 'JOB-#${repair.id}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                ),
                                _buildStatusBadge(repair.repairStatus),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$customerName | $deviceStr',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              repair.problemDescription,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Earning: \u{20B9}${repair.technicianEarning.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                                Text(
                                  'Payable: \u{20B9}${repair.technicianPayable.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: repair.technicianPayable > 0 ? Colors.orange.shade900 : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _jobFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _jobFilter = key);
        },
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.primary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color.shade900),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color.shade900),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;
    String label = status.replaceAll('_', ' ').toUpperCase();

    if (['received', 'diagnosing', 'waiting_customer', 'waiting_parts', 'pending_approval'].contains(status)) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade900;
    } else if (['repairing', 'in_progress'].contains(status)) {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade900;
    } else if (['ready', 'delivered'].contains(status)) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}