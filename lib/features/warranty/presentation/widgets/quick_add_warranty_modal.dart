import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_error_mapper.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../customer/models/customer.dart';
import '../../../device/models/device.dart';
import '../../../repair/models/repair.dart';
import '../../../sales/models/sale.dart';
import '../../data/warranty_repository.dart';
import '../../models/warranty.dart';
import '../warranty_details_screen.dart';

class QuickWarrantyModal extends StatefulWidget {
  final Sale? sale;
  final Repair? repair;
  final Customer? customer;
  final Device? device;

  const QuickWarrantyModal({
    super.key,
    this.sale,
    this.repair,
    this.customer,
    this.device,
  });

  static Future<Warranty?> show(
    BuildContext context, {
    Sale? sale,
    Repair? repair,
    Customer? customer,
    Device? device,
  }) async {
    return showModalBottomSheet<Warranty>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuickWarrantyModal(
        sale: sale,
        repair: repair,
        customer: customer,
        device: device,
      ),
    );
  }

  @override
  State<QuickWarrantyModal> createState() => _QuickWarrantyModalState();
}

class _QuickWarrantyModalState extends State<QuickWarrantyModal> {
  final WarrantyRepository _warrantyRepository = WarrantyRepository();
  final ScrollController _scrollController = ScrollController();

  bool _isCheckingExisting = true;
  Warranty? _existingWarranty;

  int _selectedDurationDays = 180; // Default 6 months
  bool _isCustomDuration = false;
  final TextEditingController _customDurationController = TextEditingController();

  DateTime _startDate = DateTime.now();
  final TextEditingController _termsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _presetDurations = [
    {'label': '7 Days', 'days': 7},
    {'label': '15 Days', 'days': 15},
    {'label': '1 Month', 'days': 30},
    {'label': '3 Months', 'days': 90},
    {'label': '6 Months', 'days': 180},
    {'label': '1 Year', 'days': 365},
  ];

  final List<String> _presetTerms = [
    'Full Device Warranty',
    'Display / Touch Combo Only',
    'Battery & Charging Port Only',
    'Motherboard Repair Warranty',
    'Part Replacement Warranty',
  ];

  @override
  void initState() {
    super.initState();
    _checkExistingWarranty();
  }

  Future<void> _checkExistingWarranty() async {
    // 1. Only consider an existing warranty if it is ACTIVE or EXPIRING_SOON
    if (widget.sale?.warranty != null) {
      final status = widget.sale!.warranty!.status;
      if (status == 'active' || status == 'expiring_soon') {
        setState(() {
          _existingWarranty = widget.sale!.warranty;
          _isCheckingExisting = false;
        });
        return;
      }
    }
    if (widget.repair?.warranty != null) {
      final status = widget.repair!.warranty!.status;
      if (status == 'active' || status == 'expiring_soon') {
        setState(() {
          _existingWarranty = widget.repair!.warranty;
          _isCheckingExisting = false;
        });
        return;
      }
    }

    // 2. Fetch from repository if saleId or repairId available
    final saleId = widget.sale?.id;
    final repairId = widget.repair?.id;

    if (saleId != null || repairId != null) {
      try {
        final res = await _warrantyRepository.getWarranties(
          saleId: saleId,
          repairId: repairId,
        );
        if (res.success && res.data != null && res.data!.isNotEmpty) {
          final activeWarranties = res.data!.where((w) {
            final matchesSale = saleId != null && w.saleId == saleId;
            final matchesRepair = repairId != null && w.repairId == repairId;
            final isActive = w.status == 'active' || w.status == 'expiring_soon';
            return (matchesSale || matchesRepair) && isActive;
          }).toList();

          if (activeWarranties.isNotEmpty && mounted) {
            setState(() {
              _existingWarranty = activeWarranties.first;
              _isCheckingExisting = false;
            });
            return;
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isCheckingExisting = false);
    }
  }

  int get _finalDurationDays {
    if (_isCustomDuration) {
      return int.tryParse(_customDurationController.text.trim()) ?? 30;
    }
    return _selectedDurationDays;
  }

  DateTime get _calculatedEndDate {
    return _startDate.add(Duration(days: _finalDurationDays));
  }

  int? get _resolvedCustomerId { if (widget.sale?.customerId != null && widget.sale!.customerId! > 0) return widget.sale!.customerId!; if (widget.repair?.customerId != null && widget.repair!.customerId > 0) return widget.repair!.customerId; if (widget.customer != null && widget.customer!.id > 0) return widget.customer!.id; return null; }

  int? get _resolvedDeviceId { if (widget.sale?.deviceId != null && widget.sale!.deviceId! > 0) return widget.sale!.deviceId!; if (widget.repair?.deviceId != null && widget.repair!.deviceId > 0) return widget.repair!.deviceId; if (widget.device != null && widget.device!.id > 0) return widget.device!.id; return null; }

  String get _customerDisplayName {
    if (widget.sale?.customerName != null && widget.sale!.customerName!.isNotEmpty) {
      return widget.sale!.customerName!;
    }
    if (widget.sale?.customer != null) return widget.sale!.customer!.name;
    if (widget.repair?.customer != null) return widget.repair!.customer!.name;
    if (widget.customer != null) return widget.customer!.name;
    return 'General Customer';
  }

  String get _deviceDisplayName {
    if (widget.sale?.device != null) {
      return '${widget.sale!.device!.brand} ${widget.sale!.device!.model}'.trim();
    }
    if (widget.repair?.device != null) {
      return '${widget.repair!.device!.brand} ${widget.repair!.device!.model}'.trim();
    }
    if (widget.device != null) {
      return '${widget.device!.brand} ${widget.device!.model}'.trim();
    }

    if (widget.sale?.items.isNotEmpty ?? false) {
      final item = widget.sale!.items.first;
      if (item.brand != null || item.model != null) {
        return '${item.brand ?? ''} ${item.model ?? ''}'.trim();
      }
      return item.productName;
    }
    return 'Customer Device';
  }

  String get _warrantyTypeLabel {
    if (widget.repair != null) return 'repair';
    return 'sale';
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

    Future<void> _submitWarranty() async {
    if (_isSubmitting) return;

    final customerId = _resolvedCustomerId;
    final deviceId = _resolvedDeviceId;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final startDateStr = _startDate.toIso8601String().split('T')[0];

      final res = await _warrantyRepository.createWarranty(
        customerId: customerId,
        deviceId: deviceId,
        warrantyType: _warrantyTypeLabel,
        durationDays: _finalDurationDays,
        saleId: widget.sale?.id,
        repairId: widget.repair?.id,
        warrantyStartDate: startDateStr,
        warrantyTerms: _termsController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isSubmitting = false);

      if (res.success && res.data != null) {
        final newWarranty = res.data!;
        AppFeedback.showSuccess(
          context,
          title: 'Warranty Added',
          message: 'Warranty #${newWarranty.warrantyNumber} created successfully!',
        );
        Navigator.pop(context, newWarranty);
      } else {
        _showFailureDialog(AppErrorMapper.mapMessage(res.message));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showFailureDialog(AppErrorMapper.mapMessage(e.toString()));
    }
  }

  void _showFailureDialog(String errorMsg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Warranty Could Not Be Added',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          errorMsg.isNotEmpty ? errorMsg : "We couldn't create the warranty. Please check the information and try again.",
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, null);
            },
            child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitWarranty();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Quick Add Warranty',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, null),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _isCheckingExisting
                ? const Center(child: CircularProgressIndicator())
                : _existingWarranty != null
                    ? _buildExistingWarrantyView()
                    : SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAutoPopulatedCard(),
                            const SizedBox(height: 16),

                            const Text(
                              'Warranty Period *',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ..._presetDurations.map((d) {
                                  final isSelected = !_isCustomDuration && _selectedDurationDays == d['days'];
                                  return ChoiceChip(
                                    label: Text(d['label']),
                                    selected: isSelected,
                                    selectedColor: AppColors.primary.withOpacity(0.15),
                                    labelStyle: TextStyle(
                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _isCustomDuration = false;
                                          _selectedDurationDays = d['days'];
                                        });
                                      }
                                    },
                                  );
                                }),
                                ChoiceChip(
                                  label: const Text('Custom'),
                                  selected: _isCustomDuration,
                                  selectedColor: AppColors.primary.withOpacity(0.15),
                                  labelStyle: TextStyle(
                                    color: _isCustomDuration ? AppColors.primary : AppColors.textPrimary,
                                    fontWeight: _isCustomDuration ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _isCustomDuration = true);
                                    }
                                  },
                                ),
                              ],
                            ),
                            if (_isCustomDuration) ...[
                              const SizedBox(height: 8),
                              CustomTextField(
                                label: 'Duration in Days',
                                hint: 'Enter number of days (e.g. 45)',
                                controller: _customDurationController,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                            const SizedBox(height: 16),

                            _buildDatePreviewCard(),
                            const SizedBox(height: 16),

                            const Text(
                              'Warranty Terms & Coverage (Optional)',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _presetTerms.map((term) {
                                return ActionChip(
                                  label: Text(term, style: const TextStyle(fontSize: 12)),
                                  backgroundColor: Colors.grey.shade100,
                                  onPressed: () {
                                    setState(() {
                                      if (_termsController.text.isEmpty) {
                                        _termsController.text = term;
                                      } else if (!_termsController.text.contains(term)) {
                                        _termsController.text += ', $term';
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                            CustomTextField(
                              label: 'Terms / Coverage',
                              hint: 'Describe warranty terms & covered components...',
                              controller: _termsController,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),

                            CustomTextField(
                              label: 'Internal Notes (Optional)',
                              hint: 'Additional notes for warranty record...',
                              controller: _notesController,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context, null),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: CustomButton(
                                    text: 'Save Warranty',
                                    isLoading: _isSubmitting,
                                    onPressed: _submitWarranty,
                                    icon: Icons.check_circle_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingWarrantyView() {
    final w = _existingWarranty!;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_rounded, color: Colors.blue, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Warranty Already Exists',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'An active warranty record is already associated with this item.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Warranty #', style: TextStyle(fontSize: 12, color: Colors.blue.shade800)),
                    Text(w.warrantyNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status', style: TextStyle(fontSize: 12, color: Colors.blue.shade800)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: w.status == 'active' ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        w.status.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Valid Until', style: TextStyle(fontSize: 12, color: Colors.blue.shade800)),
                    Text(w.warrantyEndDate, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, w),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, w);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WarrantyDetailsScreen(warranty: w)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.remove_red_eye_rounded, size: 18, color: Colors.white),
                  label: const Text('View Warranty', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoPopulatedCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                'Auto-linked Info (${_warrantyTypeLabel.toUpperCase()})',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const Divider(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _customerDisplayName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.smartphone_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _deviceDisplayName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (widget.sale != null || widget.repair != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  widget.sale != null ? 'Invoice #${widget.sale!.invoiceNumber}' : 'Job Card #${widget.repair!.jobNumber}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePreviewCard() {
    final endDateStr = "${_calculatedEndDate.day} ${_getMonthName(_calculatedEndDate.month)} ${_calculatedEndDate.year}";
    final startDateStr = "${_startDate.day} ${_getMonthName(_startDate.month)} ${_startDate.year}";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: _selectStartDate,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('Start: $startDateStr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
              ),
              Text(
                '$_finalDurationDays Days',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
              ),
            ],
          ),
          const Divider(height: 12),
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 16, color: Colors.green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Valid until $endDateStr',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1) % 12];
  }
}
