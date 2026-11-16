import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/barcode_scanner_screen.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/inventory_repository.dart';
import '../models/inventory_item.dart';
import '../../../core/utils/gst_calculator.dart';
import '../../../core/widgets/gst_input_card.dart';

class AddStockDialog extends StatefulWidget {
  final InventoryItem item;
  const AddStockDialog({super.key, required this.item});

  /// Opens Add Incoming Stock as a proper bottom sheet
  static Future<InventoryItem?> show(
    BuildContext context, {
    required InventoryItem item,
  }) {
    return showModalBottomSheet<InventoryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddStockDialog(item: item),
    );
  }

  @override
  State<AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<AddStockDialog> {
  final _inventoryRepository = InventoryRepository();
  final _quantityController = TextEditingController(text: '1');
  late TextEditingController _unitCostController;
  final _notesController = TextEditingController();
  final _imei1Controller = TextEditingController();
  final _imei2Controller = TextEditingController();
  final _serialController = TextEditingController();

  // GST State
  bool _gstEnabled = false;
  GstMode _gstMode = GstMode.exclusive;
  double _gstRate = 18.0;
  bool _isInterState = false;
  GstCalculationResult? _gstResult;

  bool _isSubmitting = false;
  bool _isScanning = false;
  String? _errorMessage;

  Future<void> _scanBoxTogether({bool isSecondary = false}) async {
    if (_isScanning) return;
    _isScanning = true;
    try {
      final result = await BarcodeScannerScreen.scanBox(
        context,
        title: 'Auto-Scan Phone Box',
        instruction: 'Point at box sticker to capture both IMEIs',
      );
      if (result != null && mounted) {
        setState(() {
          if (result.hasBothImeis) {
            _imei1Controller.text = result.imei1!;
            _imei2Controller.text = result.imei2!;
          } else if (result.imei1 != null && result.imei1!.isNotEmpty) {
            if (isSecondary && _imei1Controller.text.isNotEmpty) {
              _imei2Controller.text = result.imei1!;
            } else if (_imei1Controller.text.isEmpty) {
              _imei1Controller.text = result.imei1!;
            } else {
              _imei2Controller.text = result.imei1!;
            }
          } else if (result.imei2 != null && result.imei2!.isNotEmpty) {
            _imei2Controller.text = result.imei2!;
          }
        });
      }
    } finally {
      _isScanning = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _unitCostController = TextEditingController(text: widget.item.purchasePrice.toStringAsFixed(2));
    _gstRate = widget.item.taxRate > 0 ? widget.item.taxRate : 18.0;
    _gstMode = widget.item.taxType == 'inclusive' ? GstMode.inclusive : GstMode.exclusive;
    _gstEnabled = widget.item.taxRate > 0;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitCostController.dispose();
    _notesController.dispose();
    _imei1Controller.dispose();
    _imei2Controller.dispose();
    _serialController.dispose();
    super.dispose();
  }

  Future<void> _submitAddStock() async {
    final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
    if (qty <= 0) {
      setState(() => _errorMessage = 'Please enter a valid quantity greater than 0.');
      return;
    }

    final isMobile = widget.item.itemType == 'mobile';
    double? unitCost = double.tryParse(_unitCostController.text.trim());
    if (_gstEnabled && _gstResult != null && unitCost != null) {
      if (_gstMode == GstMode.exclusive) {
        unitCost = _gstResult!.totalPayable;
      }
    }
    final imei1 = _imei1Controller.text.trim();
    final imei2 = _imei2Controller.text.trim();
    final serial = _serialController.text.trim();

    if (isMobile) {
      if (imei1.isEmpty) {
        setState(() => _errorMessage = 'Primary IMEI 1 is required for mobile phones. Stock cannot be added without IMEI.');
        return;
      }
      if (imei1.length < 8) {
        setState(() => _errorMessage = 'Please enter a valid IMEI number (typically 15 digits).');
        return;
      }
      if (qty > 1) {
        setState(() => _errorMessage = 'For mobile phones, please add stock 1 unit at a time with its unique IMEI.');
        return;
      }
    }

    if (imei1.isNotEmpty && imei2.isNotEmpty && imei1 == imei2) {
      setState(() => _errorMessage = 'Primary IMEI 1 and Secondary IMEI 2 cannot be identical.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    // Proactively verify if any entered IMEI/Serial is already active in stock for this shop
    for (final val in [imei1, imei2, serial]) {
      if (val.isNotEmpty) {
        try {
          final check = await _inventoryRepository.checkImeiAvailability(val);
          if (check.success && check.data != null && check.data!['in_stock'] == true) {
            final itemName = check.data!['item']?['name'];
            final suffix = itemName != null ? ' ($itemName)' : '';
            if (mounted) {
              setState(() {
                _isSubmitting = false;
                _errorMessage = check.message.isNotEmpty
                    ? check.message
                    : "IMEI/Serial '$val' is already in stock for this shop$suffix. Cannot add duplicate until the current unit is sold.";
              });
            }
            return;
          }
        } catch (_) {}
      }
    }

    try {
      final res = await _inventoryRepository.addStock(
        id: widget.item.id,
        quantity: qty,
        unitCost: unitCost,
        notes: _notesController.text.trim(),
        imei1: _imei1Controller.text.trim(),
        imei2: _imei2Controller.text.trim(),
        serialNumber: _serialController.text.trim(),
      );

      if (mounted) {
        if (res.success && res.data != null) {
          Navigator.pop(context, res.data);
        } else {
          setState(() {
            _errorMessage = res.message;
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.90;
    final enteredCost = double.tryParse(_unitCostController.text.trim()) ?? 0.0;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Drag Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.add_shopping_cart_rounded, color: Colors.green.shade700, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Incoming Stock',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.item.name,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 22),
                  color: Colors.grey.shade600,
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const Divider(height: 16),

          // 3. Scrollable Form Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.error, fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: widget.item.itemType == 'mobile' ? 'Quantity (1 unit) *' : 'Quantity *',
                          hint: widget.item.itemType == 'mobile' ? '1' : 'e.g. 5',
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          readOnly: widget.item.itemType == 'mobile',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          label: 'Unit Cost (₹) *',
                          hint: 'e.g. 4500',
                          controller: _unitCostController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GstInputCard(
                    amount: enteredCost,
                    initialEnabled: _gstEnabled,
                    initialMode: _gstMode,
                    initialRate: _gstRate,
                    initialInterState: _isInterState,
                    title: 'Apply GST / Tax',
                    onChanged: (res) {
                      setState(() {
                        _gstEnabled = res.isEnabled;
                        _gstMode = res.mode;
                        _gstRate = res.rate;
                        _isInterState = res.isInterState;
                        _gstResult = res;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Purchase Notes (Optional)',
                    hint: 'e.g. Batch #45 from supplier',
                    controller: _notesController,
                    maxLines: 2,
                  ),
                  if (widget.item.itemType == 'mobile') ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Device Identifiers ',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                TextSpan(
                                  text: '(Required) *',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: _scanBoxTogether,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF10B981)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.qr_code_scanner_rounded, size: 13, color: Color(0xFF10B981)),
                                SizedBox(width: 4),
                                Text(
                                  '⚡ Auto-Scan Box',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: 'IMEI 1 * (Required)',
                      hint: '15-digit primary IMEI (Required)',
                      controller: _imei1Controller,
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.qr_code_2_rounded,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                        tooltip: 'Scan Box with camera',
                        onPressed: () => _scanBoxTogether(isSecondary: false),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: 'IMEI 2 (Optional)',
                      hint: '15-digit secondary IMEI',
                      controller: _imei2Controller,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.qr_code_2_rounded,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                        tooltip: 'Scan Box with camera',
                        onPressed: () => _scanBoxTogether(isSecondary: true),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    CustomTextField(
                      label: 'Serial Number (Optional)',
                      hint: 'e.g. SN12345678',
                      controller: _serialController,
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // 4. Fixed Bottom Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitAddStock,
                    icon: _isSubmitting
                        ? const SizedBox.shrink()
                        : const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Add Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}