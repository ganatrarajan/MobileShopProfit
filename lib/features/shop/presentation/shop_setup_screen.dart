import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/data/auth_repository.dart';

class ShopSetupScreen extends StatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> {
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
  final _authStorage = AuthStorage();
  final ImagePicker _picker = ImagePicker();

  File? _selectedLogoFile;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _prefillUserData();
  }

  Future<void> _prefillUserData() async {
    final user = await _authStorage.getUser();
    final shop = await _authStorage.getShop();

    if (mounted && user != null) {
      _ownerController.text = user['name'] ?? '';
      _mobileController.text = user['mobile'] ?? user['phone'] ?? '';
      _emailController.text = user['email'] ?? '';
    }

    if (mounted && shop != null) {
      if (shop['name'] != null) _nameController.text = shop['name'];
      if (shop['address'] != null) _addressController.text = shop['address'];
      if (shop['city'] != null) _cityController.text = shop['city'];
      if (shop['state'] != null) _stateController.text = shop['state'];
      if (shop['pincode'] != null) _pincodeController.text = shop['pincode'];
    }
  }

  Future<void> _pickLogoImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedLogoFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick logo image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleSaveShop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authRepository.createShop(
        name: _nameController.text.trim(),
        ownerName: _ownerController.text.trim(),
        mobile: _mobileController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : _mobileController.text.trim(),
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        gstNumber: _gstController.text.trim().isNotEmpty ? _gstController.text.trim() : null,
      );

      if (!mounted) return;

      if (response.success) {
        // Upload Logo if selected
        if (_selectedLogoFile != null) {
          await _authRepository.uploadShopLogo(_selectedLogoFile!.path);
        }

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (route) => false);
        }
      } else {
        setState(() {
          _errorMessage = response.message;
        });
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
        title: const Text('Complete Shop Setup'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set Up Your Mobile Shop Profile',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter your shop location and contact details for bills & job cards.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withOpacity(0.5)),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
                  const SizedBox(height: 20),
                ],

                // Logo Upload Avatar Box
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickLogoImage,
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: _selectedLogoFile != null ? FileImage(_selectedLogoFile!) : null,
                          child: _selectedLogoFile == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, color: Colors.white, size: 26),
                                    SizedBox(height: 4),
                                    Text('Shop Logo', style: TextStyle(color: Colors.white, fontSize: 10)),
                                  ],
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _pickLogoImage,
                        icon: const Icon(Icons.upload_rounded, size: 16, color: AppColors.accent),
                        label: const Text('Upload Shop Logo (Optional)', style: TextStyle(color: AppColors.accent, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Shop Information Card
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'General Shop Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Shop Name *',
                        hint: 'e.g. City Mobile Care',
                        controller: _nameController,
                        prefixIcon: Icons.storefront_rounded,
                        validator: (val) => (val == null || val.isEmpty) ? 'Enter shop name' : null,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Owner Full Name *',
                        hint: 'e.g. Rajan Kumar',
                        controller: _ownerController,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (val) => (val == null || val.isEmpty) ? 'Enter owner name' : null,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Mobile Number *',
                        hint: 'e.g. 9876543210',
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_android_rounded,
                        validator: (val) => (val == null || val.length < 10) ? 'Enter valid mobile' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Location Details Card
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location & Address',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Shop Address *',
                        hint: 'e.g. Shop No. 12, Main Market Road',
                        controller: _addressController,
                        prefixIcon: Icons.location_on_outlined,
                        validator: (val) => (val == null || val.isEmpty) ? 'Enter shop address' : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'City *',
                              hint: 'e.g. Ahmedabad',
                              controller: _cityController,
                              prefixIcon: Icons.location_city_outlined,
                              validator: (val) => (val == null || val.isEmpty) ? 'Enter city' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              label: 'State *',
                              hint: 'e.g. Gujarat',
                              controller: _stateController,
                              prefixIcon: Icons.map_outlined,
                              validator: (val) => (val == null || val.isEmpty) ? 'Enter state' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Pincode *',
                        hint: 'e.g. 380001',
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.pin_drop_outlined,
                        validator: (val) => (val == null || val.isEmpty) ? 'Enter pincode' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Optional Info Card
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tax & Additional Info (Optional)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'GST Number (Optional)',
                        hint: 'e.g. 24AAAAA0000A1Z5',
                        controller: _gstController,
                        prefixIcon: Icons.description_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                CustomButton(
                  text: 'Save Shop Profile & Continue',
                  isLoading: _isLoading,
                  onPressed: _handleSaveShop,
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