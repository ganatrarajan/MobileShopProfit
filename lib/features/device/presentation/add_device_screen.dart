import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../customer/models/customer.dart';
import '../data/device_repository.dart';

class AddDeviceScreen extends StatefulWidget {
  final Customer customer;
  const AddDeviceScreen({super.key, required this.customer});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _variantController = TextEditingController();
  final _colorController = TextEditingController();
  final _imei1Controller = TextEditingController();
  final _imei2Controller = TextEditingController();
  final _serialController = TextEditingController();
  final _notesController = TextEditingController();

  final DeviceRepository _repository = DeviceRepository();
  String _selectedDeviceType = 'Mobile';
  DateTime? _selectedPurchaseDate;
  bool _isLoading = false;
  String? _errorMessage;

  // Device Catalog state
  bool _isManualEntry = false;
  bool _isLoadingBrands = false;
  bool _isLoadingModels = false;
  List<String> _brands = [];
  List<String> _models = [];
  String? _selectedBrand;
  String? _selectedModel;

  final List<String> _deviceTypes = ['Mobile', 'Tablet', 'Laptop', 'Other'];

  @override
  void initState() {
    super.initState();
    _fetchBrands();
  }

  Future<void> _fetchBrands() async {
    setState(() => _isLoadingBrands = true);
    final response = await _repository.getDeviceBrands();
    if (mounted) {
      setState(() {
        _isLoadingBrands = false;
        if (response.success && response.data != null && response.data!.isNotEmpty) {
          _brands = response.data!;
        } else {
          // Fallback to manual entry if catalog unreachable
          _isManualEntry = true;
        }
      });
    }
  }

  Future<void> _fetchModels(String brand) async {
    setState(() {
      _isLoadingModels = true;
      _models = [];
      _selectedModel = null;
      _modelController.clear();
    });
    final response = await _repository.getDeviceModels(brand);
    if (mounted) {
      setState(() {
        _isLoadingModels = false;
        if (response.success && response.data != null) {
          _models = response.data!;
        }
      });
    }
  }

  void _showBrandSearchBottomSheet() {
    String filterQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredBrands = _brands.where((b) {
              return b.toLowerCase().contains(filterQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Mobile Brand',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  TextField(
                    onChanged: (val) {
                      setModalState(() => filterQuery = val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search brand name...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isLoadingBrands
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : filteredBrands.isEmpty
                            ? const Center(child: Text('No brands found', style: TextStyle(color: AppColors.textSecondary)))
                            : ListView.separated(
                                itemCount: filteredBrands.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final brandName = filteredBrands[idx];
                                  final isSelected = _selectedBrand == brandName;
                                  return ListTile(
                                    title: Text(
                                      brandName,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedBrand = brandName;
                                        _brandController.text = brandName;
                                      });
                                      _fetchModels(brandName);
                                      Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showModelSearchBottomSheet() {
    if (_selectedBrand == null) return;
    String filterQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredModels = _models.where((m) {
              return m.toLowerCase().contains(filterQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select $_selectedBrand Model',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  TextField(
                    onChanged: (val) {
                      setModalState(() => filterQuery = val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search model name...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isLoadingModels
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : filteredModels.isEmpty
                            ? const Center(child: Text('No models found', style: TextStyle(color: AppColors.textSecondary)))
                            : ListView.separated(
                                itemCount: filteredModels.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final modelName = filteredModels[idx];
                                  final isSelected = _selectedModel == modelName;
                                  return ListTile(
                                    title: Text(
                                      modelName,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedModel = modelName;
                                        _modelController.text = modelName;
                                      });
                                      Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedPurchaseDate = picked;
      });
    }
  }

  Future<void> _handleSaveDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? formattedDate;
    if (_selectedPurchaseDate != null) {
      formattedDate = "${_selectedPurchaseDate!.year}-${_selectedPurchaseDate!.month.toString().padLeft(2, '0')}-${_selectedPurchaseDate!.day.toString().padLeft(2, '0')}";
    }

    try {
      final response = await _repository.createDevice(
        customerId: widget.customer.id,
        deviceType: _selectedDeviceType,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        variant: _variantController.text.trim().isNotEmpty ? _variantController.text.trim() : null,
        color: _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : null,
        imei1: _imei1Controller.text.trim().isNotEmpty ? _imei1Controller.text.trim() : null,
        imei2: _imei2Controller.text.trim().isNotEmpty ? _imei2Controller.text.trim() : null,
        serialNumber: _serialController.text.trim().isNotEmpty ? _serialController.text.trim() : null,
        purchaseDate: formattedDate,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Device added successfully')),
          );
          Navigator.pop(context, true);
        } else {
          setState(() {
            _errorMessage = response.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        if (e is ApiException) {
          setState(() {
            _errorMessage = e.message;
          });
        } else {
          setState(() {
            _errorMessage = e.toString();
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildDeviceTypeChip(String type) {
    final isSelected = _selectedDeviceType == type;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedDeviceType = type;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              type,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _variantController.dispose();
    _colorController.dispose();
    _imei1Controller.dispose();
    _imei2Controller.dispose();
    _serialController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Customer Device'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Read-only Customer Header Banner
                CustomCard(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.accent,
                        child: Icon(Icons.person_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.customer.name,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '📱 ${widget.customer.mobile}',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                  ),
                  const SizedBox(height: 16),
                ],

                // Device Specifications Card
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Device Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Row(
                        children: _deviceTypes.map((type) => _buildDeviceTypeChip(type)).toList(),
                      ),
                      const SizedBox(height: 16),

                      // CATALOG vs MANUAL ENTRY TOGGLE HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _isManualEntry ? 'Manual Specifications' : 'Catalog Specifications',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isManualEntry = !_isManualEntry;
                                if (_isManualEntry) {
                                  _selectedBrand = null;
                                  _selectedModel = null;
                                } else {
                                  _brandController.clear();
                                  _modelController.clear();
                                  if (_brands.isEmpty) _fetchBrands();
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isManualEntry ? Icons.collections_bookmark_rounded : Icons.edit_note_rounded,
                                    size: 15,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isManualEntry ? 'Use Catalog' : 'Enter Manually',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (!_isManualEntry) ...[
                        // CATALOG SELECTION MODE
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: _showBrandSearchBottomSheet,
                              borderRadius: BorderRadius.circular(10),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Mobile Brand *',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
                                  suffixIcon: const Icon(Icons.search_rounded, size: 22, color: AppColors.primary),
                                ),
                                child: Text(
                                  _selectedBrand ?? (_isLoadingBrands ? 'Loading brands...' : 'Tap to search & select brand (${_brands.length} available)'),
                                  style: TextStyle(
                                    color: _selectedBrand == null ? AppColors.textMuted : AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: _selectedBrand != null ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            if (_selectedBrand == null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Please select a Mobile Brand above to load available models.',
                                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (_isLoadingModels) ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Row(
                                  children: [
                                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                                    SizedBox(width: 12),
                                    Text('Loading models catalog...', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                                  ],
                                ),
                              ),
                            ] else ...[
                              InkWell(
                                onTap: _showModelSearchBottomSheet,
                                borderRadius: BorderRadius.circular(10),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Mobile Model *',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    prefixIcon: const Icon(Icons.devices_rounded, color: AppColors.primary),
                                    suffixIcon: const Icon(Icons.arrow_drop_down_rounded, size: 28, color: AppColors.textSecondary),
                                  ),
                                  child: Text(
                                    _selectedModel ?? 'Tap to select model (${_models.length} available)',
                                    style: TextStyle(
                                      color: _selectedModel == null ? AppColors.textMuted : AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: _selectedModel != null ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ] else ...[
                        // MANUAL ENTRY MODE
                        CustomTextField(
                          label: 'Brand *',
                          hint: 'e.g. Apple, Samsung, Xiaomi',
                          controller: _brandController,
                          prefixIcon: Icons.phone_iphone_rounded,
                          validator: (val) => (val == null || val.isEmpty) ? 'Enter device brand' : null,
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'Model Name *',
                          hint: 'e.g. iPhone 13, Galaxy S24, Redmi Note 13',
                          controller: _modelController,
                          prefixIcon: Icons.devices_rounded,
                          validator: (val) => (val == null || val.isEmpty) ? 'Enter device model' : null,
                        ),
                      ],

                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Variant / RAM / Storage',
                              hint: 'e.g. 8GB / 128GB',
                              controller: _variantController,
                              prefixIcon: Icons.memory_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              label: 'Color',
                              hint: 'e.g. Black, Blue',
                              controller: _colorController,
                              prefixIcon: Icons.color_lens_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Identifiers Card (IMEI / Serial)
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Identifiers & Serial (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'IMEI 1 (15 Digits)',
                        hint: 'e.g. 864201041234567',
                        controller: _imei1Controller,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.qr_code_2_rounded,
                        validator: (val) {
                          if (val != null && val.isNotEmpty) {
                            final regExp = RegExp(r'^\d{15}$');
                            if (!regExp.hasMatch(val)) return 'IMEI must be 15 numeric digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'IMEI 2 (Dual SIM - 15 Digits)',
                        hint: 'e.g. 864201041234568',
                        controller: _imei2Controller,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.qr_code_2_rounded,
                        validator: (val) {
                          if (val != null && val.isNotEmpty) {
                            final regExp = RegExp(r'^\d{15}$');
                            if (!regExp.hasMatch(val)) return 'IMEI 2 must be 15 numeric digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Serial Number (Laptop/Tablet)',
                        hint: 'e.g. SN1234567890',
                        controller: _serialController,
                        prefixIcon: Icons.tag_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Purchase & Notes Card
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Purchase & Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _pickPurchaseDate,
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Purchase Date (Optional)',
                            prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                          ),
                          child: Text(
                            _selectedPurchaseDate == null
                                ? 'Tap to select date'
                                : "${_selectedPurchaseDate!.day}/${_selectedPurchaseDate!.month}/${_selectedPurchaseDate!.year}",
                            style: TextStyle(
                              color: _selectedPurchaseDate == null ? AppColors.textMuted : AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Device Condition / Notes',
                        hint: 'e.g. Scratches on back glass, original bill available',
                        controller: _notesController,
                        prefixIcon: Icons.note_alt_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: 'Save Device',
                  isLoading: _isLoading,
                  onPressed: _handleSaveDevice,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}