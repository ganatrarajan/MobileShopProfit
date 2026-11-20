import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/profit_visibility_service.dart';
import '../../../../core/storage/auth_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/date_helper.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import '../../../../core/widgets/whatsapp_icon.dart';
import '../data/used_mobile_repository.dart';
import '../models/used_mobile.dart';
import 'buy_used_mobile_screen.dart';
import 'used_mobile_pdf_screen.dart';
import 'widgets/add_repair_expense_modal.dart';
import 'widgets/sell_used_mobile_modal.dart';
import 'widgets/collect_used_mobile_payment_dialog.dart';

class UsedMobileDetailsScreen extends StatefulWidget {
  final UsedMobile mobile;

  const UsedMobileDetailsScreen({super.key, required this.mobile});

  @override
  State<UsedMobileDetailsScreen> createState() => _UsedMobileDetailsScreenState();
}

class _UsedMobileDetailsScreenState extends State<UsedMobileDetailsScreen> {
  late UsedMobile _mobile;
  final UsedMobileRepository _repo = UsedMobileRepository();
  bool _isLoading = false;
  bool _isOwner = true;

  @override
  void initState() {
    super.initState();
    _isOwner = ProfitVisibilityService().isOwner;
    AuthStorage().isOwner().then((val) {
      if (mounted && _isOwner != val) setState(() => _isOwner = val);
    });
    _mobile = widget.mobile;
    _refreshDetails();
  }

  Future<void> _refreshDetails() async {
    final updated = await _repo.getDetails(_mobile.id);
    if (updated != null && mounted) {
      setState(() => _mobile = updated);
    }
  }

  Future<void> _deleteMobile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Used Mobile Entry?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete ${_mobile.deviceDisplayName} (#${_mobile.purchaseRefNumber})? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final res = await _repo.deleteUsedMobile(_mobile.id);
    setState(() => _isLoading = false);

    if (res.success) {
      if (!mounted) return;
      AppFeedback.showSuccess(
        context,
        title: '🗑️ Device Deleted',
        message: '${_mobile.deviceDisplayName} record removed successfully.',
      );
      Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        title: '❌ Deletion Failed',
        message: res.message.isNotEmpty ? res.message : 'Failed to delete record.',
      );
    }
  }

  void _showFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSold = _mobile.isSold;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _mobile.purchaseRefNumber,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (!_mobile.isSold)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              tooltip: 'Edit Details',
              onPressed: () async {
                final result = await Navigator.push<UsedMobile>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BuyUsedMobileScreen(mobileToEdit: _mobile),
                  ),
                );
                if (result != null) {
                  setState(() => _mobile = result);
                }
              },
            ),
          if (!_mobile.isSold)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              tooltip: 'Delete Entry',
              onPressed: _deleteMobile,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Banner with Device Info & Status
                    _buildDeviceHeader(isDark),

                    const SizedBox(height: 16),

                    // Financial Summary & Profit Card
                    _buildFinancialCard(isDark),

                    const SizedBox(height: 16),

                    // Quick Action Buttons
                    _buildQuickActionButtons(context),

                    const SizedBox(height: 16),

                    // Specifications & IMEI Card
                    _buildDeviceSpecsCard(isDark),

                    const SizedBox(height: 16),

                    // Seller Verification & Police Compliance Card
                    _buildSellerCard(isDark),

                    if (isSold) ...[
                      const SizedBox(height: 16),
                      // Buyer & Warranty Card
                      _buildBuyerCard(isDark),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: !isSold
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: Colors.orange.shade700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(Icons.build_rounded, size: 18, color: Colors.orange.shade700),
                      label: Text(
                        'Repair Cost',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                      ),
                      onPressed: () {
                        AddRepairExpenseModal.show(context, _mobile, onExpenseAdded: _refreshDetails);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.bolt_rounded, size: 20),
                      label: const Text('Sell This Mobile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      onPressed: () {
                        SellUsedMobileModal.show(context, _mobile, onSaleComplete: _refreshDetails);
                      },
                    ),
                  ),
                ],
              ),
            )
          : (_mobile.hasDue
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3)),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.payments_rounded, size: 20),
                    label: Text(
                      'Collect Due Payment (₹${_mobile.effectiveAmountDue.toStringAsFixed(0)})',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    onPressed: () {
                      CollectUsedMobilePaymentDialog.show(context, mobile: _mobile, onPaymentRecorded: _refreshDetails);
                    },
                  ),
                )
              : null),
    );
  }

  Widget _buildDeviceHeader(bool isDark) {
    final isSold = _mobile.isSold;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSold ? AppColors.accent.withOpacity(0.15) : AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSold ? 'SOLD (#${_mobile.saleInvoiceNumber})' : 'IN STOCK',
                  style: TextStyle(
                    color: isSold ? AppColors.accent : AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Purchased ${DateHelper.formatDate(_mobile.purchaseDate.toIso8601String())}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _mobile.deviceDisplayName,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.qr_code_2_rounded, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                _mobile.imei1.isNotEmpty ? 'IMEI: ${_mobile.imei1}' : 'IMEI: Not recorded',
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_mobile.imei1.isNotEmpty)
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _mobile.imei1));
                    AppFeedback.showSuccess(
                      context,
                      title: '📋 Copied',
                      message: 'IMEI copied to clipboard: ${_mobile.imei1}',
                      duration: const Duration(seconds: 2),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(bool isDark) {
    final isSold = _mobile.isSold;
    final profit = _mobile.profit ?? 0.0;
    final roi = _mobile.profitPercentage;

    if (!_isOwner) {
      if (!isSold) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sale Information',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _metricItem('Sold Price', _mobile.sellingPrice ?? 0.0, AppColors.textPrimary, isBold: true)),
                if (_mobile.hasSaleTax)
                  Expanded(
                    child: _metricItem(
                      'Sale Tax (${_mobile.taxRate.toStringAsFixed(0)}%)',
                      _mobile.taxAmount,
                      Colors.green,
                      isBold: true,
                    ),
                  ),
              ],
            ),
            if (_mobile.hasSaleTax) ...[
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _mobile.isInterState
                        ? 'IGST: ₹${_mobile.igstAmount.toStringAsFixed(2)}'
                        : 'CGST: ₹${_mobile.cgstAmount.toStringAsFixed(2)} | SGST: ₹${_mobile.sgstAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                  if (_mobile.taxType == 'exclusive')
                    Text(
                      'Total Billed: ₹${((_mobile.sellingPrice ?? 0.0) + _mobile.taxAmount).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Financial & Profit Breakdown',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSold) ...[
                const SizedBox(width: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: ProfitVisibilityService().isHiddenNotifier,
                  builder: (context, isHidden, _) {
                    if (isHidden) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: profit >= 0 ? AppColors.accentLight : AppColors.errorLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        profit >= 0 ? '+${roi.toStringAsFixed(1)}% ROI' : '${roi.toStringAsFixed(1)}% Loss',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: profit >= 0 ? Colors.green.shade900 : Colors.red.shade900,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _metricItem('Purchase Cost', _mobile.purchasePrice, Colors.blueGrey)),
              Expanded(child: _metricItem('Repair Expense', _mobile.repairCost, Colors.orange)),
              Expanded(child: _metricItem('Total Invested', _mobile.totalCost, AppColors.primary, isBold: true)),
            ],
          ),
          if (isSold) ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(child: _metricItem('Sold Price', _mobile.sellingPrice ?? 0.0, AppColors.textPrimary, isBold: true)),
                Expanded(
                  child: _metricItem(
                    profit >= 0 ? 'Net Profit Earned' : 'Loss on Deal',
                    profit.abs(),
                    profit >= 0 ? AppColors.accent : AppColors.error,
                    isBold: true,
                    prefix: profit >= 0 ? '+₹' : '-₹',
                    isProfit: true,
                  ),
                ),
              ],
            ),
          ],
          if (_mobile.hasPurchaseTax || (isSold && _mobile.hasSaleTax)) ...[
            const Divider(height: 20),
            if (_mobile.hasPurchaseTax) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Purchase GST (${_mobile.purchaseTaxRate.toStringAsFixed(0)}% ${_mobile.purchaseTaxType == "inclusive" ? "Incl." : "Excl."})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    '₹${_mobile.purchaseTaxAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _mobile.purchaseIsInterState
                    ? 'IGST: ₹${_mobile.purchaseIgstAmount.toStringAsFixed(2)}'
                    : 'CGST: ₹${_mobile.purchaseCgstAmount.toStringAsFixed(2)} | SGST: ₹${_mobile.purchaseSgstAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
              if (isSold && _mobile.hasSaleTax) const SizedBox(height: 6),
            ],
            if (isSold && _mobile.hasSaleTax) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_rounded, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Sale GST (${_mobile.taxRate.toStringAsFixed(0)}% ${_mobile.taxType == "inclusive" ? "Incl." : "Excl."})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    '₹${_mobile.taxAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _mobile.isInterState
                        ? 'IGST: ₹${_mobile.igstAmount.toStringAsFixed(2)}'
                        : 'CGST: ₹${_mobile.cgstAmount.toStringAsFixed(2)} | SGST: ₹${_mobile.sgstAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                  if (_mobile.taxType == 'exclusive')
                    Text(
                      'Total Billed: ₹${((_mobile.sellingPrice ?? 0.0) + _mobile.taxAmount).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _metricItem(String label, double amount, Color color, {bool isBold = false, String prefix = '₹', bool isProfit = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 3),
        if (isProfit)
          ProfitText(
            amount: amount,
            prefix: prefix,
            decimals: 0,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.bold,
              color: color,
            ),
          )
        else
          Text(
            '$prefix${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.bold,
              color: color,
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActionButtons(BuildContext context) {
    final isSold = _mobile.isSold;

    if (!isSold) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text(
                'Purchase Agreement PDF',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () {
                UsedMobilePdfScreen.show(context, _mobile, UsedMobilePdfType.purchaseAgreement);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const WhatsAppIcon(size: 18, color: Colors.white),
              label: const Text(
                'WhatsApp to Seller',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () {
                WhatsAppHelper.sendUsedMobilePurchaseWhatsAppMessage(context, _mobile);
              },
            ),
          ),
        ],
      );
    }

    // When SOLD: Show dedicated Buyer documents & Seller documents
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.print_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'Invoices & WhatsApp Slips',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Buyer Actions Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: const Text(
                    'Buyer Invoice PDF',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () {
                    UsedMobilePdfScreen.show(context, _mobile, UsedMobilePdfType.saleInvoice);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const WhatsAppIcon(size: 16, color: Colors.white),
                  label: const Text(
                    'WhatsApp to Buyer',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () {
                    WhatsAppHelper.sendUsedMobileSaleWhatsAppMessage(context, _mobile);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Seller Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppColors.primary),
                  label: const Text(
                    'Seller Agreement PDF',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () {
                    UsedMobilePdfScreen.show(context, _mobile, UsedMobilePdfType.purchaseAgreement);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const WhatsAppIcon(size: 16),
                  label: const Text(
                    'WhatsApp to Seller',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () {
                    WhatsAppHelper.sendUsedMobilePurchaseWhatsAppMessage(context, _mobile);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSpecsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Device Condition & Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 12),
          _detailRow('Condition', _mobile.conditionLabel),
          if (_mobile.conditionNotes != null && _mobile.conditionNotes!.isNotEmpty)
            _detailRow('Faults / Notes', _mobile.conditionNotes!),
          if (_mobile.color != null) _detailRow('Color', _mobile.color!),
          if (_mobile.ram != null || _mobile.storage != null)
            _detailRow('Configuration', '${_mobile.ram ?? ''} / ${_mobile.storage ?? ''}'),
          if (_mobile.batteryHealth != null) _detailRow('Battery Health', _mobile.batteryHealth!),
          if (_mobile.imei2 != null && _mobile.imei2!.isNotEmpty) _detailRow('Secondary IMEI 2', _mobile.imei2!),
          if (_mobile.accessoriesIncluded.isNotEmpty)
            _detailRow('Accessories Handed', _mobile.accessoriesIncluded.join(', ')),
          if (_mobile.repairDetails != null && _mobile.repairDetails!.isNotEmpty)
            _detailRow('Repair Logged', '${_mobile.repairDetails} (₹${_mobile.repairCost.toStringAsFixed(0)})'),
        ],
      ),
    );
  }

  Widget _buildSellerCard(bool isDark) {
    final hasFront = _mobile.idProofImagePath != null && _mobile.idProofImagePath!.isNotEmpty;
    final hasBack = _mobile.idProofBackImagePath != null && _mobile.idProofBackImagePath!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Seller Verification (Original Owner)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const WhatsAppIcon(size: 18),
                    tooltip: 'WhatsApp Seller',
                    onPressed: () => WhatsAppHelper.sendUsedMobilePurchaseWhatsAppMessage(context, _mobile),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.phone_rounded, color: AppColors.accent, size: 20),
                    tooltip: 'Call Seller',
                    onPressed: () => launchUrl(Uri.parse('tel:${_mobile.sellerPhone}')),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow('Seller Name', _mobile.sellerName),
          _detailRow('Mobile Number', _mobile.sellerPhone),
          if (_mobile.sellerAddress != null && _mobile.sellerAddress!.isNotEmpty)
            _detailRow('Address', _mobile.sellerAddress!),
          _detailRow(
            'Govt ID Proof',
            (_mobile.idProofNumber != null && _mobile.idProofNumber!.isNotEmpty)
                ? '${_mobile.idProofType ?? 'ID'}: ${_mobile.idProofNumber}'
                : 'Not Provided',
          ),
          if (hasFront || hasBack) ...[
            const SizedBox(height: 12),
            const Text(
              'Govt ID Document Proof Photos (Tap to Zoom):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (hasFront)
                  Expanded(
                    child: _buildDocPhotoThumb(
                      title: 'Front Side (Photo & ID)',
                      imageUrl: _mobile.idProofImagePath!,
                      isDark: isDark,
                    ),
                  ),
                if (hasFront && hasBack) const SizedBox(width: 10),
                if (hasBack)
                  Expanded(
                    child: _buildDocPhotoThumb(
                      title: 'Back Side (Address)',
                      imageUrl: _mobile.idProofBackImagePath!,
                      isDark: isDark,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          _detailRow('Payment Mode', _mobile.paymentMode),
          if (_mobile.purchaseNotes != null && _mobile.purchaseNotes!.isNotEmpty)
            _detailRow('Purchase Notes', _mobile.purchaseNotes!),
        ],
      ),
    );
  }

  Widget _buildDocPhotoThumb({
    required String title,
    required String imageUrl,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => _showFullImageDialog(context, imageUrl),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              child: SizedBox(
                height: 105,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 28),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.inputFill,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.zoom_in_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyerCard(bool isDark) {
    Color badgeBg;
    Color badgeText;
    String statusLabel;
    if (_mobile.isPaid) {
      badgeBg = Colors.green.withOpacity(0.12);
      badgeText = Colors.green.shade700;
      statusLabel = 'PAID IN FULL';
    } else if (_mobile.isPartiallyPaid) {
      badgeBg = Colors.amber.withOpacity(0.15);
      badgeText = Colors.amber.shade900;
      statusLabel = 'PARTIALLY PAID';
    } else {
      badgeBg = Colors.red.withOpacity(0.12);
      badgeText = Colors.red.shade700;
      statusLabel = 'PAYMENT DUE';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Buyer & Sale Information',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: badgeText),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_mobile.buyerPhone != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const WhatsAppIcon(size: 18),
                      tooltip: 'WhatsApp Buyer',
                      onPressed: () => WhatsAppHelper.sendUsedMobileSaleWhatsAppMessage(context, _mobile),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.phone_rounded, color: AppColors.accent, size: 20),
                      tooltip: 'Call Buyer',
                      onPressed: () => launchUrl(Uri.parse('tel:${_mobile.buyerPhone}')),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow('Buyer Name', _mobile.buyerName ?? 'Customer'),
          if (_mobile.buyerPhone != null) _detailRow('Mobile Number', _mobile.buyerPhone!),
          if (_mobile.buyerAddress != null) _detailRow('Address', _mobile.buyerAddress!),
          if (_mobile.saleDate != null)
            _detailRow('Sale Date', DateHelper.formatDate(_mobile.saleDate!.toIso8601String())),
          _detailRow('Sale Price', '₹${_mobile.effectiveSellingPrice.toStringAsFixed(2)}'),
          _detailRow('Amount Paid', '₹${_mobile.effectiveAmountPaid.toStringAsFixed(2)}'),
          if (_mobile.hasDue) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 120,
                    child: Text(
                      'Balance Due',
                      style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${_mobile.effectiveAmountDue.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.error),
                        ),
                        InkWell(
                          onTap: () {
                            CollectUsedMobilePaymentDialog.show(context, mobile: _mobile, onPaymentRecorded: _refreshDetails);
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_circle_outline, size: 13, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Collect',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          _detailRow('Payment Mode', _mobile.salePaymentMode ?? 'Cash'),
          if (_mobile.warrantyDays != null && _mobile.warrantyDays! > 0)
            _detailRow('Testing Warranty', '${_mobile.warrantyDays} Days Guarantee'),
          if (_mobile.warrantyTerms != null && _mobile.warrantyTerms!.isNotEmpty)
            _detailRow('Warranty Terms', _mobile.warrantyTerms!),
          if (_mobile.saleNotes != null && _mobile.saleNotes!.isNotEmpty)
            _detailRow('Sale Notes', _mobile.saleNotes!),

          // Payment Installments History
          if (_mobile.payments.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment History',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                Text(
                  '${_mobile.payments.length} receipt${_mobile.payments.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mobile.payments.length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (ctx, i) {
                final p = _mobile.payments[i];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateHelper.formatDate(p.paymentDate.toIso8601String()),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${p.paymentMode}${p.notes != null && p.notes!.isNotEmpty ? ' • ${p.notes}' : ''}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    Text(
                      '+₹${p.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.green),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
