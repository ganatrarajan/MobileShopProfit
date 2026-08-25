import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/repair_repository.dart';
import '../models/repair.dart';
import 'add_repair_part_dialog.dart';
import 'collect_repair_payment_dialog.dart';
import 'update_status_dialog.dart';

class RepairDetailsScreen extends StatefulWidget {
  final Repair repair;
  const RepairDetailsScreen({super.key, required this.repair});

  @override
  State<RepairDetailsScreen> createState() => _RepairDetailsScreenState();
}

class _RepairDetailsScreenState extends State<RepairDetailsScreen> {
  final RepairRepository _repairRepository = RepairRepository();
  late Repair _repair;
  bool _isLoading = false;
  bool _showPin = false;

  final Map<String, String> _statusLabels = {
    'received': 'Received',
    'diagnosing': 'Diagnosing',
    'waiting_customer': 'Waiting Customer',
    'waiting_parts': 'Waiting Parts',
    'repairing': 'Repairing',
    'ready': 'Ready',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };

  final Map<String, Color> _statusColors = {
    'received': Colors.blue.shade700,
    'diagnosing': Colors.purple.shade700,
    'waiting_customer': Colors.orange.shade800,
    'waiting_parts': Colors.amber.shade900,
    'repairing': Colors.indigo.shade700,
    'ready': Colors.teal.shade700,
    'delivered': Colors.green.shade800,
    'cancelled': Colors.red.shade700,
  };

  @override
  void initState() {
    super.initState();
    _repair = widget.repair;
    _refreshDetails();
  }

  Future<void> _refreshDetails() async {
    setState(() => _isLoading = true);
    try {
      final res = await _repairRepository.getRepairDetails(_repair.id);
      if (mounted) {
        if (res.success && res.data != null) {
          setState(() {
            _repair = res.data!;
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

  Future<void> _updateStatus() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => UpdateStatusDialog(repair: _repair),
    );

    if (result != null && result['status'] != null) {
      final res = await _repairRepository.updateStatus(
        id: _repair.id,
        repairStatus: result['status'],
        notes: result['notes'],
      );

      if (mounted) {
        if (res.success && res.data != null) {
          setState(() => _repair = res.data!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message), backgroundColor: Colors.green.shade700),
          );
        }
      }
    }
  }

  Future<void> _collectPayment() async {
    final updatedRepair = await showDialog<Repair>(
      context: context,
      builder: (ctx) => CollectRepairPaymentDialog(repair: _repair),
    );

    if (updatedRepair != null) {
      setState(() => _repair = updatedRepair);
      _refreshDetails();
    }
  }

  Future<void> _addPart() async {
    final updatedRepair = await showDialog<Repair>(
      context: context,
      builder: (ctx) => AddRepairPartDialog(repair: _repair),
    );

    if (updatedRepair != null) {
      setState(() => _repair = updatedRepair);
      _refreshDetails();
    }
  }

  Future<void> _confirmDeletePart(RepairPart part) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Part'),
          content: Text('Remove part "${part.partName}" from this repair?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final res = await _repairRepository.deletePart(part.id);
      if (mounted && res.success && res.data != null) {
        setState(() => _repair = res.data!);
      }
    }
  }

  Future<void> _confirmDeleteRepair() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
              SizedBox(width: 8),
              Text('Delete Job Card'),
            ],
          ),
          content: Text('Are you sure you want to delete job card ${_repair.jobNumber}? This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
      final res = await _repairRepository.deleteRepair(_repair.id);
      if (mounted) {
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Job Card ${_repair.jobNumber} deleted.'), backgroundColor: Colors.green.shade700),
          );
          Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[_repair.repairStatus] ?? AppColors.primary;
    final statusLabel = _statusLabels[_repair.repairStatus] ?? _repair.repairStatus.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Job Card ${_repair.jobNumber}', overflow: TextOverflow.ellipsis),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: () async {
              final updated = await Navigator.pushNamed(context, AppRoutes.editRepair, arguments: _repair);
              if (updated == true) _refreshDetails();
            },
            tooltip: 'Edit Job Card',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshDetails,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            onPressed: _confirmDeleteRepair,
            tooltip: 'Delete Job Card',
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
                  // 1. Job Card Status Banner Card
                  CustomCard(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _repair.jobNumber,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            StatusBadge(
                              label: statusLabel,
                              backgroundColor: Colors.white,
                              textColor: statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 6,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text('Received: ${_repair.dateReceived}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                            if (_repair.expectedDeliveryDate != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.event_available_rounded, size: 14, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Text('Expected: ${_repair.expectedDeliveryDate}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                          ],
                        ),
                        if (_repair.deliveredDate != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.task_alt_rounded, size: 14, color: Colors.greenAccent),
                              const SizedBox(width: 6),
                              Text('Delivered: ${_repair.deliveredDate}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons Row (Update Status, Collect Payment)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _updateStatus,
                          icon: const Icon(Icons.published_with_changes_rounded, size: 18),
                          label: const Text('Update Status'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      if (_repair.amountDue > 0) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _collectPayment,
                            icon: const Icon(Icons.add_card_rounded, size: 18),
                            label: const Text('Collect Payment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Customer Info Card
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_pin_rounded, color: AppColors.accent, size: 20),
                            SizedBox(width: 8),
                            Text('Customer Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_repair.customer != null) ...[
                          Text(_repair.customer!.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('Mobile: ${_repair.customer!.mobile}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          if (_repair.customer!.city != null)
                            Text('City: ${_repair.customer!.city}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ] else ...[
                          const Text('Customer ID recorded', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Device Info Card
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.phone_android_rounded, color: AppColors.accent, size: 20),
                            SizedBox(width: 8),
                            Text('Device Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_repair.device != null) ...[
                          Text('${_repair.device!.brand} ${_repair.device!.model}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          if (_repair.device!.imei1 != null)
                            Text('IMEI 1: ${_repair.device!.imei1}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          if (_repair.device!.imei2 != null)
                            Text('IMEI 2: ${_repair.device!.imei2}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Complaint & Problem Card
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.report_problem_outlined, color: AppColors.error, size: 20),
                            SizedBox(width: 8),
                            Text('Customer Complaint / Problem', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_repair.problemDescription, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. Condition & Accessories Card
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Device Condition & Accessories', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        const Text('Condition at Receiving:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        _repair.deviceCondition.isNotEmpty
                            ? Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _repair.deviceCondition.map((c) {
                                  return Chip(
                                    label: Text(c, style: const TextStyle(fontSize: 11)),
                                    backgroundColor: Colors.blue.shade50,
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              )
                            : const Text('None recorded', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        if (_repair.conditionNotes != null && _repair.conditionNotes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('Notes: ${_repair.conditionNotes}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ),
                        const SizedBox(height: 12),
                        const Text('Accessories Received:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        _repair.accessoriesReceived.isNotEmpty
                            ? Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _repair.accessoriesReceived.map((a) {
                                  return Chip(
                                    label: Text(a, style: const TextStyle(fontSize: 11)),
                                    backgroundColor: Colors.amber.shade50,
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              )
                            : const Text('None recorded', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        if (_repair.accessoriesNotes != null && _repair.accessoriesNotes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('Notes: ${_repair.accessoriesNotes}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 6. Passcode Card (Optional & Secure)
                  if (_repair.pinPasscode != null && _repair.pinPasscode!.isNotEmpty) ...[
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded, color: AppColors.accent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Device Passcode / PIN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                Text(
                                  _showPin ? _repair.pinPasscode! : '••••••••',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: _showPin ? 0 : 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(_showPin ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted),
                            onPressed: () => setState(() => _showPin = !_showPin),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 7. Parts Used Section Card
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Parts Used', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            TextButton.icon(
                              onPressed: _addPart,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('+ Add Part'),
                            ),
                          ],
                        ),
                        if (_repair.parts.isEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('No parts recorded for this repair yet.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ),
                        ] else ...[
                          ..._repair.parts.map((p) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.partName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text('${p.quantity} x ₹${p.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Text('₹ ${(p.quantity * p.sellingPrice).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                                    onPressed: () => _confirmDeletePart(p),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 8. Financial Summary Card
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text('Financial Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildRow('Estimated Repair Cost', '₹ ${_repair.estimatedCost.toStringAsFixed(2)}'),
                        if (_repair.finalCost > 0)
                          _buildRow('Final Repair Cost', '₹ ${_repair.finalCost.toStringAsFixed(2)}', isBold: true),
                        if (_repair.labourCost > 0)
                          _buildRow('Labour Amount', '₹ ${_repair.labourCost.toStringAsFixed(2)}'),
                        const Divider(height: 20),
                        _buildRow('TOTAL NET AMOUNT', '₹ ${_repair.netCost.toStringAsFixed(2)}', isBold: true, fontSize: 16),
                        const SizedBox(height: 6),
                        _buildRow('Total Paid / Advance', '₹ ${_repair.amountPaid.toStringAsFixed(2)}', color: Colors.green.shade700, isBold: true),
                        const SizedBox(height: 6),
                        _buildRow(
                          'REMAINING DUE',
                          '₹ ${_repair.amountDue.toStringAsFixed(2)}',
                          color: _repair.amountDue > 0 ? Colors.red.shade700 : Colors.green.shade700,
                          isBold: true,
                          fontSize: 17,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 9. Payment History Card
                  if (_repair.payments.isNotEmpty) ...[
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Payment History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          ..._repair.payments.map((p) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '₹ ${p.amount.toStringAsFixed(2)} (${p.paymentMethod.toUpperCase()})',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                                      ),
                                      if (p.notes != null)
                                        Text(p.notes!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    ],
                                  ),
                                  Text(
                                    p.paymentDate?.substring(0, 10) ?? '',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 10. Notes Card
                  if ((_repair.customerNotes != null && _repair.customerNotes!.isNotEmpty) ||
                      (_repair.internalNotes != null && _repair.internalNotes!.isNotEmpty)) ...[
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Notes & History Log', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          if (_repair.customerNotes != null && _repair.customerNotes!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text('Customer Notes:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                            Text(_repair.customerNotes!, style: const TextStyle(fontSize: 13)),
                          ],
                          if (_repair.internalNotes != null && _repair.internalNotes!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text('Internal Technician Log:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                            Text(_repair.internalNotes!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize - 1, color: isBold ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: fontSize, color: color ?? AppColors.textPrimary, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }
}
