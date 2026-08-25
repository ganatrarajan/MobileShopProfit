import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/repair_repository.dart';
import '../models/repair.dart';

class EditRepairScreen extends StatefulWidget {
  final Repair repair;
  const EditRepairScreen({super.key, required this.repair});

  @override
  State<EditRepairScreen> createState() => _EditRepairScreenState();
}

class _EditRepairScreenState extends State<EditRepairScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repairRepository = RepairRepository();

  late TextEditingController _problemController;
  late TextEditingController _conditionNotesController;
  late TextEditingController _accessoriesNotesController;
  late TextEditingController _pinPasscodeController;
  late TextEditingController _estimatedCostController;
  late TextEditingController _finalCostController;
  late TextEditingController _labourCostController;
  late TextEditingController _customerNotesController;
  late TextEditingController _internalNotesController;

  DateTime? _expectedDeliveryDate;
  bool _obscurePin = true;

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
  late Set<String> _selectedConditions;

  final List<String> _availableAccessories = [
    'Charger',
    'Cable',
    'SIM',
    'Memory Card',
    'Cover',
    'Box',
    'Other',
  ];
  late Set<String> _selectedAccessories;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final r = widget.repair;
    _problemController = TextEditingController(text: r.problemDescription);
    _conditionNotesController = TextEditingController(text: r.conditionNotes);
    _accessoriesNotesController = TextEditingController(text: r.accessoriesNotes);
    _pinPasscodeController = TextEditingController(text: r.pinPasscode);
    _estimatedCostController = TextEditingController(text: r.estimatedCost > 0 ? r.estimatedCost.toStringAsFixed(2) : '');
    _finalCostController = TextEditingController(text: r.finalCost > 0 ? r.finalCost.toStringAsFixed(2) : '');
    _labourCostController = TextEditingController(text: r.labourCost > 0 ? r.labourCost.toStringAsFixed(2) : '');
    _customerNotesController = TextEditingController(text: r.customerNotes);
    _internalNotesController = TextEditingController(text: r.internalNotes);

    _selectedConditions = Set.from(r.deviceCondition);
    _selectedAccessories = Set.from(r.accessoriesReceived);

    if (r.expectedDeliveryDate != null) {
      _expectedDeliveryDate = DateTime.tryParse(r.expectedDeliveryDate!);
    }
  }

  @override
  void dispose() {
    _problemController.dispose();
    _conditionNotesController.dispose();
    _accessoriesNotesController.dispose();
    _pinPasscodeController.dispose();
    _estimatedCostController.dispose();
    _finalCostController.dispose();
    _labourCostController.dispose();
    _customerNotesController.dispose();
    _internalNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final estimatedCost = double.tryParse(_estimatedCostController.text.trim()) ?? 0.0;
      final finalCost = double.tryParse(_finalCostController.text.trim()) ?? 0.0;
      final labourCost = double.tryParse(_labourCostController.text.trim()) ?? 0.0;

      final dateStr = _expectedDeliveryDate != null
          ? '${_expectedDeliveryDate!.year}-${_expectedDeliveryDate!.month.toString().padLeft(2, '0')}-${_expectedDeliveryDate!.day.toString().padLeft(2, '0')}'
          : null;

      final res = await _repairRepository.updateRepair(
        id: widget.repair.id,
        problemDescription: _problemController.text.trim(),
        deviceCondition: _selectedConditions.toList(),
        conditionNotes: _conditionNotesController.text.trim(),
        accessoriesReceived: _selectedAccessories.toList(),
        accessoriesNotes: _accessoriesNotesController.text.trim(),
        pinPasscode: _pinPasscodeController.text.trim(),
        expectedDeliveryDate: dateStr,
        estimatedCost: estimatedCost,
        finalCost: finalCost,
        labourCost: labourCost,
        customerNotes: _customerNotesController.text.trim(),
        internalNotes: _internalNotesController.text.trim(),
      );

      if (mounted) {
        if (res.success && res.data != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Job Card ${widget.repair.jobNumber} updated successfully.'),
              backgroundColor: Colors.green.shade700,
            ),
          );
          Navigator.pop(context, true);
        } else {
          setState(() => _errorMessage = res.message);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit Job Card #${widget.repair.jobNumber}'),
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

              // Problem & Complaint
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Customer Complaint / Problem', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Problem Description *',
                      controller: _problemController,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Device Condition
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Device Condition', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Condition Notes',
                      controller: _conditionNotesController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Accessories Received
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Accessories Received', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Accessories Notes',
                      controller: _accessoriesNotesController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Costs & Financials
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Repair Pricing & Labour', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Estimated Cost (₹)',
                            controller: _estimatedCostController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomTextField(
                            label: 'Final Cost (₹)',
                            controller: _finalCostController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Labour Amount (₹)',
                      controller: _labourCostController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Security & Notes
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _pinPasscodeController,
                      obscureText: _obscurePin,
                      decoration: InputDecoration(
                        labelText: 'PIN / Pattern Passcode',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePin = !_obscurePin),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Customer Notes',
                      controller: _customerNotesController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Internal Technician Log',
                      controller: _internalNotesController,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: 'Save Changes',
                isLoading: _isSubmitting,
                onPressed: _submitUpdate,
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
