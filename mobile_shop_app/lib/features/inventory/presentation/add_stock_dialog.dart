import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
  String? _errorMessage;

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

    final unitCost = double.tryParse(_unitCostController.text.trim());

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

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
                    label: 'Quantity *',
                    hint: 'e.g. 5',
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
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
              const Text('Device Identifiers (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 6),
              CustomTextField(
                label: 'IMEI 1',
                hint: '15-digit IMEI',
                controller: _imei1Controller,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                label: 'IMEI 2',
                hint: '15-digit IMEI',
                controller: _imei2Controller,
                keyboardType: TextInputType.number,
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
