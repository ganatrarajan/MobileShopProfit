import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/sale_repository.dart';
import '../models/sale.dart';
import 'collect_payment_dialog.dart';

class SaleDetailsScreen extends StatefulWidget {
  final Sale sale;
  const SaleDetailsScreen({super.key, required this.sale});

  @override
  State<SaleDetailsScreen> createState() => _SaleDetailsScreenState();
}

class _SaleDetailsScreenState extends State<SaleDetailsScreen> {
  final SaleRepository _saleRepository = SaleRepository();
  late Sale _sale;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sale = widget.sale;
    _refreshDetails();
  }

  Future<void> _refreshDetails() async {
    setState(() => _isLoading = true);
    try {
      final response = await _saleRepository.getSaleDetails(_sale.id);
      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _sale = response.data!;
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green.shade700;
      case 'partially_paid':
        return Colors.orange.shade800;
      case 'due':
      default:
        return Colors.red.shade700;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'PAID';
      case 'partially_paid':
        return 'PARTIAL';
      case 'due':
      default:
        return 'DUE';
    }
  }

  Future<void> _collectPayment() async {
    final updatedSale = await showDialog<Sale>(
      context: context,
      builder: (ctx) => CollectPaymentDialog(sale: _sale),
    );

    if (updatedSale != null) {
      setState(() => _sale = updatedSale);
      _refreshDetails();
    }
  }

  Future<void> _confirmDeleteSale() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
              SizedBox(width: 8),
              Text('Delete Invoice'),
            ],
          ),
          content: Text('Are you sure you want to delete invoice ${_sale.invoiceNumber}? This action cannot be undone.'),
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
      final res = await _saleRepository.deleteSale(_sale.id);
      if (mounted) {
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invoice ${_sale.invoiceNumber} deleted successfully.'),
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
    final statusColor = _getStatusColor(_sale.paymentStatus);
    final statusLabel = _getStatusLabel(_sale.paymentStatus);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Invoice #${_sale.invoiceNumber}'),
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
            onPressed: _confirmDeleteSale,
            tooltip: 'Delete Invoice',
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
                  // Invoice Header Card
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _sale.invoiceNumber,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Date: ${_sale.saleDate.length >= 10 ? _sale.saleDate.substring(0, 10) : _sale.saleDate}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            StatusBadge(
                              label: statusLabel,
                              backgroundColor: statusColor.withOpacity(0.12),
                              textColor: statusColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Customer & Device Information Card
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_rounded, color: AppColors.accent, size: 18),
                            SizedBox(width: 8),
                            Text('Customer Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_sale.customer != null) ...[
                          Text(_sale.customer!.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text('Mobile: ${_sale.customer!.mobile}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          if (_sale.customer!.email != null)
                            Text('Email: ${_sale.customer!.email}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ] else ...[
                          const Text('Walk-in Customer (No customer record attached)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                        ],

                        if (_sale.device != null) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          const Row(
                            children: [
                              Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 18),
                              SizedBox(width: 8),
                              Text('Connected Device', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('${_sale.device!.brand} ${_sale.device!.model}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          if (_sale.device!.imei1 != null)
                            Text('IMEI 1: ${_sale.device!.imei1}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          if (_sale.device!.imei2 != null)
                            Text('IMEI 2: ${_sale.device!.imei2}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Line Items Table
                  const Text('Invoice Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  CustomCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: const [
                            Expanded(flex: 4, child: Text('Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                            Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                            Expanded(flex: 2, child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                            Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted))),
                          ],
                        ),
                        const Divider(height: 16),
                        ..._sale.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      if (item.brand != null || item.model != null)
                                        Text('${item.brand ?? ''} ${item.model ?? ''}'.trim(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      if (item.imei1 != null)
                                        Text('IMEI: ${item.imei1}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                      if (item.discount > 0)
                                        Text('Disc: -₹${item.discount.toStringAsFixed(2)}', style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('₹${item.unitPrice.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('₹${item.total.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Financial Breakdown Card
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildRow('Subtotal', '₹ ${_sale.subtotal.toStringAsFixed(2)}'),
                        if (_sale.totalDiscount > 0)
                          _buildRow('Total Discount', '- ₹ ${_sale.totalDiscount.toStringAsFixed(2)}', color: Colors.green.shade700, isBold: true),
                        if (_sale.taxAmount > 0)
                          _buildRow('Tax / GST', '+ ₹ ${_sale.taxAmount.toStringAsFixed(2)}'),
                        const Divider(height: 20),
                        _buildRow('GRAND TOTAL', '₹ ${_sale.grandTotal.toStringAsFixed(2)}', isBold: true, fontSize: 18),
                        const SizedBox(height: 6),
                        _buildRow('Amount Paid', '₹ ${_sale.amountPaid.toStringAsFixed(2)}', color: Colors.green.shade700, isBold: true),
                        const SizedBox(height: 6),
                        _buildRow('AMOUNT DUE', '₹ ${_sale.amountDue.toStringAsFixed(2)}', color: _sale.amountDue > 0 ? Colors.red.shade700 : Colors.green.shade700, isBold: true, fontSize: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Collect Payment Action Button
                  if (_sale.amountDue > 0) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _collectPayment,
                        icon: const Icon(Icons.add_card_rounded),
                        label: Text('Collect Payment (Due: ₹${_sale.amountDue.toStringAsFixed(2)})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Payment History Timeline
                  const Text('Payment History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  CustomCard(
                    padding: const EdgeInsets.all(14),
                    child: _sale.payments.isEmpty
                        ? const Text('No payments recorded yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 13))
                        : Column(
                            children: _sale.payments.map((p) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.payment_rounded, color: Colors.green.shade700, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Paid via ${p.paymentMethod.toUpperCase()}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            p.paymentDate != null && p.paymentDate!.length >= 10 ? p.paymentDate!.substring(0, 10) : '',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                          if (p.notes != null && p.notes!.isNotEmpty)
                                            Text('Notes: ${p.notes}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '+ ₹ ${p.amount.toStringAsFixed(2)}',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green.shade800),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRow(String label, String value, {Color? color, bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? AppColors.textPrimary)),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}
