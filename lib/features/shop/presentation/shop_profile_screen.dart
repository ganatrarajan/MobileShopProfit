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
import '../../auth/presentation/otp_verification_screen.dart';
import '../../../core/widgets/confirm_phone_dialog.dart';

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
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _logoUrl;
  File? _newLogoFile;
  String? _signatureUrl;
  File? _newSignatureFile;
  String? _message;
  String _initialMobile = '';

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
        _initialMobile = (shop['mobile'] ?? shop['phone'] ?? '').toString();
        _mobileController.text = _initialMobile;
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
      if (mounted) setState(() => _message = 'Failed to load shop: ');
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

    void _showErrorAndScrollToTop(String title, String errorMessage) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isSaving = false;
      _message = errorMessage;
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    if (mounted) {
      AppFeedback.showError(
        context,
        title: title,
        error: errorMessage,
      );
    }
  }

  Future<void> _handleUpdateShop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _message = null;
    });

    final newMobile = _mobileController.text.trim();
    final isMobileChanged = _initialMobile.isNotEmpty && newMobile != _initialMobile;

    try {
      if (isMobileChanged) {
        final confirmed = await showConfirmPhoneDialog(
          context: context,
          mobileNumber: newMobile,
          title: 'Confirm Mobile Update',
          message: 'An SMS OTP code will be sent to verify your new mobile number:',
        );
        if (confirmed != true) {
          setState(() => _isSaving = false);
          return;
        }
        // Send MSG91 OTP for Mobile Update
        final otpSendRes = await _authRepository.sendProfileOtp(
          name: _ownerController.text.trim(),
          mobile: newMobile,
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        );

        if (!otpSendRes.success || otpSendRes.data == null) {
          if (mounted) {
            setState(() {
              _isSaving = false;
              _message = otpSendRes.message.isNotEmpty ? otpSendRes.message : 'Failed to send OTP for mobile update.';
            });
          }
          return;
        }

        final data = otpSendRes.data is Map ? otpSendRes.data['data'] ?? otpSendRes.data : {};
        final verificationId = data['verification_id']?.toString() ?? '';

        if (verificationId.isEmpty) {
          if (mounted) {
            setState(() {
              _isSaving = false;
              _message = 'Invalid verification session response.';
            });
          }
          return;
        }

        setState(() => _isSaving = false);

        // Open OTP Verification Screen
        final dynamic verified = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              verificationId: verificationId,
              mobile: newMobile,
              cooldownSeconds: data['cooldown_seconds'] ?? 60,
              isProfileUpdate: true,
            ),
          ),
        );

        if (verified != true) {
          // Verification failed or user backed out
          return;
        }

        setState(() {
          _isSaving = true;
          _initialMobile = newMobile;
        });
      }

      // Update remaining shop details
      final response = await _authRepository.updateShop(
        name: _nameController.text.trim(),
        ownerName: _ownerController.text.trim(),
        mobile: newMobile,
        phone: newMobile,
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
            message: 'Shop profile and details saved successfully!',
          );
        } else {
          _showErrorAndScrollToTop('Update Failed', response.message ?? 'Failed to update shop details.');
        }
      }
    } catch (e) {
      _showErrorAndScrollToTop('Update Failed', e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                  controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_message != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error.withOpacity(0.3)),
                          ),
                          child: Text(
                            _message!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      CustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Branding & Media', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: _newLogoFile != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.file(_newLogoFile!, fit: BoxFit.cover),
                                            )
                                          : (_logoUrl != null && _logoUrl!.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: _logoUrl!.startsWith('http')
                                                      ? Image.network(_logoUrl!, fit: BoxFit.cover)
                                                      : Image.file(File(_logoUrl!), fit: BoxFit.cover),
                                                )
                                              : const Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.storefront_rounded, size: 30, color: AppColors.textMuted),
                                                    SizedBox(height: 4),
                                                    Text('No Logo', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                                  ],
                                                )),
                                    ),
                                    const SizedBox(height: 6),
                                    TextButton.icon(
                                      onPressed: _pickAndUploadLogo,
                                      icon: const Icon(Icons.photo_camera_rounded, size: 15, color: AppColors.primary),
                                      label: const Text('Shop Logo', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.border),
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
                            const SizedBox(height: 8),
                            const MobileHelperBanner(
                              message: 'SMS OTP verification will be sent if you update your mobile number.',
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
            ),
    );
  }
}

