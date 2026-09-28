import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/purchase_repository.dart';
import '../models/vendor.dart';
import '../models/purchase.dart';
import 'purchase_details_screen.dart';

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
    setState(() => _isLoading = false);

    if (response.success && response.data != null) {
      setState(() {
        _vendor = response.data!;
      });
    }

    // Fetch vendor purchase history
    final pRes = await _repository.getPurchases(vendorId: _vendor.id.toString(), perPage: 100);
    if (pRes.success && pRes.data != null) {
      setState(() {
        _purchases = pRes.data!.purchases;
      });
    }
  }

  void _showRecordVendorPaymentDialog() {
    final amountController = TextEditingController(text: _vendor.outstandingAmount.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Record Payment for ${_vendor.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Outstanding: ?${_vendor.outstandingAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Payment Amount (?)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final amt = double.tryParse(amountController.text.trim()) ?? 0;
                if (amt <= 0) return;
                Navigator.pop(ctx);
                final res = await _repository.recordVendorPayment(
                  vendorId: _vendor.id,
                  amount: amt,
                  paymentDate: DateTime.now().toIso8601String().split('T')[0],
                );
                if (res.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('? Payment Recorded. ?${amt.toStringAsFixed(2)} recorded.'), backgroundColor: AppColors.success),
                  );
                  _fetchDetails();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res.message), backgroundColor: AppColors.error),
                  );
                }
              },
              child: const Text('Save Payment', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_vendor.name),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchDetails),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_vendor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text('?? Mobile: ${_vendor.phone}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            if (_vendor.email != null && _vendor.email!.isNotEmpty)
                              Text('?? Email: ${_vendor.email}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            if (_vendor.gstNumber != null && _vendor.gstNumber!.isNotEmpty)
                              Text('?? GST: ${_vendor.gstNumber}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            if (_vendor.address != null && _vendor.address!.isNotEmpty)
                              Text('?? Address: ${_vendor.address}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Purchase', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    Text('?${_vendor.totalPurchase.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Paid', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    Text('?${_vendor.totalPaid.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.success)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Outstanding', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    Text('?${_vendor.outstandingAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _vendor.outstandingAmount > 0 ? AppColors.error : AppColors.success)),
                                  ],
                                ),
                              ],
                            ),
                            if (_vendor.outstandingAmount > 0) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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

                    const Text('Purchase History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('#${p.purchaseNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  StatusBadge(status: p.paymentStatus.toUpperCase()),
                                ],
                              ),
                              subtitle: Text('Date: ${p.purchaseDate.toIso8601String().split('T')[0]} • Total: ?${p.grandTotal.toStringAsFixed(0)}'),
                              trailing: Text('Due: ?${p.outstandingAmount.toStringAsFixed(0)}', style: TextStyle(color: p.outstandingAmount > 0 ? AppColors.error : AppColors.success, fontWeight: FontWeight.bold)),
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

