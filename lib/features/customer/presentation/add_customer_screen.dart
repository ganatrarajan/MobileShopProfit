import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/digital_signature_pad_dialog.dart';
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
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _errorMessage;
  File? _signatureFile;

  void _showFormError(String errorMsg) {
    FocusManager.instance.primaryFocus?.unfocus();
    AppFeedback.showError(context, error: errorMsg);
    setState(() => _errorMessage = errorMsg);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickSignature() async {
    await SignaturePickerHelper.showOptions(
      context: context,
      title: 'Customer Signature (Optional)',
      hasExistingSignature: _signatureFile != null,
      onSignaturePicked: (File file) {
        setState(() => _signatureFile = file);
      },
      onSignatureCleared: () {
        setState(() => _signatureFile = null);
      },
    );
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleSaveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      _showFormError('Please check the highlighted errors in the form.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final nameStr = _nameController.text.trim();
      final response = await _repository.createCustomer(
        name: nameStr,
        mobile: _mobileController.text.trim(),
        alternateMobile: _alternateMobileController.text.trim().isNotEmpty ? _alternateMobileController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        signature: _signatureFile?.path,
      );

      if (mounted) {
        if (response.success) {
          AppFeedback.showSuccess(
            context,
            title: '✅ Customer Added',
            message: '$nameStr has been added successfully.',
          );
          Navigator.pop(context, true);
        } else {
          _showFormError(response.message);
        }
      }
    } catch (e) {
      if (mounted) {
        if (e is ApiException && e.statusCode == 409 && e.errors != null && e.errors['existing_customer'] != null) {
          final existingCustomer = Customer.fromJson(e.errors['existing_customer']);
          _showDuplicateCustomerDialog(existingCustomer);
        } else if (e is ApiException) {
          _showFormError(e.message);
        } else {
          _showFormError(e.toString());
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
    _scrollController.dispose();
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
          controller: _scrollController,
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
                        label: 'Customer Full Name',
                        hint: 'e.g. Ramesh Patel',
                        controller: _nameController,
                        isRequired: true,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter customer full name.' : null,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Mobile Number',
                        hint: 'e.g. 9876543210',
                        controller: _mobileController,
                        isRequired: true,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_android_rounded,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Please enter mobile number.';
                          if (val.trim().length < 8) return 'Please enter a valid mobile number.';
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
                const SizedBox(height: 16),

                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Customer Signature',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Optional', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Draw digital finger signature or upload photo signature for invoice and job cards.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _pickSignature,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _signatureFile != null ? AppColors.primary : AppColors.border,
                              width: _signatureFile != null ? 1.5 : 1.0,
                            ),
                          ),
                          child: _signatureFile != null
                              ? Stack(
                                  children: [
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Image.file(_signatureFile!, fit: BoxFit.contain),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: IconButton(
                                        icon: const Icon(Icons.cancel_rounded, color: AppColors.error, size: 22),
                                        onPressed: () => setState(() => _signatureFile = null),
                                        tooltip: 'Remove',
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.draw_rounded, color: AppColors.primary, size: 24),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Tap to Draw Digital Sign or Upload Photo',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (_signatureFile != null) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _pickSignature,
                            icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                            label: const Text('Change Signature', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                          ),
                        ),
                      ],
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