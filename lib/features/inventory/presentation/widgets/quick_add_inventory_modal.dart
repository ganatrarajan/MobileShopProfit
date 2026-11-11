import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/app_searchable_bottom_sheet.dart';
import '../../../../core/widgets/barcode_scanner_screen.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../device/data/device_repository.dart';
import '../../data/inventory_repository.dart';
import '../../models/inventory_item.dart';

class QuickAddInventoryModal extends StatefulWidget {
  final String? defaultItemType;
  final bool isFromPurchase;

  const QuickAddInventoryModal({
    super.key,
    this.defaultItemType,
    this.isFromPurchase = false,
  });

  static Future<InventoryItem?> show(
    BuildContext context, {
    String? defaultItemType,
    bool isFromPurchase = false,
  }) {
    return showModalBottomSheet<InventoryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => QuickAddInventoryModal(
        defaultItemType: defaultItemType,
        isFromPurchase: isFromPurchase,
      ),
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

  // Mobile Phone Specifications Controllers
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _ramController = TextEditingController();
  final _storageController = TextEditingController();
  final _colorController = TextEditingController();
  final _skuController = TextEditingController();
  final _imei1Controller = TextEditingController();
  final _imei2Controller = TextEditingController();
  final _serialController = TextEditingController();

  String _itemType = 'mobile';
  bool _isSaving = false;
  bool _isScanning = false;
  bool _isManualBrandModel = false;
  bool _isLoadingBrands = false;
  bool _isLoadingModels = false;

  final InventoryRepository _inventoryRepository = InventoryRepository();
  final DeviceRepository _deviceRepo = DeviceRepository();

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

  @override
  void initState() {
    super.initState();
    if (widget.defaultItemType != null && widget.defaultItemType!.isNotEmpty) {
      _itemType = widget.defaultItemType!;
    }
    if (widget.isFromPurchase) {
      _openingStockController.text = '0';
    }
    _fetchBrandsCatalog();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
    _openingStockController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _ramController.dispose();
    _storageController.dispose();
    _colorController.dispose();
    _skuController.dispose();
    _imei1Controller.dispose();
    _imei2Controller.dispose();
    _serialController.dispose();
    super.dispose();
  }

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

  String? _buildDescription() {
    final parts = <String>[];
    if (_ramController.text.trim().isNotEmpty) parts.add('RAM: ${_ramController.text.trim()}');
    if (_storageController.text.trim().isNotEmpty) parts.add('Storage: ${_storageController.text.trim()}');
    if (_colorController.text.trim().isNotEmpty) parts.add('Color: ${_colorController.text.trim()}');
    return parts.isNotEmpty ? parts.join(' | ') : null;
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_itemType == 'mobile') {
      if (_brandController.text.trim().isEmpty) {
        AppFeedback.showError(context, error: 'Please select or enter the Mobile Brand.');
        return;
      }
      if (_modelController.text.trim().isEmpty) {
        AppFeedback.showError(context, error: 'Please select or enter the Mobile Model.');
        return;
      }
    }

    final sellingPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    final purchasePrice = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final openingStock = widget.isFromPurchase ? 0 : (int.tryParse(_openingStockController.text.trim()) ?? 0);

    setState(() => _isSaving = true);
    try {
      final response = await _inventoryRepository.createItem(
        name: _nameController.text.trim(),
        itemType: _itemType,
        category: _itemType == 'mobile' ? 'Mobile Phone' : null,
        brand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
        model: _modelController.text.trim().isNotEmpty ? _modelController.text.trim() : null,
        sku: _skuController.text.trim().isNotEmpty ? _skuController.text.trim() : null,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        openingStock: openingStock,
        imei1: _imei1Controller.text.trim().isNotEmpty ? _imei1Controller.text.trim() : null,
        imei2: _imei2Controller.text.trim().isNotEmpty ? _imei2Controller.text.trim() : null,
        serialNumber: _serialController.text.trim().isNotEmpty ? _serialController.text.trim() : null,
        description: _buildDescription(),
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (response.success && response.data != null) {
          final createdItem = response.data!;
          AppFeedback.showSuccess(
            context,
            title: 'Item Added',
            message: '${createdItem.name} created. Add quantity to Purchase Order.',
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
                    child: Icon(
                      _itemType == 'mobile' ? Icons.smartphone_rounded : Icons.inventory_2_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isFromPurchase ? 'Create Item for Purchase' : 'Quick Add Inventory Item',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.isFromPurchase
                              ? 'Master item will be created with 0 initial stock. Purchase Order quantity will add the stock.'
                              : 'Add new mobile phone, part or accessory to inventory',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.smartphone_rounded, size: 16),
                    label: const Text('Mobile Phone'),
                    selected: _itemType == 'mobile',
                    selectedColor: AppColors.primary.withOpacity(0.18),
                    onSelected: (sel) {
                      if (sel) {
                        setState(() {
                          _itemType = 'mobile';
                          _autoFormatName();
                        });
                      }
                    },
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.build_circle_outlined, size: 16),
                    label: const Text('Spare Part'),
                    selected: _itemType == 'spare_part',
                    selectedColor: AppColors.primary.withOpacity(0.18),
                    onSelected: (sel) {
                      if (sel) setState(() => _itemType = 'spare_part');
                    },
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.headphones_rounded, size: 16),
                    label: const Text('Accessory'),
                    selected: _itemType == 'accessory',
                    selectedColor: AppColors.primary.withOpacity(0.18),
                    onSelected: (sel) {
                      if (sel) setState(() => _itemType = 'accessory');
                    },
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.category_outlined, size: 16),
                    label: const Text('Other'),
                    selected: _itemType == 'other',
                    selectedColor: AppColors.primary.withOpacity(0.18),
                    onSelected: (sel) {
                      if (sel) setState(() => _itemType = 'other');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mobile Phone Specifications Section
              if (_itemType == 'mobile') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
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
                      const SizedBox(height: 12),

                      if (!_isManualBrandModel) ...[
                        _buildSelectField(
                          label: 'Mobile Brand',
                          value: _brandController.text,
                          hint: 'Tap to select Brand (Apple, Samsung, etc.)',
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
                              : 'Tap to select ${_brandController.text} model',
                          prefixIcon: Icons.devices_other_rounded,
                          isLoading: _isLoadingModels,
                          onTap: _selectModel,
                          isRequired: true,
                        ),
                      ] else ...[
                        CustomTextField(
                          controller: _brandController,
                          label: 'Mobile Brand *',
                          hint: 'e.g. Apple, Samsung, OnePlus',
                          prefixIcon: Icons.business_rounded,
                          isRequired: true,
                          onChanged: (_) => _autoFormatName(),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Brand required' : null,
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          controller: _modelController,
                          label: 'Mobile Model *',
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

                      // Color & SKU
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _colorController,
                              label: 'Color (Optional)',
                              hint: 'e.g. Black / Blue',
                              prefixIcon: Icons.palette_outlined,
                              onChanged: (_) => _autoFormatName(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomTextField(
                              controller: _skuController,
                              label: 'SKU / Barcode (Optional)',
                              hint: 'e.g. MOB-IP13-01',
                              prefixIcon: Icons.qr_code_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Auto-scan Box shortcut & IMEIs
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Device Identifiers (IMEI / Serial)',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                        label: 'Primary IMEI 1 (Optional)',
                        hint: 'Primary 15-digit IMEI',
                        controller: _imei1Controller,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.qr_code_2_rounded,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                          tooltip: 'Scan Box Sticker',
                          onPressed: _scanBoxTogether,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        label: 'Secondary IMEI 2 (Optional)',
                        hint: 'Secondary 15-digit IMEI',
                        controller: _imei2Controller,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.qr_code_rounded,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                          tooltip: 'Scan Box Sticker',
                          onPressed: _scanBoxTogether,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        label: 'Serial Number (Optional)',
                        hint: 'Manufacturer Serial #',
                        controller: _serialController,
                        prefixIcon: Icons.tag_rounded,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                          tooltip: 'Scan Serial #',
                          onPressed: _scanBoxTogether,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              CustomTextField(
                label: 'Item / Product Name *',
                hint: _itemType == 'mobile' ? 'e.g. Apple iPhone 13 (8 GB / 128 GB - Black)' : 'e.g. BoAt Airdopes 141 or Noise Smartwatch',
                controller: _nameController,
                isRequired: true,
                prefixIcon: Icons.shopping_bag_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter item or product name.';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              if (_itemType != 'mobile') ...[
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'SKU / Barcode (Optional)',
                        hint: 'Box Barcode',
                        controller: _skuController,
                        prefixIcon: Icons.qr_code_rounded,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                          tooltip: 'Scan Barcode',
                          onPressed: () => _scanToController(_skuController, 'Scan SKU / Barcode'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomTextField(
                        label: 'Serial Number (Optional)',
                        hint: 'S/N',
                        controller: _serialController,
                        prefixIcon: Icons.tag_rounded,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                          tooltip: 'Scan Serial #',
                          onPressed: () => _scanToController(_serialController, 'Scan Serial Number (S/N)'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Selling Price (₹) *',
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

              if (!widget.isFromPurchase)
                CustomTextField(
                  label: 'Initial Stock Quantity',
                  hint: '1',
                  controller: _openingStockController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.numbers_outlined,
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Stock quantity will be added when you save this Purchase Order.',
                          style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
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
