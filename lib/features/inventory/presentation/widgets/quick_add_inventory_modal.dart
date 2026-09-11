import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/inventory_repository.dart';
import '../../models/inventory_item.dart';

class QuickAddInventoryModal extends StatefulWidget {
  final String? defaultItemType; // e.g. 'spare_part', 'accessory', 'product'

  const QuickAddInventoryModal({
    super.key,
    this.defaultItemType,
  });

  static Future<InventoryItem?> show(BuildContext context, {String? defaultItemType}) async {
    return await showModalBottomSheet<InventoryItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => QuickAddInventoryModal(defaultItemType: defaultItemType),
    );
  }

  @override
  State<QuickAddInventoryModal> createState() => _QuickAddInventoryModalState();
}

class _QuickAddInventoryModalState extends State<QuickAddInventoryModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _openingStockController = TextEditingController(text: '1');
  final _inventoryRepository = InventoryRepository();

  String _itemType = 'spare_part';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.defaultItemType != null && widget.defaultItemType!.isNotEmpty) {
      _itemType = widget.defaultItemType!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
    _openingStockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final sellingPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    final purchasePrice = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final openingStock = int.tryParse(_openingStockController.text.trim()) ?? 1;

    setState(() => _isSaving = true);
    try {
      final response = await _inventoryRepository.createItem(
        name: _nameController.text.trim(),
        itemType: _itemType,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        openingStock: openingStock,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (response.success && response.data != null) {
          final createdItem = response.data!;
          AppFeedback.showSuccess(
            context,
            title: '✅ Item Added',
            message: '${createdItem.name} has been added to inventory.',
          );
          Navigator.pop(context, createdItem);
        } else {
          AppFeedback.showError(context, error: response.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppFeedback.showError(context, error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Add Inventory Item',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'Add a new part or product to inventory',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Item Type Chips
              const Text('Item Type *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Spare Part')),
                      selected: _itemType == 'spare_part',
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      onSelected: (sel) {
                        if (sel) setState(() => _itemType = 'spare_part');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Accessory')),
                      selected: _itemType == 'accessory',
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      onSelected: (sel) {
                        if (sel) setState(() => _itemType = 'accessory');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Product')),
                      selected: _itemType == 'product',
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      onSelected: (sel) {
                        if (sel) setState(() => _itemType = 'product');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Item / Part Name',
                hint: 'e.g. iPhone 11 Display Original',
                controller: _nameController,
                isRequired: true,
                prefixIcon: Icons.shopping_bag_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter item or part name.';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Selling Price (₹)',
                      hint: '0.00',
                      controller: _sellingPriceController,
                      isRequired: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.currency_rupee,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter price';
                        if (double.tryParse(v.trim()) == null) return 'Invalid price';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Purchase Cost (₹)',
                      hint: '0.00',
                      controller: _purchasePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.money_off_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Initial Stock Quantity',
                hint: '1',
                controller: _openingStockController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.numbers_outlined,
              ),
              const SizedBox(height: 20),

              CustomButton(
                text: _isSaving ? 'Adding Item...' : 'Save & Select Item',
                icon: Icons.check,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
