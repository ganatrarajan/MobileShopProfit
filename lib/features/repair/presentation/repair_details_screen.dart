import 'repair_invoice_pdf_screen.dart';
import '../../warranty/models/warranty.dart';
import '../data/repair_repository.dart';
import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/whatsapp_icon.dart';
import '../../warranty/presentation/warranty_details_screen.dart';
import '../../warranty/presentation/widgets/quick_add_warranty_modal.dart';

import '../../warranty/data/warranty_repository.dart';
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
  final WarrantyRepository _warrantyRepository = WarrantyRepository();
  late Repair _repair;
  bool _isLoading = false;

  static const Map<String, Color> _statusColors = {
    'received': Colors.blue,
    'diagnosing': Colors.orange,
    'waiting_customer': Colors.purple,
    'waiting_parts': Colors.amber,
    'repairing': Colors.indigo,
    'ready': Colors.green,
    'delivered': Colors.teal,
    'cancelled': Colors.red,
  };

  static const Map<String, String> _statusLabels = {
    'received': 'Received',
    'diagnosing': 'Diagnosing',
    'waiting_customer': 'Waiting Customer Approval',
    'waiting_parts': 'Waiting for Parts',
    'repairing': 'Under Repair',
    'ready': 'Ready for Pickup',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
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
          var fetchedRepair = res.data!;
          // Ensure warranty belongs strictly to this repair and is active
          if (fetchedRepair.warranty != null &&
              fetchedRepair.warranty!.repairId == fetchedRepair.id &&
              (fetchedRepair.warranty!.status == 'active' || fetchedRepair.warranty!.status == 'expiring_soon')) {
            // Keep backend warranty relation
          } else {
            // Fallback query filtering strictly by repairId
            final wRes = await _warrantyRepository.getWarranties(repairId: fetchedRepair.id);
            Warranty? matchingWarranty;
            if (wRes.success && wRes.data != null && wRes.data!.isNotEmpty) {
              final activeW = wRes.data!.where((w) =>
                  w.repairId == fetchedRepair.id &&
                  (w.status == 'active' || w.status == 'expiring_soon')).toList();
              if (activeW.isNotEmpty) {
                matchingWarranty = activeW.first;
              }
            }

            fetchedRepair = Repair(
              id: fetchedRepair.id,
              shopId: fetchedRepair.shopId,
              customerId: fetchedRepair.customerId,
              deviceId: fetchedRepair.deviceId,
              technicianId: fetchedRepair.technicianId,
              technicianName: fetchedRepair.technicianName,
              technicianEarning: fetchedRepair.technicianEarning,
              technicianPaidAmount: fetchedRepair.technicianPaidAmount,
              technicianPayable: fetchedRepair.technicianPayable,
              shopShare: fetchedRepair.shopShare,
              technicianPaymentStatus: fetchedRepair.technicianPaymentStatus,
              jobNumber: fetchedRepair.jobNumber,
              dateReceived: fetchedRepair.dateReceived,
              expectedDeliveryDate: fetchedRepair.expectedDeliveryDate,
              deliveredDate: fetchedRepair.deliveredDate,
              problemDescription: fetchedRepair.problemDescription,
              deviceCondition: fetchedRepair.deviceCondition,
              conditionNotes: fetchedRepair.conditionNotes,
              accessoriesReceived: fetchedRepair.accessoriesReceived,
              accessoriesNotes: fetchedRepair.accessoriesNotes,
              pinPasscode: fetchedRepair.pinPasscode,
              estimatedCost: fetchedRepair.estimatedCost,
              finalCost: fetchedRepair.finalCost,
              labourCost: fetchedRepair.labourCost,
              amountPaid: fetchedRepair.amountPaid,
              amountDue: fetchedRepair.amountDue,
              repairStatus: fetchedRepair.repairStatus,
              customerNotes: fetchedRepair.customerNotes,
              internalNotes: fetchedRepair.internalNotes,
              createdBy: fetchedRepair.createdBy,
              creatorName: fetchedRepair.creatorName,
              customer: fetchedRepair.customer,
              device: fetchedRepair.device,
              parts: fetchedRepair.parts,
              payments: fetchedRepair.payments,
              warranty: matchingWarranty,
              createdAt: fetchedRepair.createdAt,
              updatedAt: fetchedRepair.updatedAt,
            );
          }

          setState(() {
            _repair = fetchedRepair;
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

      if (res.success && res.data != null) {
        setState(() => _repair = res.data!);
        
        final newStatus = result['status'];
        final statusNotes = result['notes'];
        
        if (mounted) {
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  WhatsAppIcon(size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Send WhatsApp Update?', style: TextStyle(fontSize: 17)),
                  ),
                ],
              ),
              content: Text('Send status update notification to ${_repair.customer != null ? _repair.customer!.name : "Customer"} on WhatsApp?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Not Now'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await WhatsAppHelper.sendRepairStatusWhatsAppMessage(
                      context,
                      _repair,
                      newStatus,
                      statusNotes: statusNotes,
                    );
                  },
                  icon: const WhatsAppIcon(size: 16, showBackground: false),
                  label: const Text('Send WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.message), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _addPart() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AddRepairPartDialog(repair: _repair),
    );
    if (added == true) _refreshDetails();
  }

  Future<void> _collectPayment() async {
    final paid = await showDialog<bool>(
      context: context,
      builder: (ctx) => CollectRepairPaymentDialog(repair: _repair),
    );
    if (paid == true) _refreshDetails();
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
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            onPressed: () => RepairInvoicePdfScreen.show(context, _repair),
            tooltip: 'View PDF Bill / Ticket',
          ),
          IconButton(
            icon: const WhatsAppIcon(size: 22),
            onPressed: () => WhatsAppHelper.showRepairWhatsAppOptions(context, _repair),
            tooltip: 'WhatsApp Options',
          ),
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
          : RefreshIndicator(
              onRefresh: _refreshDetails,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Job Overview Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [statusColor, statusColor.withOpacity(0.85)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _repair.jobNumber,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                              const SizedBox(width: 6),
                              Text('Received: ${DateHelper.formatDate(_repair.dateReceived)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                          if (_repair.expectedDeliveryDate != null && _repair.expectedDeliveryDate!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.event_available_rounded, size: 14, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text('Expected: ${DateHelper.formatDate(_repair.expectedDeliveryDate)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ],
                          if (_repair.deliveredDate != null && _repair.deliveredDate!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.task_alt_rounded, size: 14, color: Colors.white70),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text('Delivered: ${DateHelper.formatDateTime(_repair.deliveredDate)}', style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Action Buttons Row (Update Status, WhatsApp, Collect Payment)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _updateStatus,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: statusColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 1,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.published_with_changes_rounded, size: 14),
                                SizedBox(width: 3),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => WhatsAppHelper.showRepairWhatsAppOptions(context, _repair),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 1,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                WhatsAppIcon(size: 15, showBackground: false),
                                SizedBox(width: 3),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => RepairInvoicePdfScreen.show(context, _repair),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 1,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.picture_as_pdf_rounded, size: 15),
                                SizedBox(width: 3),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('PDF Bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_repair.amountDue > 0) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _collectPayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 1,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_card_rounded, size: 14),
                                  SizedBox(width: 3),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Payment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Warranty Status Card
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: _repair.warranty != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.verified_user_rounded, color: Colors.green, size: 20),
                                        SizedBox(width: 8),
                                        Text('Warranty Active', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _repair.warranty!.status == 'active' ? Colors.green.shade100 : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _repair.warranty!.status.toUpperCase(),
                                        style: TextStyle(
                                          color: _repair.warranty!.status == 'active' ? Colors.green.shade900 : Colors.orange.shade900,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Warranty #: ${_repair.warranty!.warrantyNumber}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Valid until: ${_repair.warranty!.warrantyEndDate} (${_repair.warranty!.daysRemaining} days remaining)',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                if (_repair.warranty!.warrantyTerms != null && _repair.warranty!.warrantyTerms!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Coverage: ${_repair.warranty!.warrantyTerms}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => WarrantyDetailsScreen(warranty: _repair.warranty!),
                                        ),
                                      );
                                      if (mounted) {
                                        _refreshDetails();
                                      }
                                    },
                                    icon: const Icon(Icons.shield_rounded, size: 16),
                                    label: const Text('View Warranty', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Row(
                                    children: [
                                      Icon(Icons.shield_outlined, color: AppColors.textSecondary, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('No Warranty Linked', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                            Text('Add a warranty for this repair', style: TextStyle(fontSize: 11, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final newW = await QuickWarrantyModal.show(context, repair: _repair);
                                    if (newW != null) {
                                      setState(() {
                                        _repair = Repair(
                                          id: _repair.id,
                                          shopId: _repair.shopId,
                                          customerId: _repair.customerId,
                                          deviceId: _repair.deviceId,
                                          technicianId: _repair.technicianId,
                                          technicianName: _repair.technicianName,
                                          technicianEarning: _repair.technicianEarning,
                                          technicianPaidAmount: _repair.technicianPaidAmount,
                                          technicianPayable: _repair.technicianPayable,
                                          shopShare: _repair.shopShare,
                                          technicianPaymentStatus: _repair.technicianPaymentStatus,
                                          jobNumber: _repair.jobNumber,
                                          dateReceived: _repair.dateReceived,
                                          expectedDeliveryDate: _repair.expectedDeliveryDate,
                                          deliveredDate: _repair.deliveredDate,
                                          problemDescription: _repair.problemDescription,
                                          deviceCondition: _repair.deviceCondition,
                                          conditionNotes: _repair.conditionNotes,
                                          accessoriesReceived: _repair.accessoriesReceived,
                                          accessoriesNotes: _repair.accessoriesNotes,
                                          pinPasscode: _repair.pinPasscode,
                                          estimatedCost: _repair.estimatedCost,
                                          finalCost: _repair.finalCost,
                                          labourCost: _repair.labourCost,
                                          amountPaid: _repair.amountPaid,
                                          amountDue: _repair.amountDue,
                                          repairStatus: _repair.repairStatus,
                                          customerNotes: _repair.customerNotes,
                                          internalNotes: _repair.internalNotes,
                                          createdBy: _repair.createdBy,
                                          creatorName: _repair.creatorName,
                                          customer: _repair.customer,
                                          device: _repair.device,
                                          parts: _repair.parts,
                                          payments: _repair.payments,
                                          warranty: newW,
                                          createdAt: _repair.createdAt,
                                          updatedAt: _repair.updatedAt,
                                        );
                                      });
                                      _refreshDetails();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                                  label: const Text('Add Warranty', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_repair.customer!.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text('Mobile: ${_repair.customer!.mobile}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                      if (_repair.customer!.city != null)
                                        Text('City: ${_repair.customer!.city}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => WhatsAppHelper.showRepairWhatsAppOptions(context, _repair),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF25D366).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFF25D366), width: 1.2),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        WhatsAppIcon(size: 18),
                                        SizedBox(width: 5),
                                        Text(
                                          'WhatsApp',
                                          style: TextStyle(
                                            color: Color(0xFF128C7E),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                            if (_repair.device!.imei1 != null && _repair.device!.imei1!.isNotEmpty)
                              Text('IMEI 1: ${_repair.device!.imei1}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            if (_repair.device!.imei2 != null && _repair.device!.imei2!.isNotEmpty)
                              Text('IMEI 2: ${_repair.device!.imei2}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3b. Assigned Technician Card
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.engineering_rounded, color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Assigned Technician', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                const SizedBox(height: 2),
                                Text(
                                  _repair.technicianName != null && _repair.technicianName!.isNotEmpty
                                      ? _repair.technicianName!
                                      : 'Unassigned',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _repair.technicianName != null && _repair.technicianName!.isNotEmpty
                                        ? AppColors.textPrimary
                                        : Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Problem & Condition Details
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Problem Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(_repair.problemDescription, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                          if (_repair.deviceCondition.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text('Device Condition', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                            const SizedBox(height: 4),
                            Text(_repair.deviceCondition.join(', '), style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                          ],
                          if (_repair.accessoriesReceived.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text('Accessories Received', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                            const SizedBox(height: 4),
                            Text(_repair.accessoriesReceived.join(', '), style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 5. Parts Used List
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.build_rounded, color: AppColors.accent, size: 20),
                                  SizedBox(width: 8),
                                  Text('Parts Used', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: _addPart,
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Add Part', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_repair.parts.isEmpty)
                            const Text('No parts added yet.', style: TextStyle(fontSize: 13, color: AppColors.textMuted))
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _repair.parts.length,
                              separatorBuilder: (_, __) => const Divider(height: 12),
                              itemBuilder: (ctx, idx) {
                                final p = _repair.parts[idx];
                                return Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.partName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                          Text('${p.quantity} x \u20B9${p.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Text('\u20B9 ${(p.quantity * p.sellingPrice).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                                      onPressed: () => _confirmDeletePart(p),
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 6. Cost & Payment Summary Card
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cost Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          _buildRow('Estimated Repair Cost', '\u20B9 ${_repair.estimatedCost.toStringAsFixed(2)}'),
                          if (_repair.finalCost > 0)
                            _buildRow('Final Repair Cost', '\u20B9 ${_repair.finalCost.toStringAsFixed(2)}', isBold: true),
                          if (_repair.labourCost > 0)
                            _buildRow('Labour Amount', '\u20B9 ${_repair.labourCost.toStringAsFixed(2)}'),
                          const Divider(height: 16),
                          _buildRow('TOTAL NET AMOUNT', '\u20B9 ${_repair.netCost.toStringAsFixed(2)}', isBold: true, fontSize: 16),
                          const SizedBox(height: 6),
                          _buildRow('Total Paid / Advance', '\u20B9 ${_repair.amountPaid.toStringAsFixed(2)}', color: Colors.green.shade700, isBold: true),
                          _buildRow(
                            'AMOUNT DUE',
                            '\u20B9 ${_repair.amountDue.toStringAsFixed(2)}',
                            color: _repair.amountDue > 0 ? Colors.red.shade700 : Colors.green.shade700,
                            isBold: true,
                            fontSize: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 7. Payment History Card
                    if (_repair.payments.isNotEmpty) ...[
                      CustomCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Payment History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _repair.payments.length,
                              separatorBuilder: (_, __) => const Divider(height: 12),
                              itemBuilder: (ctx, idx) {
                                final p = _repair.payments[idx];
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '\u20B9 ${p.amount.toStringAsFixed(2)} (${p.paymentMethod.toUpperCase()})',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green.shade700),
                                        ),
                                        if (p.paymentDate != null)
                                          Text(DateHelper.formatDateTime(p.paymentDate), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      ],
                                    ),
                                    if (p.notes != null && p.notes!.isNotEmpty)
                                      Text(p.notes!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
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
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}