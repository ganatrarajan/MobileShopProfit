import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/repair_repository.dart';
import '../models/repair.dart';

class AddRepairPartDialog extends StatefulWidget {
  final Repair repair;
  const AddRepairPartDialog({super.key, required this.repair});

  @override
  State<AddRepairPartDialog> createState() => _AddRepairPartDialogState();
}

class _AddRepairPartDialogState extends State<AddRepairPartDialog> {
  final _repairRepository = RepairRepository();
  final _partNameController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _partNameController.dispose();
    _qtyController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitPart() async {
    final name = _partNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter part name.');
      return;
    }

    final qty = int.tryParse(_qtyController.text.trim()) ?? 1;
    final costPrice = double.tryParse(_costPriceController.text.trim());
    final sellingPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final res = await _repairRepository.addPart(
        repairId: widget.repair.id,
        partName: name,
        quantity: qty,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        notes: _notesController.text.trim(),
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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.build_circle_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('Add Part Used', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            CustomTextField(
              label: 'Part Name *',
              hint: 'e.g. Original Display / Battery / Charging Port',
              controller: _partNameController,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Qty *',
                    hint: '1',
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextField(
                    label: 'Charged Price (₹)',
                    hint: '0.00',
                    controller: _sellingPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Cost Price (₹, Optional)',
              hint: 'Cost to shop if known',
              controller: _costPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Notes (Optional)',
              hint: 'Supplier or part warranty note',
              controller: _notesController,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitPart,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Add Part', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
