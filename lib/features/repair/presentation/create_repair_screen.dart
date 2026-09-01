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
            final filteredCustomers = _customerList.where((c) {
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
                    onChanged: (val) {
                      setModalState(() => filterQuery = val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by customer name or mobile...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isLoadingCustomers
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : filteredCustomers.isEmpty
                            ? const Center(child: Text('No customers found', style: TextStyle(color: AppColors.textSecondary)))
                            : ListView.separated(
                                itemCount: filteredCustomers.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final customer = filteredCustomers[idx];
                                  final isSelected = _selectedCustomer?.id == customer.id;
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
                                        _selectedCustomer = customer;
                                        _selectedDevice = null;
                                        _deviceList = [];
                                      });
                                      _loadDevicesForCustomer(customer.id);
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

  void _showDeviceSearchBottomSheet() {
    if (_selectedCustomer == null) return;
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
            final filteredDevices = _deviceList.where((d) {
              final q = filterQuery.toLowerCase();
              return d.brand.toLowerCase().contains(q) ||
                  d.model.toLowerCase().contains(q) ||
                  (d.imei1 != null && d.imei1!.contains(q));
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
                        'Select Customer Device',
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
                      hintText: 'Search model, brand, IMEI...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isLoadingDevices
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : filteredDevices.isEmpty
                            ? const Center(child: Text('No devices found', style: TextStyle(color: AppColors.textSecondary)))
                            : ListView.separated(
                                itemCount: filteredDevices.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final device = filteredDevices[idx];
                                  final isSelected = _selectedDevice?.id == device.id;
                                  final imeiStr = device.imei1 != null ? 'IMEI: ${device.imei1}' : '';
                                  return ListTile(
                                    title: Text(
                                      '${device.brand} ${device.model}',
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                    subtitle: imeiStr.isNotEmpty ? Text(imeiStr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)) : null,
                                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedDevice = device;
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

  void _showTechnicianSearchBottomSheet() {
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
            final filteredTechs = _technicianList.where((t) {
              final q = filterQuery.toLowerCase();
              return t.name.toLowerCase().contains(q) ||
                  (t.mobile != null && t.mobile!.contains(q)) ||
                  (t.specialization != null && t.specialization!.toLowerCase().contains(q));
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
                        'Select Technician',
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
                      hintText: 'Search technician name or skill...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isLoadingTechnicians
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : filteredTechs.isEmpty
                            ? const Center(child: Text('No technicians found', style: TextStyle(color: AppColors.textSecondary)))
                            : ListView.separated(
                                itemCount: filteredTechs.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final tech = filteredTechs[idx];
                                  final isSelected = _selectedTechnician?.id == tech.id;
                                  final spec = tech.specialization ?? 'General Technician';
                                  return ListTile(
                                    title: Text(
                                      tech.name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                    subtitle: Text(spec, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedTechnician = tech;
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
                    InkWell(
                      onTap: _showCustomerSearchBottomSheet,
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Customer *',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.person_rounded, color: AppColors.primary),
                          suffixIcon: const Icon(Icons.search_rounded, size: 22, color: AppColors.primary),
                        ),
                        child: Text(
                          _selectedCustomer != null
                              ? '${_selectedCustomer!.name} (${_selectedCustomer!.mobile})'
                              : (_isLoadingCustomers ? 'Loading customers...' : 'Tap to search & select customer (${_customerList.length} registered)'),
                          style: TextStyle(
                            color: _selectedCustomer == null ? AppColors.textMuted : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: _selectedCustomer != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (_selectedCustomer != null) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _showDeviceSearchBottomSheet,
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Customer Device *',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.primary),
                            suffixIcon: const Icon(Icons.search_rounded, size: 22, color: AppColors.primary),
                          ),
                          child: Text(
                            _selectedDevice != null
                                ? '${_selectedDevice!.brand} ${_selectedDevice!.model}${_selectedDevice!.imei1 != null ? ' (IMEI: ${_selectedDevice!.imei1})' : ''}'
                                : (_isLoadingDevices ? 'Loading devices...' : 'Tap to search & select device (${_deviceList.length} available)'),
                            style: TextStyle(
                              color: _selectedDevice == null ? AppColors.textMuted : AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: _selectedDevice != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
                    InkWell(
                      onTap: _showTechnicianSearchBottomSheet,
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Assign Technician (Optional)',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.engineering_rounded, color: AppColors.primary),
                          suffixIcon: const Icon(Icons.search_rounded, size: 22, color: AppColors.primary),
                        ),
                        child: Text(
                          _selectedTechnician != null
                              ? '${_selectedTechnician!.name}${_selectedTechnician!.specialization != null ? ' (${_selectedTechnician!.specialization})' : ''}'
                              : (_isLoadingTechnicians ? 'Loading technicians...' : 'Tap to search & select technician (${_technicianList.length} available)'),
                          style: TextStyle(
                            color: _selectedTechnician == null ? AppColors.textMuted : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: _selectedTechnician != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
