import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/customer_repository.dart';
import '../models/customer.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _alternateMobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();

  final CustomerRepository _repository = CustomerRepository();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleSaveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _repository.createCustomer(
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        alternateMobile: _alternateMobileController.text.trim().isNotEmpty ? _alternateMobileController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer added successfully')),
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
        if (e is ApiException && e.statusCode == 409 && e.errors != null && e.errors['existing_customer'] != null) {
          final existingCustomer = Customer.fromJson(e.errors['existing_customer']);
          _showDuplicateCustomerDialog(existingCustomer);
        } else if (e is ApiException) {
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

  void _showDuplicateCustomerDialog(Customer existingCustomer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Customer Exists', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(
          'A customer with mobile number ${existingCustomer.mobile} (${existingCustomer.name}) already exists in your shop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close add screen
              Navigator.pushNamed(
                context,
                AppRoutes.customerDetails,
                arguments: existingCustomer,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Open Existing Customer'),
          ),
        ],
      ),
    );
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
        title: const Text('Add New Customer'),
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
                      const Text('Required Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
                        label: 'Mobile Number (10 Digits) *',
                        hint: 'e.g. 9876543210',
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_android_rounded,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Enter mobile number';
                          final regExp = RegExp(r'^[6-9]\d{9}$');
                          if (!regExp.hasMatch(val)) return 'Enter valid 10-digit Indian mobile number (starts 6-9)';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Optional Contact Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Alternate Mobile (Optional)',
                        hint: 'e.g. 9123456789',
                        controller: _alternateMobileController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        validator: (val) {
                          if (val != null && val.isNotEmpty) {
                            final regExp = RegExp(r'^[6-9]\d{9}$');
                            if (!regExp.hasMatch(val)) return 'Enter valid 10-digit mobile';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Email Address (Optional)',
                        hint: 'e.g. customer@gmail.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Address (Optional)',
                        hint: 'e.g. 101 Royal Residency',
                        controller: _addressController,
                        prefixIcon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'City (Optional)',
                        hint: 'e.g. Ahmedabad',
                        controller: _cityController,
                        prefixIcon: Icons.location_city_outlined,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Notes / Remarks (Optional)',
                        hint: 'e.g. VIP customer, regular repair work',
                        controller: _notesController,
                        prefixIcon: Icons.note_alt_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: 'Save Customer',
                  isLoading: _isLoading,
                  onPressed: _handleSaveCustomer,
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