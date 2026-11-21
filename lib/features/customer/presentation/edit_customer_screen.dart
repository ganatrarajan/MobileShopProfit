import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/digital_signature_pad_dialog.dart';
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
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _errorMessage;
  File? _signatureFile;
  String? _existingSignatureUrl;
  bool _isSignatureCleared = false;

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
    final bool hasSig = _signatureFile != null || (_existingSignatureUrl != null && _existingSignatureUrl!.isNotEmpty);
    await SignaturePickerHelper.showOptions(
      context: context,
      title: 'Customer Signature (Optional)',
      hasExistingSignature: hasSig,
      onSignaturePicked: (File file) {
        setState(() {
          _signatureFile = file;
          _isSignatureCleared = false;
        });
      },
      onSignatureCleared: () {
        setState(() {
          _signatureFile = null;
          _existingSignatureUrl = null;
          _isSignatureCleared = true;
        });
      },
    );
  }

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
    _existingSignatureUrl = widget.customer.signatureUrl ?? widget.customer.signaturePath;
  }

  Future<void> _handleUpdateCustomer() async {
    if (!_formKey.currentState!.validate()) {
      _showFormError('Please check the highlighted errors in the form.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? sigParam;
      if (_signatureFile != null) {
        sigParam = _signatureFile!.path;
      } else if (_isSignatureCleared) {
        sigParam = '';
      }

      final response = await _repository.updateCustomer(
        id: widget.customer.id,
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        alternateMobile: _alternateMobileController.text.trim().isNotEmpty ? _alternateMobileController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        signature: sigParam,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          final updatedCustomer = Customer.fromJson(response.data);
          AppFeedback.showSuccess(
            context,
            title: '✅ Customer Updated',
            message: 'Customer details updated successfully.',
          );
          Navigator.pop(context, updatedCustomer);
        } else {
          _showFormError(response.message);
        }
      }
    } catch (e) {
      if (mounted) {
        _showFormError(e.toString());
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
        title: const Text('Edit Customer'),
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
                              color: (_signatureFile != null || (_existingSignatureUrl != null && _existingSignatureUrl!.isNotEmpty))
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: (_signatureFile != null || (_existingSignatureUrl != null && _existingSignatureUrl!.isNotEmpty))
                                  ? 1.5
                                  : 1.0,
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
                                        onPressed: () {
                                          setState(() {
                                            _signatureFile = null;
                                            _existingSignatureUrl = null;
                                            _isSignatureCleared = true;
                                          });
                                        },
                                        tooltip: 'Remove',
                                      ),
                                    ),
                                  ],
                                )
                              : (_existingSignatureUrl != null && _existingSignatureUrl!.isNotEmpty
                                  ? Stack(
                                      children: [
                                        Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: _existingSignatureUrl!.startsWith('http')
                                                ? Image.network(_existingSignatureUrl!, fit: BoxFit.contain)
                                                : Image.file(File(_existingSignatureUrl!), fit: BoxFit.contain),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: IconButton(
                                            icon: const Icon(Icons.cancel_rounded, color: AppColors.error, size: 22),
                                            onPressed: () {
                                              setState(() {
                                                _signatureFile = null;
                                                _existingSignatureUrl = null;
                                                _isSignatureCleared = true;
                                              });
                                            },
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
                                    )),
                        ),
                      ),
                      if (_signatureFile != null || (_existingSignatureUrl != null && _existingSignatureUrl!.isNotEmpty)) ...[
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