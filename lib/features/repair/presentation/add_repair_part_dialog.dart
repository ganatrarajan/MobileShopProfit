import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/repair_repository.dart';
import '../models/repair.dart';

class AddRepairPartDialog extends StatefulWidget {
  final Repair repair;
  const AddRepairPartDialog({super.key, required this.repair});

  static Future<dynamic> show(BuildContext context, {required Repair repair}) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: AddRepairPartDialog(repair: repair),
      ),
    );
  }

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
        if (res.success) {
          Navigator.pop(context, res.data ?? true);
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
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
              const Expanded(
                child: Text('Add Part Used', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Add Part to Repair', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
