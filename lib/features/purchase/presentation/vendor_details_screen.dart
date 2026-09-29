import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/purchase_repository.dart';
import '../models/vendor.dart';
import '../models/purchase.dart';
import 'purchase_details_screen.dart';
import 'widgets/quick_add_vendor_modal.dart';

class VendorDetailsScreen extends StatefulWidget {
  final Vendor vendor;

  const VendorDetailsScreen({
    super.key,
    required this.vendor,
  });

  @override
  State<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen> {
  late Vendor _vendor;
  List<Purchase> _purchases = [];
  bool _isLoading = false;
  final PurchaseRepository _repository = PurchaseRepository();

  @override
  void initState() {
    super.initState();
    _vendor = widget.vendor;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    final response = await _repository.getVendorDetails(_vendor.id);
    if (mounted) setState(() => _isLoading = false);

    if (response.success && response.data != null) {
      if (mounted) {
        setState(() {
          _vendor = response.data!;
        });
      }
    }

    final pRes = await _repository.getPurchases(vendorId: _vendor.id.toString(), perPage: 100);
    if (mounted && pRes.success && pRes.data != null) {
      setState(() {
        _purchases = pRes.data!.purchases;
      });
    }
  }

  Future<void> _openEditVendor() async {
    final updated = await QuickAddVendorModal.show(context, vendorToEdit: _vendor);
    if (updated != null) {
      _fetchDetails();
    }
  }

  void _showRecordVendorPaymentDialog() {
    final amountController = TextEditingController(text: _vendor.outstandingAmount.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Record Payment for ${_vendor.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Outstanding: \u20B9${_vendor.outstandingAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Payment Amount (\u20B9)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () async {
                final amt = double.tryParse(amountController.text.trim()) ?? 0;
                if (amt <= 0) return;
                Navigator.pop(ctx);
                final res = await _repository.recordVendorPayment(
                  vendorId: _vendor.id,
                  amount: amt,
                  paymentDate: DateTime.now().toIso8601String().split('T')[0],
                );
                if (mounted) {
                  if (res.success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Payment Recorded: \u20B9${amt.toStringAsFixed(2)}'), backgroundColor: AppColors.success),
                    );
                    _fetchDetails();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res.message), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Save Payment'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    final s = status.toLowerCase();
    if (s == 'paid') {
      bg = Colors.green.shade100;
      text = Colors.green.shade800;
    } else if (s == 'partial') {
      bg = Colors.amber.shade100;
      text = Colors.amber.shade900;
    } else {
      bg = Colors.red.shade100;
      text = Colors.red.shade800;
    }
    return StatusBadge(
      label: status.toUpperCase(),
      backgroundColor: bg,
      textColor: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _vendor.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: 'Edit Vendor',
            onPressed: _openEditVendor,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _fetchDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDetails,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // VENDOR SUMMARY METRICS
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(_vendor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                  tooltip: 'Edit Vendor Details',
                                  onPressed: _openEditVendor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Mobile: ${_vendor.phone}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            if (_vendor.email != null && _vendor.email!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('Email: ${_vendor.email}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              ),
                            if (_vendor.gstNumber != null && _vendor.gstNumber!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('GST: ${_vendor.gstNumber}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              ),
                            if (_vendor.address != null && _vendor.address!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('Address: ${_vendor.address}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Purchase', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text('\u20B9${_vendor.totalPurchase.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Paid', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text('\u20B9${_vendor.totalPaid.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.success)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Outstanding', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text('\u20B9${_vendor.outstandingAmount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _vendor.outstandingAmount > 0 ? AppColors.error : AppColors.success)),
                                  ],
                                ),
                              ],
                            ),
                            if (_vendor.outstandingAmount > 0) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                  icon: const Icon(Icons.payment, color: Colors.white, size: 18),
                                  label: const Text('Record Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  onPressed: _showRecordVendorPaymentDialog,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Purchase History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),

                    if (_purchases.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: Text('No purchase history recorded for this vendor.', style: TextStyle(color: AppColors.textMuted))),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _purchases.length,
                        itemBuilder: (context, index) {
                          final p = _purchases[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 1,
                            child: ListTile(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('#${p.purchaseNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  _buildStatusBadge(p.paymentStatus),
                                ],
                              ),
                              subtitle: Text('Date: ${p.purchaseDate.toIso8601String().split('T')[0]}     Total: \u20B9${p.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              trailing: Text('Due: \u20B9${p.outstandingAmount.toStringAsFixed(2)}', style: TextStyle(color: p.outstandingAmount > 0 ? AppColors.error : AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PurchaseDetailsScreen(purchase: p)),
                                );
                              },
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
}
