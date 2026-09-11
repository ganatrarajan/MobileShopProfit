import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../customer/models/customer.dart';
import '../../../customer/presentation/widgets/quick_add_customer_modal.dart';
import '../../../customer/data/customer_repository.dart';
import '../../data/device_repository.dart';
import '../../models/device.dart';

class QuickAddDeviceModal extends StatefulWidget {
  final int? customerId;
  final String? customerName;

  const QuickAddDeviceModal({
    super.key,
    this.customerId,
    this.customerName,
  });

  static Future<Device?> show(
    BuildContext context, {
    int? customerId,
    String? customerName,
    Customer? customer,
    Customer? initialCustomer,
  }) async {
    final effectiveCustomerId = customerId ?? initialCustomer?.id ?? customer?.id;
    final effectiveCustomerName = customerName ?? initialCustomer?.name ?? customer?.name;

    return await showModalBottomSheet<Device>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => QuickAddDeviceModal(
        customerId: effectiveCustomerId,
        customerName: effectiveCustomerName,
      ),
    );
  }

  @override
  State<QuickAddDeviceModal> createState() => _QuickAddDeviceModalState();
}

class _QuickAddDeviceModalState extends State<QuickAddDeviceModal> {
  final _formKey = GlobalKey<FormState>();
  final _deviceRepository = DeviceRepository();
  final _customerRepository = CustomerRepository();

  int? _selectedCustomerId;
  String? _selectedCustomerName;
  List<Customer> _customerList = [];
  bool _isLoadingCustomers = false;

  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _imeiController = TextEditingController();
  final _colorController = TextEditingController();
  String _deviceType = 'Mobile';
  bool _isSaving = false;

  // Dual entry mode state (Catalog vs Manual)
  bool _isManualEntry = false;
  bool _isLoadingBrands = false;
  bool _isLoadingModels = false;
  List<String> _brands = [];
  List<String> _models = [];
  String? _selectedBrand;
  String? _selectedModel;

  final List<String> _deviceTypes = ['Mobile', 'Tablet', 'Laptop', 'Watch', 'Other'];

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.customerId;
    _selectedCustomerName = widget.customerName;
    if (_selectedCustomerId == null) {
      _loadCustomers();
    }
    _fetchBrands();
  }

  Future<void> _fetchBrands() async {
    setState(() => _isLoadingBrands = true);
    final response = await _deviceRepository.getDeviceBrands();
    if (mounted) {
      setState(() {
        _isLoadingBrands = false;
        if (response.success && response.data != null && response.data!.isNotEmpty) {
          _brands = response.data!;
        } else {
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
    final response = await _deviceRepository.getDeviceModels(brand);
    if (mounted) {
      setState(() {
        _isLoadingModels = false;
        if (response.success && response.data != null) {
          _models = response.data!;
        }
      });
    }
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoadingCustomers = true);
    try {
      final res = await _customerRepository.getCustomers();
      if (mounted && res.success && res.data != null) {
        setState(() {
          _customerList = res.data!;
          _isLoadingCustomers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCustomers = false);
    }
  }

  void _showCustomerSearchBottomSheet() {
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
            final filtered = _customerList.where((c) {
              final q = filterQuery.toLowerCase();
              return c.name.toLowerCase().contains(q) || c.mobile.contains(q);
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
                        'Select Customer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  TextField(
                    onChanged: (val) => setModalState(() => filterQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search customer name or mobile...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No customers found', style: TextStyle(color: AppColors.textSecondary)))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final customer = filtered[idx];
                              final isSelected = _selectedCustomerId == customer.id;
                              return ListTile(
                                title: Text(
                                  customer.name,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(customer.mobile, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                                onTap: () {
                                  setState(() {
                                    _selectedCustomerId = customer.id;
                                    _selectedCustomerName = customer.name;
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

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _imeiController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedCustomerId == null) {
      AppFeedback.showError(context, error: 'Please select or add a customer for this device.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final response = await _deviceRepository.createDevice(
        customerId: _selectedCustomerId!,
        deviceType: _deviceType,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        imei1: _imeiController.text.trim().isEmpty ? null : _imeiController.text.trim(),
        color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (response.success) {
          Device? createdDevice;
          if (response.data != null) {
            if (response.data is Map<String, dynamic>) {
              final map = response.data as Map<String, dynamic>;
              final devData = map.containsKey('device') ? map['device'] : map;
              createdDevice = Device.fromJson(Map<String, dynamic>.from(devData));
            } else if (response.data is Device) {
              createdDevice = response.data as Device;
            }
          }

          createdDevice ??= Device(
            id: DateTime.now().millisecondsSinceEpoch,
            shopId: 0,
            customerId: _selectedCustomerId!,
            deviceType: _deviceType,
            brand: _brandController.text.trim(),
            model: _modelController.text.trim(),
            imei1: _imeiController.text.trim(),
            color: _colorController.text.trim(),
          );

          AppFeedback.showSuccess(
            context,
            title: '✅ Device Added',
            message: '${createdDevice.brand} ${createdDevice.model} has been added successfully.',
          );
          Navigator.pop(context, createdDevice);
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
                    child: const Icon(Icons.phone_android, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Add Device',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _selectedCustomerName != null
                              ? 'For customer: $_selectedCustomerName'
                              : 'Select or add customer below',
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

              if (_selectedCustomerId == null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Select Customer *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final newCust = await QuickAddCustomerModal.show(context);
                        if (newCust != null && mounted) {
                          setState(() {
                            _customerList.insert(0, newCust);
                            _selectedCustomerId = newCust.id;
                            _selectedCustomerName = newCust.name;
                          });
                        }
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('+ Add Customer', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _isLoadingCustomers
                    ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                    : InkWell(
                        onTap: _showCustomerSearchBottomSheet,
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            hintText: 'Select Customer',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                            suffixIcon: const Icon(Icons.search_rounded, size: 22, color: AppColors.primary),
                          ),
                          child: Text(
                            _selectedCustomerId != null
                                ? '${_selectedCustomerName ?? 'Customer'} (${_customerList.firstWhere((c) => c.id == _selectedCustomerId, orElse: () => Customer(id: 0, shopId: 0, name: _selectedCustomerName ?? '', mobile: '')).mobile})'
                                : 'Tap to search & select customer (${_customerList.length} available)',
                            style: TextStyle(
                              color: _selectedCustomerId == null ? AppColors.textMuted : AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: _selectedCustomerId != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                const SizedBox(height: 14),
              ],

              // Device Type Selector
              const Text('Device Category *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _deviceTypes.map((type) {
                  final isSel = _deviceType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSel,
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: isSel ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (sel) {
                      if (sel) setState(() => _deviceType = type);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

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
                  hint: 'e.g. Samsung, Apple, Xiaomi',
                  controller: _brandController,
                  isRequired: true,
                  prefixIcon: Icons.smartphone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter device brand.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'Model Name / Number *',
                  hint: 'e.g. Galaxy S21 / iPhone 13 Pro',
                  controller: _modelController,
                  isRequired: true,
                  prefixIcon: Icons.devices,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter device model.';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 14),

              CustomTextField(
                label: 'IMEI / Serial Number (Optional)',
                hint: 'e.g. 864201948102931',
                controller: _imeiController,
                prefixIcon: Icons.qr_code,
              ),
              const SizedBox(height: 20),

              CustomButton(
                text: _isSaving ? 'Adding Device...' : 'Save & Select Device',
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
