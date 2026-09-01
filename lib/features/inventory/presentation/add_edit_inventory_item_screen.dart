import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/inventory_repository.dart';
import '../models/inventory_item.dart';

import '../../subscription/utils/subscription_guard.dart';

class AddEditInventoryItemScreen extends StatefulWidget {
  final InventoryItem? item;
  const AddEditInventoryItemScreen({super.key, this.item});

  @override
  State<AddEditInventoryItemScreen> createState() => _AddEditInventoryItemScreenState();
}

class _AddEditInventoryItemScreenState extends State<AddEditInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryRepository = InventoryRepository();

  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _skuController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _openingStockController;
  late TextEditingController _minimumStockController;
  late TextEditingController _unitController;
  late TextEditingController _descriptionController;
  late TextEditingController _imei1Controller;
  late TextEditingController _imei2Controller;
  late TextEditingController _serialController;

  String _itemType = 'spare_part'; // mobile, spare_part, accessory, other
  bool _isSubmitting = false;
  String? _errorMessage;

  final Map<String, String> _typeOptions = {
    'spare_part': 'Spare Part',
    'mobile': 'Mobile Phone',
    'accessory': 'Accessory',
    'other': 'Other',
  };

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _categoryController = TextEditingController(text: item?.category ?? 'General');
    _brandController = TextEditingController(text: item?.brand ?? '');
    _modelController = TextEditingController(text: item?.model ?? '');
    _skuController = TextEditingController(text: item?.sku ?? '');
    _purchasePriceController = TextEditingController(text: item != null ? item.purchasePrice.toStringAsFixed(2) : '');
    _sellingPriceController = TextEditingController(text: item != null ? item.sellingPrice.toStringAsFixed(2) : '');
    _openingStockController = TextEditingController(text: item != null ? item.currentStock.toString() : '0');
    _minimumStockController = TextEditingController(text: item != null ? item.minimumStock.toString() : '2');
    _unitController = TextEditingController(text: item?.unit ?? 'pcs');
    _descriptionController = TextEditingController(text: item?.description ?? '');

    String? im1, im2, sn;
    if (item != null && item.serials.isNotEmpty) {
      im1 = item.serials.first.imei1;
      im2 = item.serials.first.imei2;
      sn = item.serials.first.serialNumber;
    }
    _imei1Controller = TextEditingController(text: im1 ?? '');
    _imei2Controller = TextEditingController(text: im2 ?? '');
    _serialController = TextEditingController(text: sn ?? '');

    if (item != null) {
      _itemType = item.itemType;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted && !_isEditing) {
        final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'create inventory items');
        if (!ok && mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _skuController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _openingStockController.dispose();
    _minimumStockController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    _imei1Controller.dispose();
    _imei2Controller.dispose();
    _serialController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final purchasePrice = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final sellingPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    final openingStock = int.tryParse(_openingStockController.text.trim()) ?? 0;
    final minimumStock = int.tryParse(_minimumStockController.text.trim()) ?? 2;

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Item name is required.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (_isEditing) {
        final res = await _inventoryRepository.updateItem(
          id: widget.item!.id,
          name: name,
          itemType: _itemType,
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          category: _categoryController.text.trim(),
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          sku: _skuController.text.trim(),
          minimumStock: minimumStock,
          unit: _unitController.text.trim(),
          description: _descriptionController.text.trim(),
        );

        if (mounted) {
          if (res.success && res.data != null) {
            Navigator.pop(context, true);
          } else {
            setState(() {
              _errorMessage = res.message;
              _isSubmitting = false;
            });
          }
        }
      } else {
        final res = await _inventoryRepository.createItem(
          name: name,
          itemType: _itemType,
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          category: _categoryController.text.trim(),
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          sku: _skuController.text.trim(),
          openingStock: openingStock,
          minimumStock: minimumStock,
          unit: _unitController.text.trim(),
          description: _descriptionController.text.trim(),
          imei1: _imei1Controller.text.trim(),
          imei2: _imei2Controller.text.trim(),
          serialNumber: _serialController.text.trim(),
        );

        if (mounted) {
          if (res.success && res.data != null) {
            Navigator.pop(context, true);
          } else {
            setState(() {
              _errorMessage = res.message;
              _isSubmitting = false;
            });
          }
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Inventory Item' : 'Add Inventory Item'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(8)),
                  child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Basic Specifications Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Item Type *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _typeOptions.entries.map((entry) {
                        final isSelected = _itemType == entry.key;
                        return ChoiceChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _itemType = entry.key);
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 12),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'Item Name *',
                      hint: 'e.g. Display Folder iPhone 13 or USB-C Cable',
                      controller: _nameController,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Item name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Category',
                            hint: 'e.g. Displays, Chargers, Batteries',
                            controller: _categoryController,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextField(
                            label: 'SKU / Barcode',
                            hint: 'e.g. DISP-IP13-01',
                            controller: _skuController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Brand',
                            hint: 'e.g. Apple, Samsung',
                            controller: _brandController,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextField(
                            label: 'Model Compatibility',
                            hint: 'e.g. iPhone 13 Pro',
                            controller: _modelController,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Pricing & Cost Valuation Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pricing & Valuation *', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Purchase Cost (₹) *',
                            hint: 'e.g. 4500.00',
                            controller: _purchasePriceController,
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Cost price required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextField(
                            label: 'Selling Price (₹) *',
                            hint: 'e.g. 7000.00',
                            controller: _sellingPriceController,
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Selling price required' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Stock Levels Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Stock Management *', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (!_isEditing) ...[
                          Expanded(
                            child: CustomTextField(
                              label: 'Opening Stock',
                              hint: 'Initial quantity',
                              controller: _openingStockController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: CustomTextField(
                            label: 'Minimum Stock Alert',
                            hint: 'Low stock threshold',
                            controller: _minimumStockController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextField(
                            label: 'Unit',
                            hint: 'pcs / box / set',
                            controller: _unitController,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Mobile IMEI Fields (if mobile type)
              if (_itemType == 'mobile') ...[
                CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mobile Device Identifiers', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'IMEI 1',
                        hint: 'Primary 15-digit IMEI',
                        controller: _imei1Controller,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'IMEI 2',
                        hint: 'Secondary IMEI (Optional)',
                        controller: _imei2Controller,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Serial Number',
                        hint: 'Manufacturer Serial #',
                        controller: _serialController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 5. Description Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: CustomTextField(
                  label: 'Description & Supplier Notes (Optional)',
                  hint: 'Detailed product specs or supplier reference',
                  controller: _descriptionController,
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: _isEditing ? 'Update Item' : 'Save Inventory Item',
                isLoading: _isSubmitting,
                onPressed: _submitForm,
                icon: Icons.save_rounded,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
