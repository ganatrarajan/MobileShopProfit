import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/purchase_repository.dart';
import '../models/purchase.dart';
import 'record_purchase_payment_dialog.dart';

class PurchaseDetailsScreen extends StatefulWidget {
  final Purchase purchase;

  const PurchaseDetailsScreen({
    super.key,
    required this.purchase,
  });

  @override
  State<PurchaseDetailsScreen> createState() => _PurchaseDetailsScreenState();
}

class _PurchaseDetailsScreenState extends State<PurchaseDetailsScreen> {
  late Purchase _purchase;
  bool _isLoading = false;
  final PurchaseRepository _repository = PurchaseRepository();

  @override
  void initState() {
    super.initState();
    _purchase = widget.purchase;
    _refreshDetails();
  }

  Future<void> _refreshDetails() async {
    setState(() => _isLoading = true);
    final response = await _repository.getPurchaseDetails(_purchase.id);
    setState(() => _isLoading = false);
    if (response.success && response.data != null) {
      setState(() => _purchase = response.data!);
    }
  }

  Future<void> _openAddPayment() async {
    final updated = await RecordPurchasePaymentDialog.show(context, _purchase);
    if (updated == true) {
      _refreshDetails();
    }
  }

  Future<void> _addStockToInventory() async {
    setState(() => _isLoading = true);
    final response = await _repository.addStockToPurchase(_purchase.id);
    setState(() => _isLoading = false);
    if (response.success && response.data != null) {
      setState(() => _purchase = response.data!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
      appBar: AppBar(
        title: Text('Purchase #${_purchase.purchaseNumber}'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshDetails,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // INVENTORY STATUS BANNER
                    if (_purchase.isStockAdded)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Inventory Updated ?', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 14)),
                                  Text(
                                    '${_purchase.items.fold(0, (sum, i) => sum + i.quantity)} purchased items were added to inventory stock.',
                                    style: TextStyle(fontSize: 12, color: Colors.green.shade900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Stock Not Added Yet', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 13)),
                                  const Text('Items from this purchase have not been merged into inventory.', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              onPressed: _addStockToInventory,
                              child: const Text('Add Stock', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ],
                        ),
                      ),

                    // PURCHASE INFO CARD
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Purchase #${_purchase.purchaseNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                _buildStatusBadge(_purchase.paymentStatus),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Vendor:', style: TextStyle(color: AppColors.textMuted)),
                                Text(_purchase.vendorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Purchase Date:', style: TextStyle(color: AppColors.textMuted)),
                                Text(_purchase.purchaseDate.toIso8601String().split('T')[0], style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            if (_purchase.notes != null && _purchase.notes!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Notes:', style: TextStyle(color: AppColors.textMuted)),
                                  Expanded(child: Text(_purchase.notes!, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PURCHASE ITEMS CARD
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Items Purchased', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 12),
                            Table(
                              columnWidths: const {
                                0: FlexColumnWidth(3),
                                1: FlexColumnWidth(1),
                                2: FlexColumnWidth(2),
                                3: FlexColumnWidth(2),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(color: Colors.grey.shade100),
                                  children: const [
                                    Padding(padding: EdgeInsets.all(6), child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: EdgeInsets.all(6), child: Text('Qty', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: EdgeInsets.all(6), child: Text('Rate', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    Padding(padding: EdgeInsets.all(6), child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  ],
                                ),
                                ..._purchase.items.map((item) {
                                  return TableRow(
                                    children: [
                                      Padding(padding: const EdgeInsets.all(6), child: Text(item.itemName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                                      Padding(padding: const EdgeInsets.all(6), child: Text('${item.quantity}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                                      Padding(padding: const EdgeInsets.all(6), child: Text('?${item.purchaseRate.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                                      Padding(padding: const EdgeInsets.all(6), child: Text('?${item.totalAmount.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PAYMENT BREAKDOWN CARD
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Payment Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:'),
                                Text('?${_purchase.subtotal.toStringAsFixed(2)}'),
                              ],
                            ),
                            if (_purchase.discount > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Discount:'),
                                  Text('- ?${_purchase.discount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.error)),
                                ],
                              ),
                            ],
                            if (_purchase.additionalCharges > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Additional Charges:'),
                                  Text('+ ?${_purchase.additionalCharges.toStringAsFixed(2)}'),
                                ],
                              ),
                            ],
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('?${_purchase.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Amount Paid:'),
                                Text('?${_purchase.amountPaid.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Outstanding:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('?${_purchase.outstandingAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: _purchase.outstandingAmount > 0 ? AppColors.error : AppColors.success)),
                              ],
                            ),
                            if (_purchase.outstandingAmount > 0) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.payment_rounded, color: Colors.white, size: 18),
                                  label: const Text('Add Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  onPressed: _openAddPayment,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}

