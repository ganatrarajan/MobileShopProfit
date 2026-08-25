import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/warranty_repository.dart';
import '../models/warranty.dart';
import 'create_claim_dialog.dart';
import 'update_claim_status_dialog.dart';

class WarrantyDetailsScreen extends StatefulWidget {
  final Warranty warranty;
  const WarrantyDetailsScreen({super.key, required this.warranty});

  @override
  State<WarrantyDetailsScreen> createState() => _WarrantyDetailsScreenState();
}

class _WarrantyDetailsScreenState extends State<WarrantyDetailsScreen> {
  final WarrantyRepository _warrantyRepository = WarrantyRepository();
  late Warranty _warranty;
  bool _isLoading = false;

  final Map<String, Color> _statusColors = {
    'active': Colors.green.shade700,
    'expiring_soon': Colors.amber.shade900,
    'expired': Colors.red.shade700,
    'voided': Colors.grey.shade700,
  };

  final Map<String, Color> _claimStatusColors = {
    'open': Colors.blue.shade700,
    'checking': Colors.purple.shade700,
    'approved': Colors.teal.shade700,
    'rejected': Colors.red.shade700,
    'repairing': Colors.indigo.shade700,
    'resolved': Colors.green.shade700,
    'closed': Colors.grey.shade700,
  };

  @override
  void initState() {
    super.initState();
    _warranty = widget.warranty;
    _refreshDetails();
  }

  Future<void> _refreshDetails() async {
    setState(() => _isLoading = true);
    try {
      final res = await _warrantyRepository.getWarrantyDetails(_warranty.id);
      if (mounted) {
        if (res.success && res.data != null) {
          setState(() {
            _warranty = res.data!;
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

  Future<void> _registerClaim() async {
    final newClaim = await showDialog<WarrantyClaim>(
      context: context,
      builder: (ctx) => CreateClaimDialog(warranty: _warranty),
    );

    if (newClaim != null) {
      _refreshDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Claim ${newClaim.claimNumber} filed successfully.'), backgroundColor: Colors.green.shade700),
        );
      }
    }
  }

  Future<void> _updateClaimStatus(WarrantyClaim claim) async {
    final updatedClaim = await showDialog<WarrantyClaim>(
      context: context,
      builder: (ctx) => UpdateClaimStatusDialog(claim: claim),
    );

    if (updatedClaim != null) {
      _refreshDetails();
    }
  }

  Future<void> _confirmDeleteWarranty() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
              SizedBox(width: 8),
              Text('Delete Warranty'),
            ],
          ),
          content: Text('Are you sure you want to delete warranty ${_warranty.warrantyNumber}? All associated claims will also be deleted.'),
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
      final res = await _warrantyRepository.deleteWarranty(_warranty.id);
      if (mounted) {
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Warranty ${_warranty.warrantyNumber} deleted.'), backgroundColor: Colors.green.shade700),
          );
          Navigator.pop(context, true);
        }
      }
    }
  }

  String? get _coveredComponent {
    if (_warranty.warrantyTerms != null && _warranty.warrantyTerms!.contains('Covered Component/Part:')) {
      final lines = _warranty.warrantyTerms!.split('\n');
      for (final line in lines) {
        if (line.startsWith('Covered Component/Part:')) {
          return line.replaceFirst('Covered Component/Part:', '').trim();
        }
      }
    }
    if (_warranty.repair != null && _warranty.repair!.problemDescription.isNotEmpty) {
      return _warranty.repair!.problemDescription;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[_warranty.status] ?? AppColors.primary;
    final statusLabel = _warranty.status.replaceAll('_', ' ').toUpperCase();

    String bannerTitle = '';
    String bannerSubtitle = '';
    if (_warranty.status == 'expired') {
      bannerTitle = 'WARRANTY EXPIRED';
      bannerSubtitle = 'Expired ${_warranty.daysRemaining.abs()} days ago on ${_warranty.warrantyEndDate}';
    } else if (_warranty.status == 'expiring_soon') {
      bannerTitle = 'EXPIRING SOON';
      bannerSubtitle = 'Warranty expires in ${_warranty.daysRemaining} days on ${_warranty.warrantyEndDate}';
    } else if (_warranty.status == 'voided') {
      bannerTitle = 'WARRANTY VOIDED';
      bannerSubtitle = 'This warranty has been marked as voided by shop owner';
    } else {
      bannerTitle = 'WARRANTY ACTIVE';
      bannerSubtitle = 'Expires in ${_warranty.daysRemaining} days on ${_warranty.warrantyEndDate}';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Warranty ${_warranty.warrantyNumber}', overflow: TextOverflow.ellipsis),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshDetails,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            onPressed: _confirmDeleteWarranty,
            tooltip: 'Delete Warranty',
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
                  // 1. Dynamic Status Banner Card
                  CustomCard(
                    backgroundColor: statusColor,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _warranty.warrantyNumber,
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
                        Text(
                          bannerTitle,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bannerSubtitle,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text('Start: ${_warranty.warrantyStartDate}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(width: 12),
                            const Icon(Icons.timer_rounded, size: 14, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text('Duration: ${_warranty.durationDays} Days', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons Row (File Claim)
                  ElevatedButton.icon(
                    onPressed: _registerClaim,
                    icon: const Icon(Icons.assignment_late_rounded, size: 18),
                    label: const Text('Register Warranty Claim'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Customer Summary Card
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
                        if (_warranty.customer != null) ...[
                          Text(_warranty.customer!.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('Mobile: ${_warranty.customer!.mobile}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Device Summary Card
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
                        if (_warranty.device != null) ...[
                          Text('${_warranty.device!.brand} ${_warranty.device!.model}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          if (_warranty.device!.imei1 != null)
                            Text('IMEI 1: ${_warranty.device!.imei1}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          if (_warranty.device!.imei2 != null)
                            Text('IMEI 2: ${_warranty.device!.imei2}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Linked Sale or Repair Card
                  if (_warranty.sale != null || _warranty.repair != null) ...[
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(_warranty.warrantyType == 'sale' ? Icons.receipt_long_rounded : Icons.build_circle_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(_warranty.warrantyType == 'sale' ? 'Linked Sale Invoice' : 'Linked Repair Job Card', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_warranty.sale != null) ...[
                            Text('Invoice #${_warranty.sale!.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Grand Total: ₹${_warranty.sale!.grandTotal.toStringAsFixed(2)} (${_warranty.sale!.saleDate})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                          if (_warranty.repair != null) ...[
                            Text('Job Card #${_warranty.repair!.jobNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Net Cost: ₹${_warranty.repair!.netCost.toStringAsFixed(2)} (${_warranty.repair!.dateReceived})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text('Problem: ${_warranty.repair!.problemDescription}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 5. Covered Component Highlight Card
                  if (_coveredComponent != null) ...[
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.build_circle_rounded, color: AppColors.accent, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('COVERED COMPONENT / PART CHANGED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent)),
                                const SizedBox(height: 2),
                                Text(_coveredComponent!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 6. Warranty Terms & Notes
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Warranty Terms & Conditions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          _warranty.warrantyTerms != null && _warranty.warrantyTerms!.isNotEmpty
                              ? _warranty.warrantyTerms!
                              : 'Standard shop warranty terms apply.',
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                        if (_warranty.notes != null && _warranty.notes!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text('Internal Notes:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                          Text(_warranty.notes!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 6. Claims History List Card
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Warranty Claims (${_warranty.claims.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            TextButton.icon(
                              onPressed: _registerClaim,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('New Claim'),
                            ),
                          ],
                        ),
                        if (_warranty.claims.isEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('No warranty claims filed yet.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ),
                        ] else ...[
                          ..._warranty.claims.map((claim) {
                            final cColor = _claimStatusColors[claim.claimStatus] ?? AppColors.primary;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(claim.claimNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                                        StatusBadge(
                                          label: claim.claimStatus.toUpperCase(),
                                          backgroundColor: cColor.withOpacity(0.12),
                                          textColor: cColor,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Complaint: ${claim.complaint}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    if (claim.resolution != null && claim.resolution!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Resolution: ${claim.resolution}', style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.w500)),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Claim Date: ${claim.claimDate}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                        ElevatedButton(
                                          onPressed: () => _updateClaimStatus(claim),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: cColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: const Text('Update Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
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
}
