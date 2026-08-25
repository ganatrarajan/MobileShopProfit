import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/customer_repository.dart';
import '../models/customer.dart';

class EditCustomerScreen extends StatefulWidget {
  final Customer customer;
  const EditCustomerScreen({super.key, required this.customer});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _alternateMobileController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _notesController;

  final CustomerRepository _repository = CustomerRepository();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _mobileController = TextEditingController(text: widget.customer.mobile);
    _alternateMobileController = TextEditingController(text: widget.customer.alternateMobile ?? '');
    _emailController = TextEditingController(text: widget.customer.email ?? '');
    _addressController = TextEditingController(text: widget.customer.address ?? '');
    _cityController = TextEditingController(text: widget.customer.city ?? '');
    _notesController = TextEditingController(text: widget.customer.notes ?? '');
  }

  Future<void> _handleUpdateCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _repository.updateCustomer(
        id: widget.customer.id,
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        alternateMobile: _alternateMobileController.text.trim().isNotEmpty ? _alternateMobileController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          final updatedCustomer = Customer.fromJson(response.data);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer updated successfully')),
          );
          Navigator.pop(context, updatedCustomer);
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

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _alternateMobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Customer'),
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
                      const Text('Customer Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Customer Full Name *',
                        hint: 'e.g. Ramesh Patel',
                        controller: _nameController,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (val) => (val == null || val.isEmpty) ? 'Enter customer name' : null,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Mobile Number *',
                        hint: 'e.g. 9876543210',
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_android_rounded,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Enter mobile number';
                          final regExp = RegExp(r'^[6-9]\d{9}$');
                          if (!regExp.hasMatch(val)) return 'Enter valid 10-digit Indian mobile number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Alternate Mobile',
                        hint: 'e.g. 9123456789',
                        controller: _alternateMobileController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Email',
                        hint: 'e.g. customer@gmail.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Address',
                        hint: 'e.g. 101 Royal Residency',
                        controller: _addressController,
                        prefixIcon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'City',
                        hint: 'e.g. Ahmedabad',
                        controller: _cityController,
                        prefixIcon: Icons.location_city_outlined,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Notes',
                        hint: 'e.g. VIP customer, regular repair work',
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
                  onPressed: _handleUpdateCustomer,
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