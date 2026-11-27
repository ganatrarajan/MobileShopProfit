import '../../../core/storage/auth_storage.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/utils/date_helper.dart';
import '../../settings/presentation/widgets/security_pin_dialogs.dart';
import '../../warranty/models/warranty.dart';
import '../data/sale_repository.dart';
import 'package:flutter/material.dart';
import '../../../core/services/profit_visibility_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../warranty/presentation/warranty_details_screen.dart';
import '../../warranty/presentation/widgets/quick_add_warranty_modal.dart';

import '../../warranty/data/warranty_repository.dart';
import '../models/sale.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/whatsapp_icon.dart';
import 'sale_invoice_pdf_screen.dart';
import 'collect_payment_dialog.dart';
import 'edit_sale_screen.dart';

class SaleDetailsScreen extends StatefulWidget {
  final Sale sale;
  const SaleDetailsScreen({super.key, required this.sale});

  @override
  State<SaleDetailsScreen> createState() => _SaleDetailsScreenState();
}

class _SaleDetailsScreenState extends State<SaleDetailsScreen> {
  
  final SaleRepository _saleRepository = SaleRepository();
  final WarrantyRepository _warrantyRepository = WarrantyRepository();
  late Sale _sale;
  bool _isLoading = false;
  bool _isOwner = true;

  @override
  void initState() {
    super.initState();
    _sale = widget.sale;
    AuthStorage().isOwner().then((val) {
      if (mounted) setState(() => _isOwner = val);
    });
    _refreshDetails();
  }

  Future<void> _refreshDetails() async {
    setState(() => _isLoading = true);
    try {
      final response = await _saleRepository.getSaleDetails(_sale.id);
      if (mounted) {
        if (response.success && response.data != null) {
          var fetchedSale = response.data!;
          if (fetchedSale.warranty != null &&
              fetchedSale.warranty!.saleId == fetchedSale.id &&
              (fetchedSale.warranty!.status == 'active' || fetchedSale.warranty!.status == 'expiring_soon')) {
            // Keep backend relation
          } else {
            final wRes = await _warrantyRepository.getWarranties(saleId: fetchedSale.id);
            Warranty? matchingWarranty;
            if (wRes.success && wRes.data != null && wRes.data!.isNotEmpty) {
              final activeW = wRes.data!.where((w) =>
                  w.saleId == fetchedSale.id &&
                  (w.status == 'active' || w.status == 'expiring_soon')).toList();
              if (activeW.isNotEmpty) {
                matchingWarranty = activeW.first;
              }
            }

            fetchedSale = fetchedSale.copyWith(warranty: matchingWarranty);
          }
          setState(() {
            _sale = fetchedSale;
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
    final result = await CollectPaymentDialog.show(context, sale: _sale);
    if (result != null && result is Sale) {
      setState(() => _sale = result);
      _refreshDetails();
    }
  }

  Future<void> _editSale() async {
    if (!_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only shop owner / admin can edit sales invoices.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final pin = await SecurityPinPromptDialog.show(
      context,
      title: 'Admin Verification',
      message: 'Enter your 4-digit Security PIN to edit invoice ${_sale.invoiceNumber}.',
      confirmLabel: 'Verify & Edit',
    );

    if (pin == null || pin.isEmpty) return;

    if (!mounted) return;

    final updatedSale = await Navigator.push<Sale>(
      context,
      MaterialPageRoute(
        builder: (_) => EditSaleScreen(
          sale: _sale,
          securityPin: pin,
        ),
      ),
    );

    if (updatedSale != null && mounted) {
      setState(() => _sale = updatedSale);
      _refreshDetails();
    }
  }

  Future<void> _confirmDeleteSale() async {
    if (!_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only shop admin can delete sales.'), backgroundColor: AppColors.error),
      );
      return;
    }

    final pin = await SecurityPinPromptDialog.show(
      context,
      title: 'Delete Invoice',
      message: 'Are you sure you want to delete invoice ${_sale.invoiceNumber}? This action cannot be undone.\n\nEnter your 4-digit Security PIN to confirm deletion.',
      confirmLabel: 'Delete Invoice',
      isDanger: true,
      onConfirmAction: (enteredPin) => _saleRepository.deleteSale(_sale.id, securityPin: enteredPin),
    );

    if (pin == null || pin.isEmpty) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice ${_sale.invoiceNumber} deleted successfully.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_sale.paymentStatus);
    final statusLabel = _getStatusLabel(_sale.paymentStatus);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Invoice #${_sale.invoiceNumber}', overflow: TextOverflow.ellipsis),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          const ProfitVisibilityToggle(),
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              onPressed: _editSale,
              tooltip: 'Edit Invoice (Admin PIN Required)',
            ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            onPressed: () => SaleInvoicePdfScreen.show(context, _sale),
            tooltip: 'Print / View PDF Invoice',
          ),
          IconButton(
            icon: const WhatsAppIcon(size: 22),
            onPressed: () => WhatsAppHelper.sendSaleWhatsAppMessage(context, _sale),
            tooltip: 'Send WhatsApp Bill',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            tooltip: 'More Options',
            onSelected: (value) {
              if (value == 'refresh') {
                _refreshDetails();
              } else if (value == 'edit') {
                _editSale();
              } else if (value == 'delete') {
                _confirmDeleteSale();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 20, color: AppColors.textPrimary),
                    SizedBox(width: 10),
                    Text('Refresh Invoice'),
                  ],
                ),
              ),
              if (_isOwner)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 20, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text('Edit Invoice'),
                    ],
                  ),
                ),
              if (_isOwner)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                      SizedBox(width: 10),
                      Text('Delete Invoice', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? AppShimmer.detailsLoading()
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
                                  'Date: ${DateHelper.formatSmart(_sale.saleDate)}',
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.person_rounded, color: AppColors.accent, size: 18),
                                SizedBox(width: 8),
                                Text('Customer Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (_sale.customer?.mobile.isNotEmpty == true || (_sale.customerMobile != null && _sale.customerMobile!.isNotEmpty)) ...[
                              InkWell(
                                onTap: () => WhatsAppHelper.sendSaleWhatsAppMessage(context, _sale),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
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

                  // Warranty Status Card
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: _sale.warranty != null
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
                                      color: _sale.warranty!.status == 'active' ? Colors.green.shade100 : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _sale.warranty!.status.toUpperCase(),
                                      style: TextStyle(
                                        color: _sale.warranty!.status == 'active' ? Colors.green.shade900 : Colors.orange.shade900,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Warranty #: ${_sale.warranty!.warrantyNumber}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Valid until: ${DateHelper.formatDate(_sale.warranty!.warrantyEndDate)} (${_sale.warranty!.daysRemaining} days remaining)',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              if (_sale.warranty!.warrantyTerms != null && _sale.warranty!.warrantyTerms!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Coverage: ${_sale.warranty!.warrantyTerms}',
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
                                        builder: (_) => WarrantyDetailsScreen(warranty: _sale.warranty!),
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
                                          Text('Add a warranty for this sale', style: TextStyle(fontSize: 11, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final newW = await QuickWarrantyModal.show(context, sale: _sale);
                                  if (newW != null) {
                                    setState(() {
                                      _sale = _sale.copyWith(warranty: newW);
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
                  const SizedBox(height: 14),
                  // Line Items Table
                  const Text('Invoice Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  CustomCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Row(
                          children: [
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
                                       if ((item.brand != null || item.model != null) &&
                                           !item.productName.toLowerCase().contains((item.brand ?? '').toLowerCase()) &&
                                           !item.productName.toLowerCase().contains((item.model ?? '').toLowerCase()))
                                         Text('${item.brand ?? ''} ${item.model ?? ''}'.trim(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      if (item.imei1 != null)
                                        Text('IMEI: ${item.imei1}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                      if (_isOwner && item.costPrice != null && item.costPrice! > 0) ...[
                                        const SizedBox(height: 2),
                                        ValueListenableBuilder<bool>(
                                          valueListenable: ProfitVisibilityService().isHiddenNotifier,
                                          builder: (context, _, __) {
                                            // For inclusive tax, the net revenue of this item is total - taxAmount
                                            final taxableRevenue = item.taxType == 'inclusive' && item.taxAmount > 0
                                                ? (item.total - item.taxAmount)
                                                : item.total;
                                            final totalCost = item.costPrice! * item.quantity;
                                            final profitVal = taxableRevenue - totalCost;
                                            final isProfit = profitVal >= 0;
                                            return Text(
                                              'Cost: ${ProfitVisibilityService().format(totalCost, decimals: 0)} \u2022 ${isProfit ? "Profit" : "Loss"}: ${ProfitVisibilityService().format(profitVal, showSign: true, decimals: 0)}',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: isProfit ? const Color(0xFF047857) : const Color(0xFFDC2626),
                                                fontWeight: FontWeight.w600,
                                             ),
                                            );
                                          },
                                        ),
                                      ],
                                       if (item.taxRate > 0 || item.taxAmount > 0) ...[
                                         const SizedBox(height: 3),
                                         Container(
                                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                           decoration: BoxDecoration(
                                             color: AppColors.primary.withOpacity(0.08),
                                             borderRadius: BorderRadius.circular(4),
                                             border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 0.8),
                                           ),
                                           child: Text(
                                             item.taxType == 'inclusive'
                                                 ? '${item.taxRate.toStringAsFixed(item.taxRate % 1 == 0 ? 0 : 1)}% GST Incl. (₹${item.taxAmount.toStringAsFixed(2)})'
                                                 : '+${item.taxRate.toStringAsFixed(item.taxRate % 1 == 0 ? 0 : 1)}% GST Extra (+₹${item.taxAmount.toStringAsFixed(2)})',
                                             style: const TextStyle(fontSize: 9.5, color: AppColors.primary, fontWeight: FontWeight.bold),
                                           ),
                                         ),
                                       ],
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
                    child: Builder(
                      builder: (context) {
                        final itemsTaxSum = _sale.items.fold<double>(0.0, (sum, i) => sum + i.taxAmount);
                        final hasTax = _sale.taxAmount > 0 || _sale.taxRate > 0 || itemsTaxSum > 0;
                        final displayTaxAmount = _sale.taxAmount > 0 ? _sale.taxAmount : itemsTaxSum;
                        final displayTaxRate = _sale.taxRate > 0
                            ? _sale.taxRate
                            : (_sale.items.any((i) => i.taxRate > 0) ? _sale.items.firstWhere((i) => i.taxRate > 0).taxRate : 0.0);
                        final displayTaxType = _sale.taxRate > 0
                            ? _sale.taxType
                            : (_sale.items.any((i) => i.taxRate > 0) ? _sale.items.firstWhere((i) => i.taxRate > 0).taxType : 'exclusive');
                        final displayCgst = _sale.cgstAmount > 0 ? _sale.cgstAmount : (_sale.isInterState ? 0.0 : displayTaxAmount / 2);
                        final displaySgst = _sale.sgstAmount > 0 ? _sale.sgstAmount : (_sale.isInterState ? 0.0 : displayTaxAmount / 2);
                        final displayIgst = _sale.igstAmount > 0 ? _sale.igstAmount : (_sale.isInterState ? displayTaxAmount : 0.0);

                        final taxableBase = displayTaxType == 'inclusive'
                            ? (_sale.subtotal - _sale.totalDiscount - displayTaxAmount > 0 ? _sale.subtotal - _sale.totalDiscount - displayTaxAmount : 0.0)
                            : (_sale.subtotal - _sale.totalDiscount > 0 ? _sale.subtotal - _sale.totalDiscount : 0.0);

                        final isProfitable = _sale.netProfit >= 0;

                        return Column(
                          children: [
                            if (displayTaxType == 'inclusive' && hasTax) ...[
                              _buildRow('Taxable Base (Subtotal)', '₹ ${taxableBase.toStringAsFixed(2)}'),
                              if (_sale.totalDiscount > 0)
                                _buildRow('Total Discount', '- ₹ ${_sale.totalDiscount.toStringAsFixed(2)}', color: Colors.green.shade700, isBold: true),
                            ] else ...[
                              _buildRow('Subtotal', '₹ ${_sale.subtotal.toStringAsFixed(2)}'),
                              if (_sale.totalDiscount > 0)
                                _buildRow('Total Discount', '- ₹ ${_sale.totalDiscount.toStringAsFixed(2)}', color: Colors.green.shade700, isBold: true),
                            ],
                            if (hasTax) ...[
                              Container(
                                margin: const EdgeInsets.only(top: 8, bottom: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.receipt_long_rounded, size: 14, color: AppColors.primary),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            'GST Breakdown (${displayTaxRate.toStringAsFixed(displayTaxRate % 1 == 0 ? 0 : 1)}%)',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: displayTaxType == 'inclusive' ? const Color(0xFFEFF6FF) : const Color(0xFFFAF5FF),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: displayTaxType == 'inclusive' ? const Color(0xFFBFDBFE) : const Color(0xFFE9D5FF),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            displayTaxType == 'inclusive' ? 'Incl. in Price' : 'Added to Price',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: displayTaxType == 'inclusive' ? const Color(0xFF1D4ED8) : const Color(0xFF7E22CE),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 14, thickness: 0.7),
                                    if (displayTaxType == 'inclusive') ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        margin: const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Tax is included in product price: Base ₹${taxableBase.toStringAsFixed(2)} + GST ₹${displayTaxAmount.toStringAsFixed(2)} = ₹${_sale.grandTotal.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                    if (_sale.isInterState) ...[
                                      _buildRow(
                                        'IGST (${displayTaxRate.toStringAsFixed(displayTaxRate % 1 == 0 ? 0 : 1)}%)',
                                        '${displayTaxType == 'exclusive' ? "+ " : ""}₹ ${displayIgst.toStringAsFixed(2)}',
                                        fontSize: 12,
                                        color: AppColors.primary,
                                      ),
                                    ] else ...[
                                      _buildRow(
                                        'CGST (${(displayTaxRate / 2).toStringAsFixed((displayTaxRate / 2) % 1 == 0 ? 0 : 1)}%)',
                                        '${displayTaxType == 'exclusive' ? "+ " : ""}₹ ${displayCgst.toStringAsFixed(2)}',
                                        fontSize: 12,
                                        color: Colors.teal.shade800,
                                      ),
                                      const SizedBox(height: 3),
                                      _buildRow(
                                        'SGST (${(displayTaxRate / 2).toStringAsFixed((displayTaxRate / 2) % 1 == 0 ? 0 : 1)}%)',
                                        '${displayTaxType == 'exclusive' ? "+ " : ""}₹ ${displaySgst.toStringAsFixed(2)}',
                                        fontSize: 12,
                                        color: Colors.teal.shade800,
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    const Divider(height: 8, thickness: 0.5),
                                    _buildRow(
                                      'Total GST Amount',
                                      '₹ ${displayTaxAmount.toStringAsFixed(2)}',
                                      isBold: true,
                                      fontSize: 12.5,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const Divider(height: 20),
                            _buildRow('GRAND TOTAL', '₹ ${_sale.grandTotal.toStringAsFixed(2)}', isBold: true, fontSize: 18),
                            const SizedBox(height: 6),
                            _buildRow('Amount Paid', '₹ ${_sale.amountPaid.toStringAsFixed(2)}', color: Colors.green.shade700, isBold: true),
                            const SizedBox(height: 6),
                            _buildRow('AMOUNT DUE', '\u20B9 ${_sale.amountDue.toStringAsFixed(2)}', color: _sale.amountDue > 0 ? Colors.red.shade700 : Colors.green.shade700, isBold: true, fontSize: 18),
                            if (_isOwner) ...[
                              const Divider(height: 20),
                              ValueListenableBuilder<bool>(
                                valueListenable: ProfitVisibilityService().isHiddenNotifier,
                                builder: (context, _, __) {
                                  return _buildRow(
                                    'Item Purchase Cost',
                                    ProfitVisibilityService().format(_sale.totalCost, prefix: '₹ ', decimals: 2),
                                    color: AppColors.textSecondary,
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              // Net Profit / Loss Box
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _sale.amountPaid > 0
                                      ? (isProfitable ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2))
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _sale.amountPaid > 0
                                        ? (isProfitable ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA))
                                        : const Color(0xFFE2E8F0),
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isProfitable ? Icons.monetization_on_rounded : Icons.trending_down_rounded,
                                              size: 18,
                                              color: _sale.amountPaid > 0
                                                  ? (isProfitable ? const Color(0xFF059669) : const Color(0xFFDC2626))
                                                  : AppColors.textMuted,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isProfitable ? 'Realized Net Profit' : 'Loss on Sale',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: isProfitable ? const Color(0xFF047857) : const Color(0xFFDC2626),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            ProfitText(
                                              amount: _sale.amountPaid > 0 ? _sale.netProfit : 0.0,
                                              prefix: '₹ ',
                                              showSign: _sale.amountPaid > 0 && isProfitable,
                                              decimals: 2,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color: _sale.amountPaid > 0
                                                    ? (isProfitable ? const Color(0xFF059669) : const Color(0xFFDC2626))
                                                    : AppColors.textMuted,
                                              ),
                                            ),
                                            ValueListenableBuilder<bool>(
                                              valueListenable: ProfitVisibilityService().isHiddenNotifier,
                                              builder: (context, isHidden, _) {
                                                if (isHidden || _sale.amountPaid <= 0 || _sale.profitMarginPercent <= 0 || !isProfitable) {
                                                  return const SizedBox.shrink();
                                                }
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF059669),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '${_sale.profitMarginPercent.toStringAsFixed(0)}% Margin',
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (hasTax) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Excludes ₹${displayTaxAmount.toStringAsFixed(2)} GST tax paid to government',
                                        style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                    if (_sale.amountDue > 0) ...[
                                      const SizedBox(height: 6),
                                      const Divider(height: 1),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Expanded(
                                            child: Text(
                                              'Expected Profit (Full Payment)',
                                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ProfitText(
                                            amount: _sale.expectedNetProfit,
                                            prefix: '₹ ',
                                            decimals: 2,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // PDF & WhatsApp Action Buttons Card
                  CustomCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => SaleInvoicePdfScreen.show(context, _sale),
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                            label: const Text('PDF Bill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => WhatsAppHelper.sendSaleWhatsAppMessage(context, _sale),
                            icon: const WhatsAppIcon(size: 18, showBackground: false),
                            label: const Text('WhatsApp Bill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
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
                                            DateHelper.formatSmart(p.paymentDate),
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
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
