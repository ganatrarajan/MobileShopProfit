import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../customer/data/customer_repository.dart';
import '../../customer/models/customer.dart';
import '../../device/data/device_repository.dart';
import '../../device/models/device.dart';
import '../../repair/data/repair_repository.dart';
import '../../repair/models/repair.dart';
import '../../sales/data/sale_repository.dart';
import '../../sales/models/sale.dart';
import '../data/warranty_repository.dart';

class CreateWarrantyScreen extends StatefulWidget {
  final Customer? preselectedCustomer;
  final Device? preselectedDevice;
  final Sale? preselectedSale;
  final Repair? preselectedRepair;

  const CreateWarrantyScreen({
    super.key,
    this.preselectedCustomer,
    this.preselectedDevice,
    this.preselectedSale,
    this.preselectedRepair,
  });

  @override
  State<CreateWarrantyScreen> createState() => _CreateWarrantyScreenState();
}

class _CreateWarrantyScreenState extends State<CreateWarrantyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _warrantyRepository = WarrantyRepository();
  final _customerRepository = CustomerRepository();
  final _deviceRepository = DeviceRepository();
  final _saleRepository = SaleRepository();
  final _repairRepository = RepairRepository();

  Customer? _selectedCustomer;
  Device? _selectedDevice;
  Sale? _selectedSale;
  Repair? _selectedRepair;

  List<Customer> _customerList = [];
  List<Device> _deviceList = [];
  List<Sale> _saleList = [];
  List<Repair> _repairList = [];

  bool _isLoadingCustomers = false;
  bool _isLoadingDevices = false;
  bool _isLoadingSalesOrRepairs = false;

  String _warrantyType = 'sale'; // 'sale', 'repair'
  int _selectedDurationDays = 30; // default 30 days
  bool _isCustomDuration = false;
  final _customDurationController = TextEditingController();

  DateTime _startDate = DateTime.now();
  final _coveredPartController = TextEditingController();
  final _termsController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  final List<int> _presetDurations = [7, 15, 30, 60, 90, 180, 365];
  final List<String> _presetCoveredParts = [
    'Display / Touch Combo',
    'Battery Replacement',
    'Charging Port / Subboard',
    'Motherboard Repair',
    'Camera Module',
    'Full Mobile Device',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preselectedCustomer;
    _selectedDevice = widget.preselectedDevice;
    _selectedSale = widget.preselectedSale;
    _selectedRepair = widget.preselectedRepair;

    if (_selectedRepair != null) {
      _warrantyType = 'repair';
    }

    _loadCustomers();
    if (_selectedCustomer != null) {
      _loadDevicesForCustomer(_selectedCustomer!.id);
      _loadSalesOrRepairs();
    }
  }

  @override
  void dispose() {
    _customDurationController.dispose();
    _termsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime get _endDate {
    final days = _isCustomDuration
        ? (int.tryParse(_customDurationController.text.trim()) ?? _selectedDurationDays)
        : _selectedDurationDays;
    return _startDate.add(Duration(days: days));
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoadingCustomers = true);
    try {
      final res = await _customerRepository.getCustomers();
      if (res.success && res.data != null) {
        setState(() {
          _customerList = res.data!;
          _isLoadingCustomers = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingCustomers = false);
    }
  }

  Future<void> _loadDevicesForCustomer(int customerId) async {
    setState(() => _isLoadingDevices = true);
    try {
      final res = await _deviceRepository.getDevicesForCustomer(customerId);
      if (res.success && res.data != null) {
        setState(() {
          _deviceList = res.data!;
          _isLoadingDevices = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingDevices = false);
    }
  }

  Future<void> _loadSalesOrRepairs() async {
    if (_selectedCustomer == null) return;
    setState(() => _isLoadingSalesOrRepairs = true);
    try {
      if (_warrantyType == 'sale') {
        final res = await _saleRepository.getSales(customerId: _selectedCustomer!.id);
        if (res.success && res.data != null) {
          setState(() {
            _saleList = res.data!;
            _isLoadingSalesOrRepairs = false;
          });
        }
      } else {
        final res = await _repairRepository.getRepairs(customerId: _selectedCustomer!.id);
        if (res.success && res.data != null) {
          setState(() {
            _repairList = res.data!;
            _isLoadingSalesOrRepairs = false;
          });
        }
      }
    } catch (_) {
      setState(() => _isLoadingSalesOrRepairs = false);
    }
  }

  Future<void> _submitWarranty() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomer == null) {
      setState(() => _errorMessage = 'Please select a customer for this warranty.');
      return;
    }

    if (_selectedDevice == null) {
      setState(() => _errorMessage = 'Please select a device for this warranty.');
      return;
    }

    final durationDays = _isCustomDuration
        ? (int.tryParse(_customDurationController.text.trim()) ?? 0)
        : _selectedDurationDays;

    if (durationDays <= 0) {
      setState(() => _errorMessage = 'Please specify a valid warranty duration in days.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final startStr = '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}';
      final coveredPart = _coveredPartController.text.trim();
      final termsText = _termsController.text.trim();

      String combinedTerms = '';
      if (coveredPart.isNotEmpty) {
        combinedTerms = 'Covered Component/Part: $coveredPart';
        if (termsText.isNotEmpty) {
          combinedTerms += '\n$termsText';
        }
      } else {
        combinedTerms = termsText;
      }

      final res = await _warrantyRepository.createWarranty(
        customerId: _selectedCustomer!.id,
        deviceId: _selectedDevice!.id,
        warrantyType: _warrantyType,
        durationDays: durationDays,
        saleId: _selectedSale?.id,
        repairId: _selectedRepair?.id,
        warrantyStartDate: startStr,
        warrantyTerms: combinedTerms,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        if (res.success && res.data != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Warranty ${res.data!.warrantyNumber} created successfully!'),
              backgroundColor: Colors.green.shade700,
            ),
          );
          Navigator.pop(context, true);
        } else {
          setState(() => _errorMessage = res.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final endDateCalc = _endDate;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Issue New Warranty'),
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
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Warranty Type Selector
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Warranty Category *', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _warrantyType = 'sale';
                                _selectedSale = null;
                                _selectedRepair = null;
                              });
                              _loadSalesOrRepairs();
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _warrantyType == 'sale' ? AppColors.primary : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_bag_rounded, color: _warrantyType == 'sale' ? Colors.white : AppColors.textSecondary, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Sale Warranty',
                                    style: TextStyle(
                                      color: _warrantyType == 'sale' ? Colors.white : AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _warrantyType = 'repair';
                                _selectedSale = null;
                                _selectedRepair = null;
                              });
                              _loadSalesOrRepairs();
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _warrantyType == 'repair' ? AppColors.accent : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.build_circle_rounded, color: _warrantyType == 'repair' ? Colors.white : AppColors.textSecondary, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Repair Warranty',
                                    style: TextStyle(
                                      color: _warrantyType == 'repair' ? Colors.white : AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Customer & Device Selector Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Customer & Device *', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Customer>(
                      value: _selectedCustomer,
                      isExpanded: true,
                      hint: _isLoadingCustomers ? const Text('Loading customers...') : const Text('Select Customer *'),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                      ),
                      items: _customerList.map((c) {
                        return DropdownMenuItem<Customer>(
                          value: c,
                          child: Text('${c.name} (${c.mobile})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCustomer = val;
                          _selectedDevice = null;
                          _selectedSale = null;
                          _selectedRepair = null;
                          _deviceList = [];
                        });
                        if (val != null) {
                          _loadDevicesForCustomer(val.id);
                          _loadSalesOrRepairs();
                        }
                      },
                    ),
                    if (_selectedCustomer != null) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Device>(
                        value: _selectedDevice,
                        isExpanded: true,
                        hint: _isLoadingDevices ? const Text('Loading devices...') : const Text('Select Device *'),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.primary),
                        ),
                        items: _deviceList.map((d) {
                          final imeiStr = d.imei1 != null ? ' (IMEI: ${d.imei1})' : '';
                          return DropdownMenuItem<Device>(
                            value: d,
                            child: Text('${d.brand} ${d.model}$imeiStr', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedDevice = val),
                      ),
                    ],
                    if (_selectedCustomer != null) ...[
                      const SizedBox(height: 12),
                      if (_warrantyType == 'sale') ...[
                        DropdownButtonFormField<Sale>(
                          value: _selectedSale,
                          isExpanded: true,
                          hint: _isLoadingSalesOrRepairs ? const Text('Loading sale invoices...') : const Text('Link to Sale Invoice (Optional)'),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                          ),
                          items: _saleList.map((s) {
                            return DropdownMenuItem<Sale>(
                              value: s,
                              child: Text('Invoice #${s.invoiceNumber} - ₹${s.grandTotal.toStringAsFixed(2)} (${s.saleDate})', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedSale = val),
                        ),
                      ] else ...[
                        DropdownButtonFormField<Repair>(
                          value: _selectedRepair,
                          isExpanded: true,
                          hint: _isLoadingSalesOrRepairs ? const Text('Loading repair job cards...') : const Text('Link to Repair Job Card (Optional)'),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.build_circle_rounded, color: AppColors.primary),
                          ),
                          items: _repairList.map((r) {
                            return DropdownMenuItem<Repair>(
                              value: r,
                              child: Text('Job #${r.jobNumber} - ₹${r.netCost.toStringAsFixed(2)} (${r.dateReceived})', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedRepair = val),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Duration & Expiry Calculator Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Warranty Period & Duration *', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._presetDurations.map((d) {
                          final isSelected = !_isCustomDuration && _selectedDurationDays == d;
                          return ChoiceChip(
                            label: Text('$d Days'),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _isCustomDuration = false;
                                  _selectedDurationDays = d;
                                });
                              }
                            },
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }),
                        ChoiceChip(
                          label: const Text('Custom...'),
                          selected: _isCustomDuration,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _isCustomDuration = true);
                            }
                          },
                          selectedColor: AppColors.accent,
                          labelStyle: TextStyle(
                            color: _isCustomDuration ? Colors.white : AppColors.textPrimary,
                            fontWeight: _isCustomDuration ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    if (_isCustomDuration) ...[
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Custom Duration (Days) *',
                        hint: 'Enter number of days (e.g. 45 or 120)',
                        controller: _customDurationController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() => _startDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Start Date', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  const SizedBox(height: 2),
                                  Text('${_startDate.day}/${_startDate.month}/${_startDate.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              border: Border.all(color: Colors.green.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Calculated Expiry Date', style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text('${endDateCalc.day}/${endDateCalc.month}/${endDateCalc.year}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade900)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Covered Part / Component Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.build_circle_rounded, color: AppColors.accent, size: 20),
                        SizedBox(width: 8),
                        Text('Covered Component / Part Changed', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presetCoveredParts.map((partName) {
                        final isSelected = _coveredPartController.text.trim() == partName;
                        return ChoiceChip(
                          label: Text(partName),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _coveredPartController.text = selected ? partName : '';
                            });
                          },
                          selectedColor: AppColors.accent.withOpacity(0.2),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.accent : AppColors.textPrimary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Part / Component Name Covered',
                      hint: 'e.g. Display Folder / Original Battery / Charging Sub-board',
                      controller: _coveredPartController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Terms & Conditions Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Warranty Terms & Notes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Warranty Terms & Inclusions (Optional)',
                      hint: 'e.g. Covers screen replacement for touch failure only. Physical & liquid damage void.',
                      controller: _termsController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Internal Shop Notes (Optional)',
                      hint: 'Private note for shop reference',
                      controller: _notesController,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: 'Issue Warranty',
                isLoading: _isSubmitting,
                onPressed: _submitWarranty,
                icon: Icons.verified_rounded,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
