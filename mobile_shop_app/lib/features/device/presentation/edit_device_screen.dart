import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/device_repository.dart';
import '../models/device.dart';

class EditDeviceScreen extends StatefulWidget {
  final Device device;
  const EditDeviceScreen({super.key, required this.device});

  @override
  State<EditDeviceScreen> createState() => _EditDeviceScreenState();
}

class _EditDeviceScreenState extends State<EditDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _variantController;
  late TextEditingController _colorController;
  late TextEditingController _imei1Controller;
  late TextEditingController _imei2Controller;
  late TextEditingController _serialController;
  late TextEditingController _notesController;

  final DeviceRepository _repository = DeviceRepository();
  late String _selectedDeviceType;
  DateTime? _selectedPurchaseDate;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _deviceTypes = ['Mobile', 'Tablet', 'Laptop', 'Other'];

  @override
  void initState() {
    super.initState();
    _selectedDeviceType = widget.device.deviceType;
    _brandController = TextEditingController(text: widget.device.brand);
    _modelController = TextEditingController(text: widget.device.model);
    _variantController = TextEditingController(text: widget.device.variant ?? '');
    _colorController = TextEditingController(text: widget.device.color ?? '');
    _imei1Controller = TextEditingController(text: widget.device.imei1 ?? '');
    _imei2Controller = TextEditingController(text: widget.device.imei2 ?? '');
    _serialController = TextEditingController(text: widget.device.serialNumber ?? '');
    _notesController = TextEditingController(text: widget.device.notes ?? '');

    if (widget.device.purchaseDate != null && widget.device.purchaseDate!.isNotEmpty) {
      try {
        _selectedPurchaseDate = DateTime.parse(widget.device.purchaseDate!);
      } catch (_) {}
    }
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedPurchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedPurchaseDate = picked;
      });
    }
  }

  Future<void> _handleUpdateDevice() async {
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
      final response = await _repository.updateDevice(
        id: widget.device.id,
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
        if (response.success && response.data != null) {
          final updatedDevice = Device.fromJson(response.data);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Device details updated successfully')),
          );
          Navigator.pop(context, updatedDevice);
        } else {
          setState(() {
            _errorMessage = response.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
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
        title: const Text('Edit Device Details'),
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
                      CustomTextField(
                        label: 'Brand *',
                        controller: _brandController,
                        prefixIcon: Icons.phone_iphone_rounded,
                        validator: (val) => (val == null || val.isEmpty) ? 'Enter device brand' : null,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Model Name *',
                        controller: _modelController,
                        prefixIcon: Icons.devices_rounded,
                        validator: (val) => (val == null || val.isEmpty) ? 'Enter device model' : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Variant / Storage',
                              controller: _variantController,
                              prefixIcon: Icons.memory_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              label: 'Color',
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

                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Identifiers & Serial', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'IMEI 1 (15 Digits)',
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
                        label: 'IMEI 2 (Dual SIM)',
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
                        label: 'Serial Number',
                        controller: _serialController,
                        prefixIcon: Icons.tag_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Purchase Date & Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _pickPurchaseDate,
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Purchase Date',
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
                        label: 'Notes',
                        controller: _notesController,
                        prefixIcon: Icons.note_alt_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: 'Save Changes',
                  isLoading: _isLoading,
                  onPressed: _handleUpdateDevice,
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