import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/data/auth_repository.dart';

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

  final _authRepository = AuthRepository();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _logoUrl;
  File? _newLogoFile;
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
            setState(() {
              _logoUrl = response.data['logo_url'];
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Shop logo uploaded successfully')),
            );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick logo: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shop profile updated successfully')),
          );
        } else {
          setState(() => _message = response.message);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
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

                    // Shop Logo Header
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickAndUploadLogo,
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: AppColors.primaryLight,
                              backgroundImage: _newLogoFile != null
                                  ? FileImage(_newLogoFile!)
                                  : (_logoUrl != null ? NetworkImage(_logoUrl!) as ImageProvider : null),
                              child: (_newLogoFile == null && _logoUrl == null)
                                  ? const Icon(Icons.storefront_rounded, size: 40, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _pickAndUploadLogo,
                            icon: const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.accent),
                            label: const Text('Change Shop Logo', style: TextStyle(color: AppColors.accent, fontSize: 13)),
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
                            label: 'Shop Name *',
                            controller: _nameController,
                            prefixIcon: Icons.storefront_rounded,
                            validator: (val) => (val == null || val.isEmpty) ? 'Enter shop name' : null,
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Owner Name *',
                            controller: _ownerController,
                            prefixIcon: Icons.person_outline_rounded,
                            validator: (val) => (val == null || val.isEmpty) ? 'Enter owner name' : null,
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Mobile Number *',
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
                            label: 'Address *',
                            controller: _addressController,
                            prefixIcon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  label: 'City *',
                                  controller: _cityController,
                                  prefixIcon: Icons.location_city_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomTextField(
                                  label: 'State *',
                                  controller: _stateController,
                                  prefixIcon: Icons.map_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: 'Pincode *',
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