import '../../technician/data/technician_repository.dart';
import '../../technician/models/technician.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../customer/data/customer_repository.dart';
import '../../customer/models/customer.dart';
import '../../device/data/device_repository.dart';
import '../../device/models/device.dart';
import '../data/repair_repository.dart';

class CreateRepairScreen extends StatefulWidget {
  const CreateRepairScreen({super.key});

  @override
  State<CreateRepairScreen> createState() => _CreateRepairScreenState();
}

class _CreateRepairScreenState extends State<CreateRepairScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repairRepository = RepairRepository();
  final _customerRepository = CustomerRepository();
  final _deviceRepository = DeviceRepository();
  final _technicianRepository = TechnicianRepository();
  Technician? _selectedTechnician;
  List<Technician> _technicianList = [];
  bool _isLoadingTechnicians = false;

  Customer? _selectedCustomer;
  Device? _selectedDevice;
  List<Customer> _customerList = [];
  List<Device> _deviceList = [];
  bool _isLoadingCustomers = false;
  bool _isLoadingDevices = false;

  final _problemController = TextEditingController();
  final _conditionNotesController = TextEditingController();
  final _accessoriesNotesController = TextEditingController();
  final _pinPasscodeController = TextEditingController();
  final _estimatedCostController = TextEditingController();
  final _technicianEarningController = TextEditingController();
  final _advancePaymentController = TextEditingController();
  final _customerNotesController = TextEditingController();
  final _internalNotesController = TextEditingController();

  DateTime? _expectedDeliveryDate;
  String _paymentMethod = 'cash';
  bool _obscurePin = true;

  // Conditions Selection
  final List<String> _availableConditions = [
    'Screen damaged',
    'Body damaged',
    'Back glass damaged',
    'Camera damaged',
    'Water damage',
    'No visible damage',
    'Speaker issue',
    'Other',
  ];
  final Set<String> _selectedConditions = {};

  // Accessories Selection
  final List<String> _availableAccessories = [
    'Charger',
    'Cable',
    'SIM',
    'Memory Card',
    'Cover',
    'Box',
    'Other',
  ];
  final Set<String> _selectedAccessories = {};

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadTechnicians();
  }

  @override
  void dispose() {
    _problemController.dispose();
    _conditionNotesController.dispose();
    _accessoriesNotesController.dispose();
    _pinPasscodeController.dispose();
    _estimatedCostController.dispose();
    _advancePaymentController.dispose();
    _customerNotesController.dispose();
    _internalNotesController.dispose();
    super.dispose();
  }

    Future<void> _loadTechnicians() async {
    setState(() => _isLoadingTechnicians = true);
    try {
      final res = await _technicianRepository.getTechnicians(status: 'active');
      if (mounted && res.success && res.data != null) {
        setState(() {
          _technicianList = res.data!.technicians;
          _isLoadingTechnicians = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTechnicians = false);
    }
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

  Future<void> _submitRepair() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomer == null) {
      setState(() => _errorMessage = 'Please select a customer for this repair.');
      return;
    }

    if (_selectedDevice == null) {
      setState(() => _errorMessage = 'Please select a customer device for this repair.');
      return;
    }

    if (_problemController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please describe the customer complaint / problem.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final estimatedCost = double.tryParse(_estimatedCostController.text.trim()) ?? 0.0;
      final advancePayment = double.tryParse(_advancePaymentController.text.trim()) ?? 0.0;

      final dateStr = _expectedDeliveryDate != null
          ? '${_expectedDeliveryDate!.year}-${_expectedDeliveryDate!.month.toString().padLeft(2, '0')}-${_expectedDeliveryDate!.day.toString().padLeft(2, '0')}'
          : null;

      final response = await _repairRepository.createRepair(
        customerId: _selectedCustomer!.id,
        deviceId: _selectedDevice!.id,
        technicianId: _selectedTechnician?.id,
        technicianEarning: double.tryParse(_technicianEarningController.text) ?? 0.0,
        problemDescription: _problemController.text.trim(),
        deviceCondition: _selectedConditions.toList(),
        conditionNotes: _conditionNotesController.text.trim(),
        accessoriesReceived: _selectedAccessories.toList(),
        accessoriesNotes: _accessoriesNotesController.text.trim(),
        pinPasscode: _pinPasscodeController.text.trim(),
        expectedDeliveryDate: dateStr,
        estimatedCost: estimatedCost,
        paymentAmount: advancePayment,
        paymentMethod: _paymentMethod,
        customerNotes: _customerNotesController.text.trim(),
        internalNotes: _internalNotesController.text.trim(),
      );

      if (mounted) {
        if (response.success && response.data != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Job Card ${response.data!.jobNumber} created successfully!'),
              backgroundColor: Colors.green.shade700,
            ),
          );
          Navigator.pop(context, true);
        } else {
          setState(() => _errorMessage = response.message);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Repair Job Card'),
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
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Customer & Device Selection Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_pin_rounded, color: AppColors.accent, size: 20),
                        SizedBox(width: 8),
                        Text('Customer & Device *', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Customer>(
                      value: (_selectedCustomer != null && _customerList.any((c) => c.id == _selectedCustomer!.id))
                          ? _customerList.firstWhere((c) => c.id == _selectedCustomer!.id)
                          : null,
                      isExpanded: true,
                      hint: _isLoadingCustomers
                          ? const Text('Loading customers...')
                          : const Text('Select Customer *'),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
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
                          _deviceList = [];
                        });
                        if (val != null) {
                          _loadDevicesForCustomer(val.id);
                        }
                      },
                    ),
                    if (_selectedCustomer != null) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Device>(
                        value: (_selectedDevice != null && _deviceList.any((d) => d.id == _selectedDevice!.id))
                            ? _deviceList.firstWhere((d) => d.id == _selectedDevice!.id)
                            : null,
                        isExpanded: true,
                        hint: _isLoadingDevices
                            ? const Text('Loading customer devices...')
                            : const Text('Select Customer Device *'),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.primary),
                        ),
                        items: _deviceList.map((d) {
                          final imeiStr = d.imei1 != null ? ' - ${d.imei1}' : '';
                          return DropdownMenuItem<Device>(
                            value: d,
                            child: Text('${d.brand} ${d.model}$imeiStr', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedDevice = val);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

                            // Technician Selection Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.engineering_rounded, color: AppColors.accent, size: 20),
                        SizedBox(width: 8),
                        Text('Assign Technician', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Assign an active technician to handle this repair job', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Technician>(
                      value: (_selectedTechnician != null && _technicianList.any((t) => t.id == _selectedTechnician!.id))
                          ? _technicianList.firstWhere((t) => t.id == _selectedTechnician!.id)
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.engineering_rounded, color: AppColors.primary),
                      ),
                      hint: _isLoadingTechnicians ? const Text('Loading technicians...') : const Text('Select Technician (Optional)'),
                      items: _technicianList.map((t) {
                        final String displayName = (t.specialization != null && t.specialization!.isNotEmpty)
                            ? '${t.name} (${t.specialization})'
                            : t.name;
                        return DropdownMenuItem<Technician>(
                          value: t,
                          child: Text(
                            displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedTechnician = val),
                    ),
                    if (_selectedTechnician != null) ...[
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Technician Earning (\u{20B9})',
                        hint: 'Enter fixed earning for technician (e.g. 200)',
                        controller: _technicianEarningController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.currency_rupee_rounded,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (ctx) {
                          final repairCost = double.tryParse(_estimatedCostController.text) ?? 0.0;
                          final techEarning = double.tryParse(_technicianEarningController.text) ?? 0.0;
                          final shopShare = (repairCost - techEarning) < 0 ? 0.0 : (repairCost - techEarning);
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Shop Share: \u{20B9}${shopShare.toStringAsFixed(2)}',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tech Earning: \u{20B9}${techEarning.toStringAsFixed(2)}',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 2. Complaint & Problem Description Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.report_problem_outlined, color: AppColors.accent, size: 20),
                        SizedBox(width: 8),
                        Text('Problem & Complaint *', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Customer Problem Description *',
                      hint: 'e.g. Display glass broken, touch not working after fall',
                      controller: _problemController,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Device Condition Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.checklist_rounded, color: AppColors.accent, size: 20),
                        SizedBox(width: 8),
                        Text('Device Condition at Receiving', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableConditions.map((cond) {
                        final isSelected = _selectedConditions.contains(cond);
                        return FilterChip(
                          label: Text(cond),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedConditions.add(cond);
                              } else {
                                _selectedConditions.remove(cond);
                              }
                            });
                          },
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Other Condition Notes (Optional)',
                      hint: 'e.g. Back cover missing screw, frame dent on left side',
                      controller: _conditionNotesController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Accessories Received Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.devices_other_rounded, color: AppColors.accent, size: 20),
                        SizedBox(width: 8),
                        Text('Accessories Received', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableAccessories.map((acc) {
                        final isSelected = _selectedAccessories.contains(acc);
                        return FilterChip(
                          label: Text(acc),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAccessories.add(acc);
                              } else {
                                _selectedAccessories.remove(acc);
                              }
                            });
                          },
                          selectedColor: AppColors.accent.withOpacity(0.2),
                          checkmarkColor: AppColors.accent,
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
                      label: 'Accessories Notes (Optional)',
                      hint: 'e.g. Samsung 25W charger provided without cable',
                      controller: _accessoriesNotesController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Secure Passcode & Delivery Date Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, color: AppColors.accent, size: 20),
                        SizedBox(width: 8),
                        Text('Security & Delivery Schedule', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pinPasscodeController,
                      obscureText: _obscurePin,
                      decoration: InputDecoration(
                        labelText: 'PIN / Pattern Passcode (Optional)',
                        hintText: 'e.g. 1234 or Pattern note',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted),
                          onPressed: () => setState(() => _obscurePin = !_obscurePin),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(const Duration(days: 1)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (picked != null) {
                                setState(() => _expectedDeliveryDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.event_rounded, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _expectedDeliveryDate != null
                                          ? 'Expected: ${_expectedDeliveryDate!.day}/${_expectedDeliveryDate!.month}/${_expectedDeliveryDate!.year}'
                                          : 'Expected Delivery Date',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _expectedDeliveryDate != null ? AppColors.textPrimary : AppColors.textMuted,
                                        fontWeight: _expectedDeliveryDate != null ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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

              // 6. Cost Estimation & Advance Payment Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.payments_outlined, color: AppColors.accent, size: 20),
                        SizedBox(width: 8),
                        Text('Estimate & Advance Payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Estimated Cost (₹)',
                            hint: '0.00',
                            controller: _estimatedCostController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'Advance Paid (₹)',
                            hint: '0.00',
                            controller: _advancePaymentController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Advance Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'upi', child: Text('UPI / PhonePe / GPay')),
                        DropdownMenuItem(value: 'card', child: Text('Credit / Debit Card')),
                        DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _paymentMethod = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 7. Internal & Customer Notes Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Additional Notes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Customer Notes (Visible on Job Card)',
                      hint: 'Special instructions for customer',
                      controller: _customerNotesController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Internal Technician Notes (Shop Only)',
                      hint: 'Private notes for technician',
                      controller: _internalNotesController,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: 'Save Repair & Generate Job Card',
                isLoading: _isSubmitting,
                onPressed: _submitRepair,
                icon: Icons.build_circle_rounded,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
