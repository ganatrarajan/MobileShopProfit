import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/customer_repository.dart';
import '../../models/customer.dart';

class QuickAddCustomerModal extends StatefulWidget {
  const QuickAddCustomerModal({super.key});

  static Future<Customer?> show(BuildContext context) async {
    return await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const QuickAddCustomerModal(),
    );
  }

  @override
  State<QuickAddCustomerModal> createState() => _QuickAddCustomerModalState();
}

class _QuickAddCustomerModalState extends State<QuickAddCustomerModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _customerRepository = CustomerRepository();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final response = await _customerRepository.createCustomer(
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (response.success) {
          Customer? createdCustomer;
          if (response.data != null) {
            if (response.data is Map<String, dynamic>) {
              final map = response.data as Map<String, dynamic>;
              final customerData = map.containsKey('customer') ? map['customer'] : map;
              createdCustomer = Customer.fromJson(Map<String, dynamic>.from(customerData));
            } else if (response.data is Customer) {
              createdCustomer = response.data as Customer;
            }
          }

          // Fallback if ID wasn't in response body
          createdCustomer ??= Customer(
            id: DateTime.now().millisecondsSinceEpoch,
            shopId: 0,
            name: _nameController.text.trim(),
            mobile: _mobileController.text.trim(),
            email: _emailController.text.trim(),
            address: _addressController.text.trim(),
          );

          AppFeedback.showSuccess(
            context,
            title: '✅ Customer Added',
            message: '${createdCustomer.name} has been added successfully.',
          );
          Navigator.pop(context, createdCustomer);
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
                  child: const Icon(Icons.person_add_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Add Customer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Enter customer info to select automatically',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
            const Divider(height: 24),
            CustomTextField(
              label: 'Full Name',
              hint: 'e.g. Rajesh Patel',
              controller: _nameController,
              isRequired: true,
              prefixIcon: Icons.person_outline,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter customer full name.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Mobile Number',
              hint: 'e.g. 9876543210',
              controller: _mobileController,
              isRequired: true,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter mobile number.';
                if (v.trim().length < 8) return 'Please enter a valid mobile number.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Address (Optional)',
              hint: 'e.g. Shop 12, Main Market',
              controller: _addressController,
              prefixIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: _isSaving ? 'Adding Customer...' : 'Save & Select Customer',
              icon: Icons.check,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
