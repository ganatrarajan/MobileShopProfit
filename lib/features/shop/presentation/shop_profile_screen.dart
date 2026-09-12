import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/storage/auth_storage.dart';

class ShopProfileScreen extends StatefulWidget {
  const ShopProfileScreen({super.key});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _mobileController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _gstController = TextEditingController();
  final _termsController = TextEditingController();

  final _authRepository = AuthRepository();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _logoUrl;
  File? _newLogoFile;
  String? _signatureUrl;
  File? _newSignatureFile;
  String? _message;

  @override
  void initState() {
    super.initState();
    _fetchShopDetails();
  }

  Future<void> _fetchShopDetails() async {
    try {
      final response = await _authRepository.fetchShop();
      if (response.success && response.data != null) {
        final shop = response.data as Map<String, dynamic>;
        _nameController.text = shop['name'] ?? '';
        _ownerController.text = shop['owner_name'] ?? '';
        _mobileController.text = shop['mobile'] ?? shop['phone'] ?? '';
        _phoneController.text = shop['phone'] ?? '';
        _emailController.text = shop['email'] ?? '';
        _addressController.text = shop['address'] ?? '';
        _cityController.text = shop['city'] ?? '';
        _stateController.text = shop['state'] ?? '';
        _pincodeController.text = shop['pincode'] ?? '';
        _gstController.text = shop['gst_number'] ?? '';
        _logoUrl = shop['logo_url'];
        final localShop = await AuthStorage().getShop();
        final savedTerms = shop['terms_and_conditions'] ?? shop['terms'] ?? localShop?['terms_and_conditions'];
        _termsController.text = savedTerms ?? "1. Goods once sold will be covered strictly as per warranty terms.\n2. Physical damage, liquid exposure, or unauthorized tampering voids all warranty.\n3. Please present this bill for any warranty claims or queries.";
        if (localShop != null) {
          _signatureUrl = localShop['signature_path'] ?? localShop['signature_url'];
          if (_logoUrl == null || _logoUrl!.isEmpty) {
            _logoUrl = localShop['logo_path'] ?? localShop['logo_url'];
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _message = 'Failed to load shop: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadLogo() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _newLogoFile = File(image.path);
          _isSaving = true;
        });

        final response = await _authRepository.uploadShopLogo(image.path);
        if (mounted) {
          if (response.success && response.data != null) {
            final logoPath = response.data['logo_url'] ?? image.path;
            setState(() {
              _logoUrl = logoPath;
            });
            final shopData = await AuthStorage().getShop() ?? {};
            shopData['logo_path'] = image.path;
            shopData['logo_url'] = logoPath;
            await AuthStorage().saveSession(
              token: (await AuthStorage().getToken()) ?? '',
              user: (await AuthStorage().getUser()) ?? {},
              shop: shopData,
            );
            if (mounted) {
              AppFeedback.showSuccess(
                context,
                title: 'Shop Logo Updated',
                message: 'Shop logo uploaded and saved successfully!',
              );
            }
          }
        }
      }
    } on PlatformException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please restart the Flutter app (flutter run) to register the ImagePicker native plugin.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          title: 'Logo Upload Failed',
          error: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

    Future<void> _pickAndUploadSignature() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 400,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _newSignatureFile = File(image.path);
          _signatureUrl = image.path;
        });

        final shopData = await AuthStorage().getShop() ?? {};
        shopData['signature_path'] = image.path;
        shopData['signature_url'] = image.path;
        await AuthStorage().saveSession(
          token: (await AuthStorage().getToken()) ?? '',
          user: (await AuthStorage().getUser()) ?? {},
          shop: shopData,
        );

        if (mounted) {
          AppFeedback.showSuccess(
            context,
            title: 'Signature Saved',
            message: 'Shop signature image updated successfully!',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          title: 'Signature Selection Failed',
          error: e.toString(),
        );
      }
    }
  }

  Future<void> _handleUpdateShop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      final response = await _authRepository.updateShop(
        name: _nameController.text.trim(),
        ownerName: _ownerController.text.trim(),
        mobile: _mobileController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        gstNumber: _gstController.text.trim().isNotEmpty ? _gstController.text.trim() : null,
      );

      final shopData = await AuthStorage().getShop() ?? {};
      shopData['terms_and_conditions'] = _termsController.text.trim();
      await AuthStorage().saveSession(
        token: (await AuthStorage().getToken()) ?? '',
        user: (await AuthStorage().getUser()) ?? {},
        shop: shopData,
      );

      if (mounted) {
        if (response.success) {
          AppFeedback.showSuccess(
            context,
            title: 'Profile Updated',
            message: 'Shop details and invoice terms saved successfully!',
          );
        } else {
          AppFeedback.showError(
            context,
            title: 'Update Failed',
            error: response.message,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          title: 'Update Error',
          error: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _mobileController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _gstController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Shop Profile'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_message != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_message!, style: const TextStyle(color: AppColors.error)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Shop Logo & Signature Header Card
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Branding & Invoicing Assets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Shop Logo Uploader
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: _pickAndUploadLogo,
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundColor: AppColors.primaryLight,
                                      backgroundImage: _newLogoFile != null
                                          ? FileImage(_newLogoFile!)
                                          : (_logoUrl != null && _logoUrl!.isNotEmpty
                                              ? (_logoUrl!.startsWith('http')
                                                  ? NetworkImage(_logoUrl!) as ImageProvider
                                                  : FileImage(File(_logoUrl!)))
                                              : null),
                                      child: (_newLogoFile == null && (_logoUrl == null || _logoUrl!.isEmpty))
                                          ? const Icon(Icons.storefront_rounded, size: 36, color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextButton.icon(
                                    onPressed: _pickAndUploadLogo,
                                    icon: const Icon(Icons.camera_alt_outlined, size: 15, color: AppColors.accent),
                                    label: const Text('Shop Logo', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              Container(height: 80, width: 1, color: AppColors.border),
                              // Shop Signature Uploader
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: _pickAndUploadSignature,
                                    child: Container(
                                      width: 110,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.border, width: 1.2),
                                      ),
                                      child: _newSignatureFile != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(_newSignatureFile!, fit: BoxFit.contain),
                                            )
                                          : (_signatureUrl != null && _signatureUrl!.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: _signatureUrl!.startsWith('http')
                                                      ? Image.network(_signatureUrl!, fit: BoxFit.contain)
                                                      : Image.file(File(_signatureUrl!), fit: BoxFit.contain),
                                                )
                                              : const Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.draw_rounded, size: 26, color: AppColors.textMuted),
                                                    SizedBox(height: 2),
                                                    Text('Add Sign', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                                  ],
                                                )),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextButton.icon(
                                    onPressed: _pickAndUploadSignature,
                                    icon: const Icon(Icons.gesture_rounded, size: 15, color: AppColors.accent),
                                    label: const Text('Shop Signature', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('General Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Shop Name',
                            controller: _nameController,
                            prefixIcon: Icons.storefront_rounded,
                            
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Owner Name',
                            controller: _ownerController,
                            prefixIcon: Icons.person_outline_rounded,
                            
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Mobile Number',
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_android_rounded,
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Address & Tax', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Address',
                            controller: _addressController,
                            prefixIcon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  label: 'City',
                                  controller: _cityController,
                                  prefixIcon: Icons.location_city_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomTextField(
                                  label: 'State',
                                  controller: _stateController,
                                  prefixIcon: Icons.map_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Pincode',
                            controller: _pincodeController,
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.pin_drop_outlined,
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'GST Number',
                            controller: _gstController,
                            prefixIcon: Icons.description_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Invoice Terms & Conditions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          const Text('These custom terms will appear on your PDF invoice bills.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Invoice Terms (One per line)',
                            controller: _termsController,
                            maxLines: 4,
                            prefixIcon: Icons.gavel_rounded,
                            hint: "1. Goods once sold will be covered strictly as per warranty terms.\n2. Physical damage voids warranty.\n3. Present bill for claims.",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    CustomButton(
                      text: 'Save Changes',
                      isLoading: _isSaving,
                      onPressed: _handleUpdateShop,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}