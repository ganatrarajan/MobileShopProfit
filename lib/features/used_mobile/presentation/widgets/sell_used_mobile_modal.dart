import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/date_helper.dart';
import '../../../../core/widgets/app_searchable_bottom_sheet.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
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
  final _notesController = TextEditingController();

  final UsedMobileRepository _repo = UsedMobileRepository();

  DateTime _saleDate = DateTime.now();
  String _paymentMode = 'Cash';
  int _warrantyDays = 15;
  bool _isCustomWarranty = false;
  bool _isLoading = false;

  final List<String> _paymentModes = ['Cash', 'UPI / GPay / PhonePe', 'Debit/Credit Card', 'Bank Transfer'];
  final List<int> _warrantyOptions = [0, 7, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    // If selling price was already estimated or mobile is sold
    if (widget.mobile.sellingPrice != null && widget.mobile.sellingPrice! > 0) {
      _sellingPriceController.text = widget.mobile.sellingPrice!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _buyerAddressController.dispose();
    _sellingPriceController.dispose();
    _customWarrantyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _sellingPrice {
    final text = _sellingPriceController.text.trim();
    return double.tryParse(text) ?? 0.0;
  }

  double get _totalCost => widget.mobile.totalCost;
  double get _calculatedProfit => _sellingPrice - _totalCost;
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

    final int selectedWarranty = _isCustomWarranty
        ? (int.tryParse(_customWarrantyController.text.trim()) ?? 0)
        : _warrantyDays;

    setState(() => _isLoading = true);

    final payload = {
      'buyer_name': _buyerNameController.text.trim(),
      'buyer_phone': buyerPhone,
      if (_buyerAddressController.text.trim().isNotEmpty)
        'buyer_address': _buyerAddressController.text.trim(),
      'selling_price': sellingPrice,
      'sale_date': _saleDate.toIso8601String().split('T').first,
      'sale_payment_mode': _paymentMode,
      'warranty_days': selectedWarranty,
      'warranty_terms': selectedWarranty > 0
          ? '$selectedWarranty Days Testing Warranty on Motherboard & Display (Physical/liquid damage excluded)'
          : null,
      if (_notesController.text.trim().isNotEmpty)
        'sale_notes': _notesController.text.trim(),
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
                        'IMEI 1: ${widget.mobile.imei1}',
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

                // Selling Price & Real-Time Profit Card
                const Text(
                  'Sale Pricing & Real-Time Profit',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),

                CustomTextField(
                  controller: _sellingPriceController,
                  label: 'Selling Price (₹) *',
                  hint: 'Enter final price to buyer',
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

                // Live Profit Calculation Card
                if (_sellingPrice > 0)
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
                  text: _isLoading ? 'Recording Sale...' : 'Confirm Sale & Generate Bill',
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

