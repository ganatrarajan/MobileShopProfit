import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/barcode_scanner_screen.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/inventory_repository.dart';
import '../models/inventory_item.dart';

class AddStockDialog extends StatefulWidget {
  final InventoryItem item;
  const AddStockDialog({super.key, required this.item});

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
    final unitCost = double.tryParse(_unitCostController.text.trim());
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.add_shopping_cart_rounded, color: Colors.green.shade700, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Incoming Stock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(widget.item.name, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(6)),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
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
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Purchase Notes (Optional)',
              hint: 'e.g. Batch #45 from supplier',
              controller: _notesController,
              maxLines: 2,
            ),
            if (widget.item.itemType == 'mobile') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Device Identifiers ',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          TextSpan(
                            text: '(Required) *',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700),
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, size: 12, color: Color(0xFF10B981)),
                          SizedBox(width: 3),
                          Text(
                            '⚡ Scan Box',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              CustomTextField(
                label: 'IMEI 1 * (Required)',
                hint: '15-digit primary IMEI (Required)',
                controller: _imei1Controller,
                isRequired: true,
                keyboardType: TextInputType.number,
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
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                  tooltip: 'Scan Box with camera',
                  onPressed: () => _scanBoxTogether(isSecondary: true),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submitAddStock,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Add Stock', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
