import 'package:flutter/material.dart';
import '../../../../core/services/profit_visibility_service.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/date_helper.dart';
import '../../../../core/utils/gst_calculator.dart';
import '../../../../core/widgets/app_searchable_bottom_sheet.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/gst_input_card.dart';
import '../../data/used_mobile_repository.dart';
import '../../models/used_mobile.dart';

class SellUsedMobileModal extends StatefulWidget {
  final UsedMobile mobile;
  final VoidCallback? onSaleComplete;

  const SellUsedMobileModal({
    super.key,
    required this.mobile,
    this.onSaleComplete,
  });

  static Future<bool?> show(BuildContext context, UsedMobile mobile, {VoidCallback? onSaleComplete}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SellUsedMobileModal(
        mobile: mobile,
        onSaleComplete: onSaleComplete,
      ),
    );
  }

  @override
  State<SellUsedMobileModal> createState() => _SellUsedMobileModalState();
}

class _SellUsedMobileModalState extends State<SellUsedMobileModal> {
  final _formKey = GlobalKey<FormState>();
  final _buyerNameController = TextEditingController();
  final _buyerPhoneController = TextEditingController();
  final _buyerAddressController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _customWarrantyController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final _notesController = TextEditingController();

  final UsedMobileRepository _repo = UsedMobileRepository();

  DateTime _saleDate = DateTime.now();
  String _paymentMode = 'Cash';
  int _warrantyDays = 15;
  bool _isCustomWarranty = false;
  bool _isPartialPayment = false;
  bool _isLoading = false;
  bool _isOwner = true;

  // Optional GST / Tax
  bool _gstEnabled = false;
  GstMode _gstMode = GstMode.inclusive;
  double _gstRate = 18.0;
  bool _gstIsInterState = false;
  GstCalculationResult? _gstResult;

  final List<String> _paymentModes = ['Cash', 'UPI / GPay / PhonePe', 'Debit/Credit Card', 'Bank Transfer'];
  final List<int> _warrantyOptions = [0, 7, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    _isOwner = ProfitVisibilityService().isOwner;
    AuthStorage().isOwner().then((val) {
      if (mounted && _isOwner != val) setState(() => _isOwner = val);
    });
    // If selling price was already estimated or mobile is sold
    if (widget.mobile.sellingPrice != null && widget.mobile.sellingPrice! > 0) {
      _sellingPriceController.text = widget.mobile.sellingPrice!.toStringAsFixed(0);
    }
    if (widget.mobile.hasSaleTax) {
      _gstEnabled = true;
      _gstRate = widget.mobile.taxRate > 0 ? widget.mobile.taxRate : 18.0;
      _gstMode = widget.mobile.taxType == 'exclusive' ? GstMode.exclusive : GstMode.inclusive;
      _gstIsInterState = widget.mobile.isInterState;
    }
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _buyerAddressController.dispose();
    _sellingPriceController.dispose();
    _customWarrantyController.dispose();
    _amountPaidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _sellingPrice {
    final text = _sellingPriceController.text.trim();
    return double.tryParse(text) ?? 0.0;
  }

  GstCalculationResult get _currentGstResult {
    if (!_gstEnabled || _sellingPrice <= 0) {
      return GstCalculationResult.disabled(amount: _sellingPrice);
    }
    return _gstResult ??
        GstCalculator.calculate(
          amount: _sellingPrice,
          rate: _gstRate,
          mode: _gstMode,
          isInterState: _gstIsInterState,
          isEnabled: _gstEnabled,
        );
  }

  double get _finalPayable => _gstEnabled && _gstMode == GstMode.exclusive
      ? _currentGstResult.totalPayable
      : _sellingPrice;

  double get _totalCost => widget.mobile.totalCost;

  // Net revenue that belongs to the shop (excludes GST tax that must be paid to government)
  double get _netSellingRevenue {
    if (!_gstEnabled || _sellingPrice <= 0) return _sellingPrice;
    return _gstMode == GstMode.inclusive
        ? _currentGstResult.taxableAmount
        : _sellingPrice;
  }

  // Realized Net Profit (Net Revenue minus Total Cost)
  double get _calculatedProfit => _netSellingRevenue - _totalCost;
  double get _calculatedRoi => _totalCost > 0 ? (_calculatedProfit / _totalCost * 100) : 0.0;

  Future<void> _submitSale() async {
    _formKey.currentState?.validate();

    final buyerName = _buyerNameController.text.trim();
    if (buyerName.isEmpty) {
      AppFeedback.showError(
        context,
        title: 'Customer Name Required',
        message: 'Please enter Buyer / Customer Name *.',
      );
      return;
    }

    final buyerPhone = _buyerPhoneController.text.trim();
    final cleanBuyerPhone = buyerPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanBuyerPhone.isEmpty) {
      AppFeedback.showError(
        context,
        title: 'Mobile Number Required',
        message: 'Please enter Customer 10-digit mobile number *.',
      );
      return;
    }
    if (cleanBuyerPhone.length < 10) {
      AppFeedback.showError(
        context,
        title: 'Invalid Mobile Number',
        message: 'Customer mobile number must be 10 digits (currently ${cleanBuyerPhone.length} digits).',
      );
      return;
    }

    final sellingPrice = _sellingPrice;
    if (sellingPrice <= 0) {
      AppFeedback.showError(
        context,
        title: 'Selling Price Required',
        message: 'Selling price must be greater than ₹0.',
      );
      return;
    }

    double amountPaid = _finalPayable;
    if (_isPartialPayment) {
      final parsed = double.tryParse(_amountPaidController.text.trim());
      if (parsed == null || parsed < 0) {
        AppFeedback.showError(
          context,
          title: 'Invalid Paid Amount',
          message: 'Please enter a valid amount received now.',
        );
        return;
      }
      if (parsed > _finalPayable) {
        AppFeedback.showError(
          context,
          title: 'Amount Exceeds Total',
          message: 'Amount paid cannot exceed total payable amount (₹${_finalPayable.toStringAsFixed(2)}).',
        );
        return;
      }
      amountPaid = parsed;
    }

    final int selectedWarranty = _isCustomWarranty
        ? (int.tryParse(_customWarrantyController.text.trim()) ?? 0)
        : _warrantyDays;

    setState(() => _isLoading = true);

    final currentGst = _currentGstResult;

    final payload = {
      'buyer_name': _buyerNameController.text.trim(),
      'buyer_phone': buyerPhone,
      if (_buyerAddressController.text.trim().isNotEmpty)
        'buyer_address': _buyerAddressController.text.trim(),
      'selling_price': sellingPrice,
      'amount_paid': amountPaid,
      'sale_date': _saleDate.toIso8601String().split('T').first,
      'sale_payment_mode': _paymentMode,
      'warranty_days': selectedWarranty,
      'warranty_terms': selectedWarranty > 0
          ? '$selectedWarranty Days Testing Warranty on Motherboard & Display (Physical/liquid damage excluded)'
          : null,
      if (_notesController.text.trim().isNotEmpty)
        'sale_notes': _notesController.text.trim(),

      // Optional Sale GST
      'tax_rate': _gstEnabled ? currentGst.rate : 0.0,
      'tax_type': _gstEnabled ? (_gstMode == GstMode.exclusive ? 'exclusive' : 'inclusive') : 'inclusive',
      'tax_amount': _gstEnabled ? currentGst.taxAmount : 0.0,
      'cgst_amount': _gstEnabled ? currentGst.cgstAmount : 0.0,
      'sgst_amount': _gstEnabled ? currentGst.sgstAmount : 0.0,
      'igst_amount': _gstEnabled ? currentGst.igstAmount : 0.0,
      'is_inter_state': _gstEnabled && _gstIsInterState,
    };

    final result = await _repo.sellUsedMobile(widget.mobile.id, payload);

    setState(() => _isLoading = false);

    if (result.success && result.data != null) {
      if (!mounted) return;
      final updatedMobile = result.data!;
      Navigator.pop(context, true);
      widget.onSaleComplete?.call();
      AppFeedback.showSuccess(
        context,
        title: '⚡ Quick Sale Completed',
        message: 'Invoice #${updatedMobile.saleInvoiceNumber ?? updatedMobile.id} completed successfully.',
      );
    } else {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        title: 'Sale Failed',
        message: result.message.isNotEmpty ? result.message : 'Failed to record sale. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardPadding),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top handle
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.point_of_sale_rounded, color: AppColors.accent, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sell Second-Hand Mobile',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                            ),
                            Text(
                              'Ref #${widget.mobile.purchaseRefNumber}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Device & Investment Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.mobile.deviceDisplayName,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.mobile.conditionLabel,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (widget.mobile.imei1.isNotEmpty) 'IMEI 1: ${widget.mobile.imei1}',
                          if (widget.mobile.serialNumber != null && widget.mobile.serialNumber!.trim().isNotEmpty)
                            'S/N: ${widget.mobile.serialNumber!.trim()}',
                        ].join('  •  '),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'monospace'),
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _costChip('Purchase Cost', widget.mobile.purchasePrice),
                          _costChip('Repair Spent', widget.mobile.repairCost),
                          _costChip('Total Invested', widget.mobile.totalCost, isHighlight: true),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Buyer Information
                const Text(
                  'Buyer / Customer Details',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),

                CustomTextField(
                  controller: _buyerNameController,
                  label: 'Buyer Full Name *',
                  hint: 'e.g. Ramesh Patel',
                  prefixIcon: Icons.person_rounded,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter buyer name' : null,
                ),
                const SizedBox(height: 10),

                CustomTextField(
                  controller: _buyerPhoneController,
                  label: 'Buyer Mobile Number *',
                  hint: '10-digit mobile number',
                  prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter mobile number' : null,
                ),
                const SizedBox(height: 10),

                CustomTextField(
                  controller: _buyerAddressController,
                  label: 'Buyer Address (Optional)',
                  hint: 'City / Area',
                  prefixIcon: Icons.location_on_outlined,
                ),

                const SizedBox(height: 16),

                // Selling Price Card
                Text(
                  _isOwner ? 'Sale Pricing & Real-Time Profit' : 'Sale Pricing',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),

                CustomTextField(
                  controller: _sellingPriceController,
                  label: _gstEnabled && _gstMode == GstMode.exclusive
                      ? 'Base Selling Price (₹) *'
                      : 'Selling Price (₹) *',
                  hint: _gstEnabled && _gstMode == GstMode.exclusive
                      ? 'Enter base price (GST extra on top)'
                      : 'Enter final price to buyer',
                  prefixIcon: Icons.currency_rupee_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter selling price';
                    final num = double.tryParse(val.trim());
                    if (num == null || num <= 0) return 'Enter valid amount';
                    return null;
                  },
                ),

                const SizedBox(height: 10),

                // Optional GST / Tax Input Card (Defaults to OFF)
                GstInputCard(
                  amount: _sellingPrice,
                  initialEnabled: _gstEnabled,
                  initialMode: _gstMode,
                  initialRate: _gstRate,
                  initialInterState: _gstIsInterState,
                  title: 'Apply GST / Tax (Optional)',
                  onChanged: (result) {
                    setState(() {
                      _gstResult = result;
                      _gstEnabled = result.isEnabled;
                      _gstMode = result.mode;
                      _gstRate = result.rate;
                      _gstIsInterState = result.isInterState;
                    });
                  },
                ),

                // Final Amount to Collect & Billing Summary
                if (_sellingPrice > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _gstEnabled
                            ? AppColors.primary.withOpacity(0.5)
                            : (isDark ? AppColors.darkBorder : AppColors.border),
                        width: _gstEnabled ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_gstEnabled && _currentGstResult.taxAmount > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _gstMode == GstMode.exclusive ? 'Base Price (before tax):' : 'Gross Selling Price:',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '₹${(_gstMode == GstMode.inclusive ? _currentGstResult.taxableAmount : _sellingPrice).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _gstMode == GstMode.exclusive
                                    ? 'GST Added (+${_currentGstResult.rate.toStringAsFixed(0)}%):'
                                    : 'GST Included (${_currentGstResult.rate.toStringAsFixed(0)}%):',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _gstMode == GstMode.exclusive ? AppColors.primary : Colors.teal.shade800,
                                ),
                              ),
                              Text(
                                '${_gstMode == GstMode.exclusive ? "+" : ""}₹${_currentGstResult.taxAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _gstMode == GstMode.exclusive ? AppColors.primary : Colors.teal.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _gstIsInterState
                                ? '  • IGST: ₹${_currentGstResult.igstAmount.toStringAsFixed(2)}'
                                : '  • CGST: ₹${_currentGstResult.cgstAmount.toStringAsFixed(2)} | SGST: ₹${_currentGstResult.sgstAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                          ),
                          const Divider(height: 14),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'FINAL AMOUNT TO COLLECT',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                Text(
                                  _gstEnabled
                                      ? (_gstMode == GstMode.exclusive ? 'Base + GST Tax Total' : 'Price Includes GST')
                                      : 'No GST Applied (Exempt)',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            Text(
                              '₹${_finalPayable.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Payment Type / Partial Payment Option
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Option',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(
                                  child: Text('Full Payment'),
                                ),
                                selected: !_isPartialPayment,
                                onSelected: (sel) {
                                  if (sel) setState(() => _isPartialPayment = false);
                                },
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: !_isPartialPayment ? Colors.white : AppColors.textPrimary,
                                  fontWeight: !_isPartialPayment ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(
                                  child: Text('Partial / Due'),
                                ),
                                selected: _isPartialPayment,
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() {
                                      _isPartialPayment = true;
                                      if (_amountPaidController.text.isEmpty && _finalPayable > 0) {
                                        _amountPaidController.text = (_finalPayable / 2).toStringAsFixed(0);
                                      }
                                    });
                                  }
                                },
                                selectedColor: Colors.orange.shade700,
                                labelStyle: TextStyle(
                                  color: _isPartialPayment ? Colors.white : AppColors.textPrimary,
                                  fontWeight: _isPartialPayment ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_isPartialPayment) ...[
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _amountPaidController,
                            label: 'Amount Received Now (₹) *',
                            hint: 'e.g. 5000',
                            prefixIcon: Icons.payments_outlined,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 8),
                          Builder(builder: (context) {
                            final paid = double.tryParse(_amountPaidController.text.trim()) ?? 0.0;
                            final due = (_finalPayable - paid).clamp(0.0, _finalPayable);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Remaining Due to Collect:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade900)),
                                  Text('₹${due.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ],

                // Live Profit Calculation Card
                if (_isOwner && _sellingPrice > 0) ...[
                  const SizedBox(height: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _calculatedProfit >= 0
                          ? AppColors.accentLight.withOpacity(0.4)
                          : AppColors.errorLight.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _calculatedProfit >= 0 ? AppColors.accent : AppColors.error,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _calculatedProfit >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                              color: _calculatedProfit >= 0 ? AppColors.accent : AppColors.error,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _calculatedProfit >= 0 ? 'Net Profit' : 'Loss on Deal',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _calculatedProfit >= 0 ? Colors.green.shade900 : Colors.red.shade900,
                                  ),
                                ),
                                Text(
                                  '₹${_calculatedProfit.abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _calculatedProfit >= 0 ? AppColors.accent : AppColors.error,
                                  ),
                                ),
                                if (_gstEnabled && _currentGstResult.taxAmount > 0)
                                  Text(
                                    _gstMode == GstMode.inclusive
                                        ? 'Excl. ₹${_currentGstResult.taxAmount.toStringAsFixed(0)} GST paid to govt'
                                        : 'Base ₹${_netSellingRevenue.toStringAsFixed(0)} - Cost ₹${_totalCost.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            'ROI: ${_calculatedRoi >= 0 ? "+" : ""}${_calculatedRoi.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _calculatedProfit >= 0 ? AppColors.accent : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Testing Warranty Options
                const Text(
                  'Testing Warranty Guarantee',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._warrantyOptions.map((days) {
                      final isSelected = !_isCustomWarranty && _warrantyDays == days;
                      return ChoiceChip(
                        label: Text(days == 0 ? 'No Warranty' : '$days Days'),
                        selected: isSelected,
                        onSelected: (sel) {
                          if (sel) {
                            setState(() {
                              _warrantyDays = days;
                              _isCustomWarranty = false;
                            });
                          }
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      );
                    }),
                    ChoiceChip(
                      label: const Text('Custom'),
                      selected: _isCustomWarranty,
                      onSelected: (sel) {
                        setState(() => _isCustomWarranty = sel);
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _isCustomWarranty ? Colors.white : AppColors.textPrimary,
                        fontWeight: _isCustomWarranty ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                if (_isCustomWarranty) ...[
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _customWarrantyController,
                    label: 'Warranty in Days',
                    hint: 'e.g. 45 or 90',
                    prefixIcon: Icons.verified_user_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ],

                const SizedBox(height: 16),

                // Payment Mode & Date
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildSelectField(
                        label: 'Payment Mode',
                        value: _paymentMode,
                        hint: 'Select mode',
                        prefixIcon: Icons.payment_rounded,
                        onTap: _selectPaymentMode,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sale Date',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _saleDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (picked != null) setState(() => _saleDate = picked);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkBackground : AppColors.inputFill,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      DateHelper.formatDate(_saleDate.toIso8601String()),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textMuted, size: 22),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: _notesController,
                  label: 'Sale Notes / Remarks (Optional)',
                  hint: 'Any remarks or customer request',
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                // Submit Button
                CustomButton(
                  text: _isLoading
                      ? 'Recording Sale...'
                      : (_sellingPrice > 0
                          ? 'Confirm Sale & Bill (₹${_finalPayable.toStringAsFixed(0)})'
                          : 'Confirm Sale & Generate Bill'),
                  icon: Icons.check_circle_rounded,
                  isLoading: _isLoading,
                  backgroundColor: AppColors.accent,
                  onPressed: _isLoading ? null : _submitSale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectPaymentMode() async {
    final selected = await AppSearchableBottomSheet.show(
      context,
      title: 'Select Payment Mode',
      options: _paymentModes,
      selectedValues: [_paymentMode],
      searchHint: 'Search payment mode...',
    );
    if (selected != null && selected is String && selected.isNotEmpty) {
      setState(() => _paymentMode = selected);
    }
  }

  Widget _buildSelectField({
    required String label,
    required String value,
    required String hint,
    required IconData prefixIcon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final hasValue = value.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: labelColor,
            letterSpacing: 0.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.inputFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: Row(
              children: [
                Icon(prefixIcon, size: 18, color: hasValue ? AppColors.primary : AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasValue ? value : hint,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                      color: hasValue
                          ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                          : AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textMuted, size: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _costChip(String label, double amount, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isHighlight ? AppColors.primary : AppColors.textMuted,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isHighlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

