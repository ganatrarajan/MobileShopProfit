import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/purchase_repository.dart';
import '../../models/vendor.dart';

class QuickAddVendorModal extends StatefulWidget {
  final Vendor? vendorToEdit;

  const QuickAddVendorModal({super.key, this.vendorToEdit});

  static Future<Vendor?> show(BuildContext context, {Vendor? vendorToEdit}) {
    return showModalBottomSheet<Vendor>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickAddVendorModal(vendorToEdit: vendorToEdit),
    );
  }

  @override
  State<QuickAddVendorModal> createState() => _QuickAddVendorModalState();
}

class _QuickAddVendorModalState extends State<QuickAddVendorModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _gstController;
  late TextEditingController _notesController;

  final PurchaseRepository _repository = PurchaseRepository();
  bool _isLoading = false;

  bool get _isEditing => widget.vendorToEdit != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vendorToEdit;
    _nameController = TextEditingController(text: v?.name ?? '');
    _phoneController = TextEditingController(text: v?.phone ?? '');
    _emailController = TextEditingController(text: v?.email ?? '');
    _addressController = TextEditingController(text: v?.address ?? '');
    _gstController = TextEditingController(text: v?.gstNumber ?? '');
    _notesController = TextEditingController(text: v?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (_isEditing) {
      final response = await _repository.updateVendor(
        id: widget.vendorToEdit!.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        gstNumber: _gstController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (mounted) setState(() => _isLoading = false);

      if (response.success && response.data != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vendor Updated Successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, response.data);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message.isNotEmpty ? response.message : 'Failed to update vendor.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } else {
      final response = await _repository.createVendor(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        gstNumber: _gstController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (mounted) setState(() => _isLoading = false);

      if (response.success && response.data != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vendor Created Successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, response.data);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message.isNotEmpty ? response.message : 'Failed to create vendor.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Vendor Details' : '+ Add New Vendor',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                label: 'Vendor / Supplier Name *',
                hint: 'e.g. ABC Mobile Parts',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter vendor name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _phoneController,
                label: 'Mobile Number *',
                hint: 'e.g. 9876543210',
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter vendor mobile number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _emailController,
                label: 'Email Address (Optional)',
                hint: 'e.g. vendor@parts.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _gstController,
                label: 'GST Number (Optional)',
                hint: 'e.g. 24ABCDE1234F1Z5',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _addressController,
                label: 'Address (Optional)',
                hint: 'Enter supplier shop address',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'Internal notes about supplier',
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: _isEditing ? 'Update Vendor' : 'Save Vendor',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
