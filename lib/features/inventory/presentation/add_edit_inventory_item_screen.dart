import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/widgets/app_searchable_bottom_sheet.dart';
import '../../../core/widgets/barcode_scanner_screen.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../device/data/device_repository.dart';
import '../data/inventory_repository.dart';
import '../models/inventory_item.dart';

class AddEditInventoryItemScreen extends StatefulWidget {
  final InventoryItem? item;

  const AddEditInventoryItemScreen({super.key, this.item});

  @override
  State<AddEditInventoryItemScreen> createState() => _AddEditInventoryItemScreenState();
}

class _AddEditInventoryItemScreenState extends State<AddEditInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryRepository = InventoryRepository();
  final _deviceRepo = DeviceRepository();
  final ScrollController _scrollController = ScrollController();

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
  late TextEditingController _ramController;
  late TextEditingController _storageController;
  late TextEditingController _colorController;

  String _itemType = 'spare_part'; // mobile, spare_part, accessory, other
  bool _isSubmitting = false;
  bool _isScanning = false;
  bool _isManualBrandModel = false;
  bool _isLoadingBrands = false;
  bool _isLoadingModels = false;
  String? _errorMessage;

  List<String> _catalogBrands = [];
  List<String> _catalogModels = [];

  final List<String> _ramOptions = [
    '2 GB',
    '3 GB',
    '4 GB',
    '6 GB',
    '8 GB',
    '12 GB',
    '16 GB',
    '24 GB',
  ];

  final List<String> _storageOptions = [
    '32 GB',
    '64 GB',
    '128 GB',
    '256 GB',
    '512 GB',
    '1 TB',
  ];

  Future<void> _fetchBrandsCatalog() async {
    setState(() => _isLoadingBrands = true);
    final response = await _deviceRepo.getDeviceBrands();
    if (mounted) {
      setState(() {
        _isLoadingBrands = false;
        if (response.success && response.data != null && response.data!.isNotEmpty) {
          _catalogBrands = response.data!;
        } else {
          _catalogBrands = [
            'Apple',
            'Samsung',
            'OnePlus',
            'Vivo',
            'Oppo',
            'Realme',
            'Xiaomi',
            'Poco',
            'Motorola',
            'Google',
            'IQOO',
            'Nothing',
          ];
        }
      });
    }
  }

  Future<void> _fetchModelsCatalog(String brand) async {
    setState(() {
      _isLoadingModels = true;
      _catalogModels = [];
    });
    final response = await _deviceRepo.getDeviceModels(brand);
    if (mounted) {
      setState(() {
        _isLoadingModels = false;
        if (response.success && response.data != null) {
          _catalogModels = response.data!;
        }
      });
    }
  }

  Future<void> _scanBoxTogether() async {
    if (_isScanning) return;
    _isScanning = true;
    try {
      final result = await BarcodeScannerScreen.scanBox(
        context,
        title: 'Auto-Scan Phone Box',
        instruction: 'Point at box sticker to capture IMEIs and Serial',
      );
      if (result != null && mounted) {
        setState(() {
          if (result.imei1 != null && ScannedBoxResult.isValidImei(result.imei1)) {
            _imei1Controller.text = result.imei1!;
          }
          if (result.imei2 != null && ScannedBoxResult.isValidImei(result.imei2)) {
            _imei2Controller.text = result.imei2!;
          }
          if (result.serialNumber != null && result.serialNumber!.isNotEmpty) {
            _serialController.text = result.serialNumber!;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Both IMEIs and Serial Number populated from 1 scan!'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } finally {
      _isScanning = false;
    }
  }

  Future<void> _scanToController(TextEditingController controller, String title) async {
    final scanned = await BarcodeScannerScreen.scan(
      context,
      title: title,
    );
    if (scanned != null && scanned.trim().isNotEmpty && mounted) {
      final clean = scanned.replaceFirst(RegExp(r'^(s/n|sn|serial|imei1|imei2|imei|p/n|pn)[:\s-]+', caseSensitive: false), '').trim();
      setState(() {
        controller.text = clean.isNotEmpty ? clean : scanned.trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Scanned: ${controller.text}'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  final Map<String, String> _typeOptions = {
    'mobile': 'Mobile Phone',
    'spare_part': 'Spare Part',
    'accessory': 'Accessory',
    'other': 'Other',
  };

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _categoryController = TextEditingController(text: item?.category ?? (item?.itemType == 'mobile' ? 'Mobile Phone' : 'General'));
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

    // Parse specs if present in description e.g. "RAM: 8 GB | Storage: 128 GB | Color: Black"
    String initialRam = '';
    String initialStorage = '';
    String initialColor = '';
    if (item != null && item.description != null) {
      final desc = item.description!;
      final ramMatch = RegExp(r'RAM:\s*([0-9]+\s*GB)', caseSensitive: false).firstMatch(desc);
      if (ramMatch != null) initialRam = ramMatch.group(1) ?? '';

      final storageMatch = RegExp(r'Storage:\s*([0-9]+\s*(?:GB|TB))', caseSensitive: false).firstMatch(desc);
      if (storageMatch != null) initialStorage = storageMatch.group(1) ?? '';

      final colorMatch = RegExp(r'Color:\s*([^|]+)', caseSensitive: false).firstMatch(desc);
      if (colorMatch != null) initialColor = colorMatch.group(1)?.trim() ?? '';
    }

    _ramController = TextEditingController(text: initialRam);
    _storageController = TextEditingController(text: initialStorage);
    _colorController = TextEditingController(text: initialColor);

    if (item != null) {
      _itemType = item.itemType;
    }

    _fetchBrandsCatalog();
    if (_brandController.text.isNotEmpty) {
      _fetchModelsCatalog(_brandController.text);
    }
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
    _ramController.dispose();
    _storageController.dispose();
    _colorController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _autoFormatName() {
    if (_itemType != 'mobile') return;
    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();
    final ram = _ramController.text.trim();
    final storage = _storageController.text.trim();
    final color = _colorController.text.trim();

    if (brand.isEmpty && model.isEmpty) return;

    final parts = <String>[];
    if (brand.isNotEmpty) parts.add(brand);
    if (model.isNotEmpty) parts.add(model);

    final specs = <String>[];
    if (ram.isNotEmpty && storage.isNotEmpty) {
      specs.add('$ram / $storage');
    } else if (storage.isNotEmpty) {
      specs.add(storage);
    } else if (ram.isNotEmpty) {
      specs.add(ram);
    }

    if (color.isNotEmpty) {
      specs.add(color);
    }

    String fullName = parts.join(' ');
    if (specs.isNotEmpty) {
      fullName += ' (${specs.join(' - ')})';
    }

    _nameController.text = fullName;
  }

  Future<void> _selectBrand() async {
    final selected = await AppSearchableBottomSheet.show(
      context,
      title: 'Select Mobile Brand',
      options: _catalogBrands,
      selectedValues: _brandController.text.isNotEmpty ? [_brandController.text] : [],
      searchHint: 'Search mobile brand...',
      addCustomHint: '+ Add Custom Brand',
      onAddCustomOption: (custom) async {
        if (!_catalogBrands.contains(custom)) {
          setState(() => _catalogBrands.insert(0, custom));
        }
      },
    );
    if (selected != null && selected is String && selected.isNotEmpty) {
      setState(() {
        _brandController.text = selected;
        _modelController.clear();
      });
      _autoFormatName();
      _fetchModelsCatalog(selected);
    }
  }

  Future<void> _selectModel() async {
    if (_brandController.text.trim().isEmpty) {
      AppFeedback.showError(
        context,
        title: 'Brand Required',
        message: 'Please select Brand first to view its models.',
      );
      return;
    }

    final selected = await AppSearchableBottomSheet.show(
      context,
      title: 'Select ${_brandController.text.trim()} Model',
      options: _catalogModels.isNotEmpty ? _catalogModels : ['Standard Model'],
      selectedValues: _modelController.text.isNotEmpty ? [_modelController.text] : [],
      searchHint: 'Search model name...',
      addCustomHint: '+ Add Custom Model',
      onAddCustomOption: (custom) async {
        if (!_catalogModels.contains(custom)) {
          setState(() => _catalogModels.insert(0, custom));
        }
      },
    );
    if (selected != null && selected is String && selected.isNotEmpty) {
      setState(() => _modelController.text = selected);
      _autoFormatName();
    }
  }

  Future<void> _selectRam() async {
    final selected = await AppSearchableBottomSheet.show(
      context,
      title: 'Select RAM',
      options: _ramOptions,
      selectedValues: _ramController.text.isNotEmpty ? [_ramController.text] : [],
      searchHint: 'Search RAM...',
    );
    if (selected != null && selected is String && selected.isNotEmpty) {
      setState(() => _ramController.text = selected);
      _autoFormatName();
    }
  }

  Future<void> _selectStorage() async {
    final selected = await AppSearchableBottomSheet.show(
      context,
      title: 'Select Storage',
      options: _storageOptions,
      selectedValues: _storageController.text.isNotEmpty ? [_storageController.text] : [],
      searchHint: 'Search storage...',
    );
    if (selected != null && selected is String && selected.isNotEmpty) {
      setState(() => _storageController.text = selected);
      _autoFormatName();
    }
  }

  Widget _buildSelectField({
    required String label,
    required String value,
    required String hint,
    required IconData prefixIcon,
    required VoidCallback onTap,
    bool isLoading = false,
    bool isRequired = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: labelColor),
            ),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : Colors.white,
              border: Border.all(
                color: value.isNotEmpty
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : AppColors.border),
                width: value.isNotEmpty ? 1.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(prefixIcon, size: 18, color: value.isNotEmpty ? AppColors.primary : AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: isLoading
                      ? const Row(
                          children: [
                            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 8),
                            Text('Loading...', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        )
                      : Text(
                          value.isNotEmpty ? value : hint,
                          style: TextStyle(
                            fontSize: 13,
                            color: value.isNotEmpty
                                ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                                : AppColors.textMuted,
                            fontWeight: value.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                const Icon(Icons.arrow_drop_down, color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFormError(String errorMsg) {
    AppFeedback.showError(context, error: errorMsg);
    setState(() => _errorMessage = errorMsg);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_itemType == 'mobile') {
      if (_brandController.text.trim().isEmpty) {
        _showFormError('Mobile brand is required.');
        return;
      }
      if (_modelController.text.trim().isEmpty) {
        _showFormError('Mobile model is required.');
        return;
      }
    }

    final name = _nameController.text.trim();
    final purchasePrice = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final sellingPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    final openingStock = int.tryParse(_openingStockController.text.trim()) ?? 0;
    final minimumStock = int.tryParse(_minimumStockController.text.trim()) ?? 2;

    if (name.isEmpty) {
      _showFormError('Item name is required.');
      return;
    }

    // Auto-compose description if empty and mobile specs provided
    String description = _descriptionController.text.trim();
    if (_itemType == 'mobile') {
      final specParts = <String>[];
      if (_ramController.text.trim().isNotEmpty) specParts.add('RAM: ${_ramController.text.trim()}');
      if (_storageController.text.trim().isNotEmpty) specParts.add('Storage: ${_storageController.text.trim()}');
      if (_colorController.text.trim().isNotEmpty) specParts.add('Color: ${_colorController.text.trim()}');
      if (specParts.isNotEmpty) {
        final specsStr = specParts.join(' | ');
        if (description.isEmpty) {
          description = specsStr;
        } else if (!description.contains('RAM:') && !description.contains('Storage:')) {
          description = '$description\nSpecs: $specsStr';
        }
      }
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
          category: _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : (_itemType == 'mobile' ? 'Mobile Phone' : null),
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          sku: _skuController.text.trim(),
          minimumStock: minimumStock,
          unit: _unitController.text.trim(),
          description: description,
          imei1: _imei1Controller.text.trim(),
          imei2: _imei2Controller.text.trim(),
          serialNumber: _serialController.text.trim(),
        );

        if (mounted) {
          if (res.success && res.data != null) {
            AppFeedback.showSuccess(
              context,
              title: '✅ Item Updated',
              message: '$name has been updated successfully.',
            );
            Navigator.pop(context, true);
          } else {
            _showFormError(res.message);
            setState(() => _isSubmitting = false);
          }
        }
      } else {
        final res = await _inventoryRepository.createItem(
          name: name,
          itemType: _itemType,
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          category: _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : (_itemType == 'mobile' ? 'Mobile Phone' : null),
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          sku: _skuController.text.trim(),
          openingStock: openingStock,
          minimumStock: minimumStock,
          unit: _unitController.text.trim(),
          description: description,
          imei1: _imei1Controller.text.trim(),
          imei2: _imei2Controller.text.trim(),
          serialNumber: _serialController.text.trim(),
        );

        if (mounted) {
          if (res.success && res.data != null) {
            AppFeedback.showSuccess(
              context,
              title: '✅ Item Added',
              message: '$name has been added to inventory.',
            );
            Navigator.pop(context, true);
          } else {
            _showFormError(res.message);
            setState(() => _isSubmitting = false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showFormError(e.toString());
        setState(() => _isSubmitting = false);
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
        controller: _scrollController,
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
                            if (selected) {
                              setState(() {
                                _itemType = entry.key;
                                if (_itemType == 'mobile' && _categoryController.text == 'General') {
                                  _categoryController.text = 'Mobile Phone';
                                }
                              });
                            }
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 12),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Mobile Specific Specs or General Brand/Model
                    if (_itemType == 'mobile') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Row(
                                    children: [
                                      Icon(Icons.phone_android_rounded, size: 16, color: AppColors.primary),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Mobile Specifications',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    setState(() => _isManualBrandModel = !_isManualBrandModel);
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isManualBrandModel ? Icons.list_alt_rounded : Icons.edit_note_rounded,
                                        size: 15,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isManualBrandModel ? 'Select List' : 'Enter Manually',
                                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            if (!_isManualBrandModel) ...[
                              _buildSelectField(
                                label: 'Mobile Brand',
                                value: _brandController.text,
                                hint: 'Select Brand (Apple, Samsung, etc.)',
                                prefixIcon: Icons.business_rounded,
                                isLoading: _isLoadingBrands,
                                onTap: _selectBrand,
                                isRequired: true,
                              ),
                              const SizedBox(height: 10),
                              _buildSelectField(
                                label: 'Mobile Model',
                                value: _modelController.text,
                                hint: _brandController.text.isEmpty
                                    ? 'Select Brand first'
                                    : 'Select ${_brandController.text} model',
                                prefixIcon: Icons.devices_other_rounded,
                                isLoading: _isLoadingModels,
                                onTap: _selectModel,
                                isRequired: true,
                              ),
                            ] else ...[
                              CustomTextField(
                                controller: _brandController,
                                label: 'Brand Name *',
                                hint: 'e.g. Apple, Samsung, OnePlus',
                                prefixIcon: Icons.business_rounded,
                                isRequired: true,
                                onChanged: (_) => _autoFormatName(),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Brand required' : null,
                              ),
                              const SizedBox(height: 10),
                              CustomTextField(
                                controller: _modelController,
                                label: 'Model Name *',
                                hint: 'e.g. iPhone 13 / Galaxy S21',
                                prefixIcon: Icons.devices_other_rounded,
                                isRequired: true,
                                onChanged: (_) => _autoFormatName(),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Model required' : null,
                              ),
                            ],
                            const SizedBox(height: 10),

                            // RAM & Storage
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSelectField(
                                    label: 'RAM',
                                    value: _ramController.text,
                                    hint: 'Select RAM',
                                    prefixIcon: Icons.memory_rounded,
                                    onTap: _selectRam,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildSelectField(
                                    label: 'Storage',
                                    value: _storageController.text,
                                    hint: 'Select Storage',
                                    prefixIcon: Icons.sd_storage_rounded,
                                    onTap: _selectStorage,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            CustomTextField(
                              controller: _colorController,
                              label: 'Color (Optional)',
                              hint: 'e.g. Midnight Black / Alpine Green',
                              prefixIcon: Icons.palette_outlined,
                              onChanged: (_) => _autoFormatName(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    CustomTextField(
                      label: 'Item Name *',
                      hint: _itemType == 'mobile' ? 'e.g. Apple iPhone 13 (8 GB / 128 GB - Black)' : 'e.g. Display Folder iPhone 13 or USB-C Cable',
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
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                              tooltip: 'Scan Barcode',
                              onPressed: () => _scanToController(_skuController, 'Scan SKU / Barcode'),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_itemType != 'mobile') ...[
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
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Device Identifiers',
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                  Icon(Icons.qr_code_scanner_rounded, size: 14, color: Color(0xFF10B981)),
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
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'IMEI 1',
                        hint: 'Primary 15-digit IMEI',
                        controller: _imei1Controller,
                        keyboardType: TextInputType.number,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                          tooltip: 'Scan Box (All Identifiers)',
                          onPressed: _scanBoxTogether,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'IMEI 2',
                        hint: 'Secondary IMEI (Optional)',
                        controller: _imei2Controller,
                        keyboardType: TextInputType.number,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                          tooltip: 'Scan Box (All Identifiers)',
                          onPressed: _scanBoxTogether,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Serial Number',
                        hint: 'Manufacturer Serial #',
                        controller: _serialController,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                          tooltip: 'Scan Box (All Identifiers)',
                          onPressed: _scanBoxTogether,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                // 4b. Product Identifiers for non-mobile items (Earbuds, Smartwatches, Power Banks, Chargers, Accessories)
                CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.qr_code_scanner_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Product Identifiers (Optional)',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Earbuds, Watch, etc.',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Serial Number (S/N)',
                        hint: 'e.g. SN-883921 or scan box',
                        controller: _serialController,
                        prefixIcon: Icons.tag_rounded,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                          tooltip: 'Scan Serial Number',
                          onPressed: () => _scanToController(_serialController, 'Scan Serial Number (S/N)'),
                        ),
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
