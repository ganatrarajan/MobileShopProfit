import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/purchase_repository.dart';
import '../../models/vendor.dart';

class QuickAddVendorModal extends StatefulWidget {
  const QuickAddVendorModal({super.key});

  static Future<Vendor?> show(BuildContext context) {
    return showModalBottomSheet<Vendor>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickAddVendorModal(),
    );
  }

  @override
  State<QuickAddVendorModal> createState() => _QuickAddVendorModalState();
}

class _QuickAddVendorModalState extends State<QuickAddVendorModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  final _notesController = TextEditingController();

  final PurchaseRepository _repository = PurchaseRepository();
  bool _isLoading = false;

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

    final response = await _repository.createVendor(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      gstNumber: _gstController.text.trim(),
      notes: _notesController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (response.success && response.data != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('? Vendor Created Successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, response.data);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message.isNotEmpty ? response.message : 'Please select or enter a vendor name.'),
            backgroundColor: AppColors.error,
          ),
        );
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
                  const Text(
                    '+ Add New Vendor',
                    style: TextStyle(
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
                    return 'Please select or enter a vendor name.';
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
              const SizedBox(height: 20),
              CustomButton(
                text: 'Save Vendor',
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
