import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/inventory_repository.dart';
import '../models/inventory_item.dart';

class AdjustStockDialog extends StatefulWidget {
  final InventoryItem item;
  const AdjustStockDialog({super.key, required this.item});

  @override
  State<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<AdjustStockDialog> {
  final _inventoryRepository = InventoryRepository();
  String _selectedAdjustmentType = 'damaged'; // damaged, return, correction, lost
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  final Map<String, String> _adjustmentLabels = {
    'damaged': 'Damaged (-)',
    'lost': 'Lost / Stolen (-)',
    'return': 'Customer Return (+)',
    'correction': 'Stock Correction (+/-)',
  };

  final Map<String, Color> _adjustmentColors = {
    'damaged': Colors.red.shade700,
    'lost': Colors.orange.shade800,
    'return': Colors.green.shade700,
    'correction': Colors.blue.shade700,
  };

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitAdjustment() async {
    final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
    if (qty == 0) {
      setState(() => _errorMessage = 'Please enter a non-zero quantity.');
      return;
    }

    final reason = _notesController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorMessage = 'A mandatory reason is required for stock adjustments.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final res = await _inventoryRepository.adjustStock(
        id: widget.item.id,
        adjustmentType: _selectedAdjustmentType,
        quantity: qty,
        notes: reason,
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
    final adjColor = _adjustmentColors[_selectedAdjustmentType] ?? AppColors.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: adjColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.published_with_changes_rounded, color: adjColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Stock Adjustment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            const Text('Adjustment Type *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _adjustmentLabels.entries.map((entry) {
                final isSelected = _selectedAdjustmentType == entry.key;
                final color = _adjustmentColors[entry.key] ?? AppColors.primary;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedAdjustmentType = entry.key);
                  },
                  selectedColor: color,
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Quantity *',
              hint: 'e.g. 1',
              controller: _quantityController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Reason for Adjustment (Mandatory) *',
              hint: 'e.g. Broken display during technician assembly',
              controller: _notesController,
              maxLines: 2,
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
          onPressed: _isSubmitting ? null : _submitAdjustment,
          style: ElevatedButton.styleFrom(
            backgroundColor: adjColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save Adjustment', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
