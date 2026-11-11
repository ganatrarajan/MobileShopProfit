import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/date_helper.dart';
import '../../../../core/widgets/app_searchable_bottom_sheet.dart';
import '../../../../core/widgets/barcode_scanner_screen.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../device/data/device_repository.dart';
import '../data/used_mobile_repository.dart';
import '../models/used_mobile.dart';

class BuyUsedMobileScreen extends StatefulWidget {
  final UsedMobile? mobileToEdit;

  const BuyUsedMobileScreen({super.key, this.mobileToEdit});

  @override
  State<BuyUsedMobileScreen> createState() => _BuyUsedMobileScreenState();
}

class _BuyUsedMobileScreenState extends State<BuyUsedMobileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UsedMobileRepository _repo = UsedMobileRepository();
  final DeviceRepository _deviceRepo = DeviceRepository();
  final ImagePicker _picker = ImagePicker();

  // Seller Details
  late final TextEditingController _sellerNameController;
  late final TextEditingController _sellerPhoneController;
  late final TextEditingController _sellerAddressController;
  late final TextEditingController _idProofNumberController;
  String _idProofType = 'Aadhaar Card';

  // ID Proof Photos (Front is Required, Back is Optional)
  File? _idProofFrontFile;
  String? _idProofFrontUrl;
  File? _idProofBackFile;
  String? _idProofBackUrl;

  // Device Specifications
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _imei1Controller;
  late final TextEditingController _imei2Controller;
  late final TextEditingController _serialController;
  late final TextEditingController _ramController;
  late final TextEditingController _storageController;
  late final TextEditingController _colorController;
  late final TextEditingController _batteryHealthController;

  // Catalog Auto-Data
  List<String> _catalogBrands = [];
  List<String> _catalogModels = [];
  bool _isLoadingBrands = false;
  bool _isLoadingModels = false;
  bool _isManualBrandModel = false;

  // Condition & Accessories
  String _deviceCondition = 'good';
  late final TextEditingController _conditionNotesController;
  final Set<String> _selectedAccessories = {};
  late final TextEditingController _otherAccessoriesController;

  // Financials
  late final TextEditingController _purchasePriceController;
  String _paymentMode = 'Cash';
  DateTime _purchaseDate = DateTime.now();
  late final TextEditingController _purchaseNotesController;

  bool _isLoading = false;
  bool _isScanning = false;

  Future<void> _scanBoxTogether() async {
    if (_isScanning) return;
    _isScanning = true;
    try {
      final result = await BarcodeScannerScreen.scanBox(
        context,
        title: 'Auto-Scan Box / Phone',
        instruction: 'Point at box sticker or *#06# screen to capture both IMEIs',
      );
      if (result != null && mounted) {
        setState(() {
          if (result.imei1 != null && ScannedBoxResult.isValidImei(result.imei1)) {
            _imei1Controller.text = result.imei1!;
          }
          if (result.imei2 != null && ScannedBoxResult.isValidImei(result.imei2)) {
            _imei2Controller.text = result.imei2!;
          }
          if (result.serialNumber != null && result.serialNumber!.isNotEmpty) {
            _serialController.text = result.serialNumber!;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Both IMEIs and Serial populated from 1 scan!'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } finally {
      _isScanning = false;
    }
  }

  final List<String> _idProofTypes = [
    'Aadhaar Card',
    'PAN Card',
    'Driving License',
    'Voter ID',
    'Passport',
    'Other ID',
  ];

  final List<String> _ramOptions = [
    '2 GB',
    '3 GB',
    '4 GB',
    '6 GB',
    '8 GB',
    '12 GB',
    '16 GB',
    '24 GB',
  ];

  final List<String> _storageOptions = [
    '32 GB',
    '64 GB',
    '128 GB',
    '256 GB',
    '512 GB',
    '1 TB',
  ];

  final List<String> _accessoryOptions = [
    'Original Box',
    'Original Charger',
    'Charging Cable',
    'Original Bill / Invoice',
    'Earphones',
    'Back Cover / Case',
  ];

  final List<String> _paymentModes = [
    'Cash',
    'UPI / GPay / PhonePe',
    'Bank Transfer',
    'Cheque',
  ];

  bool get _isEdit => widget.mobileToEdit != null;

  @override
  void initState() {
    super.initState();

    if (widget.mobileToEdit?.isSold == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppFeedback.showError(
            context,
            title: 'Editing Locked',
            message: 'Sold devices cannot be edited to preserve sales invoice records.',
          );
          Navigator.pop(context);
        }
      });
      return;
    }

    final m = widget.mobileToEdit;

    _sellerNameController = TextEditingController(text: m?.sellerName ?? '');
    _sellerPhoneController = TextEditingController(text: m?.sellerPhone ?? '');
    _sellerAddressController = TextEditingController(text: m?.sellerAddress ?? '');
    _idProofNumberController = TextEditingController(text: m?.idProofNumber ?? '');
    _idProofType = m?.idProofType ?? 'Aadhaar Card';
    _idProofFrontUrl = m?.idProofImagePath;
    _idProofBackUrl = m?.idProofBackImagePath;

    _brandController = TextEditingController(text: m?.brand ?? '');
    _modelController = TextEditingController(text: m?.model ?? '');
    _imei1Controller = TextEditingController(text: m?.imei1 ?? '');
    _imei2Controller = TextEditingController(text: m?.imei2 ?? '');
    _serialController = TextEditingController(text: m?.serialNumber ?? '');
    _ramController = TextEditingController(text: m?.ram ?? '');
    _storageController = TextEditingController(text: m?.storage ?? '');
    _colorController = TextEditingController(text: m?.color ?? '');
    _batteryHealthController = TextEditingController(text: m?.batteryHealth ?? '');

    _deviceCondition = m?.deviceCondition ?? 'good';
    _conditionNotesController = TextEditingController(text: m?.conditionNotes ?? '');

    // Partition accessories into standard chips vs custom other text
    final otherList = <String>[];
    if (m?.accessoriesIncluded != null) {
      for (final acc in m!.accessoriesIncluded) {
        if (_accessoryOptions.contains(acc)) {
          _selectedAccessories.add(acc);
        } else {
          otherList.add(acc);
        }
      }
    }
    _otherAccessoriesController = TextEditingController(text: otherList.join(', '));

    _purchasePriceController = TextEditingController(
      text: m != null ? m.purchasePrice.toStringAsFixed(0) : '',
    );
    _paymentMode = m?.paymentMode ?? 'Cash';
    _purchaseDate = m?.purchaseDate ?? DateTime.now();
    _purchaseNotesController = TextEditingController(text: m?.purchaseNotes ?? '');

    _fetchBrandsCatalog();
    if (_brandController.text.trim().isNotEmpty) {
      _fetchModelsCatalog(_brandController.text.trim());
    }
  }

  @override
  void dispose() {
    _sellerNameController.dispose();
    _sellerPhoneController.dispose();
    _sellerAddressController.dispose();
    _idProofNumberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _imei1Controller.dispose();
    _imei2Controller.dispose();
    _serialController.dispose();
    _ramController.dispose();
    _storageController.dispose();
    _colorController.dispose();
    _batteryHealthController.dispose();
    _conditionNotesController.dispose();
    _otherAccessoriesController.dispose();
    _purchasePriceController.dispose();
    _purchaseNotesController.dispose();
    super.dispose();
  }

  Future<void> _fetchBrandsCatalog() async {
    setState(() => _isLoadingBrands = true);
    final response = await _deviceRepo.getDeviceBrands();
    if (mounted) {
      setState(() {
        _isLoadingBrands = false;
        if (response.success && response.data != null && response.data!.isNotEmpty) {
          _catalogBrands = response.data!;
        } else {
          _catalogBrands = [
            'Apple',
            'Samsung',
            'OnePlus',
            'Vivo',
            'Oppo',
            'Realme',
            'Xiaomi',
            'Poco',
            'Motorola',
            'Google',
            'IQOO',
            'Nothing',
          ];
        }
      });
    }
  }

  Future<void> _fetchModelsCatalog(String brand) async {
    setState(() {
      _isLoadingModels = true;
      _catalogModels = [];
    });
    final response = await _deviceRepo.getDeviceModels(brand);
    if (mounted) {
      setState(() {
        _isLoadingModels = false;
        if (response.success && response.data != null) {
          _catalogModels = response.data!;
        }
      });
    }
  }

  // --- Document Photo Picker (Front & Back) ---
  Future<void> _showPhotoPickerSheet({required bool isFront}) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFront ? 'Attach Front Side of Document (Optional)' : 'Attach Back Side of Document (Optional)',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  isFront ? 'Photo showing name & photo on Aadhaar / PAN' : 'Photo showing address side of Aadhaar / ID',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Capture document clearly using camera'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickImage(ImageSource.camera, isFront: isFront);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.accent),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Select existing photo of ID proof'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickImage(ImageSource.gallery, isFront: isFront);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source, {required bool isFront}) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          if (isFront) {
            _idProofFrontFile = File(picked.path);
          } else {
            _idProofBackFile = File(picked.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, message: 'Failed to pick image: $e');
      }
    }
  }

  // --- Bottom Sheet Selection Handlers ---
  Future<void> _selectIdProofType() async {
    final selected = await AppSearchableBottomSheet.show(
      context,
      title: 'Select ID Proof Type',
      options: _idProofTypes,
      selectedValues: [_idProofType],
      searchHint: 'Search ID proof...',
      addCustomHint: '+ Add Other Document Type',
    );
    if (selected != null && selected is String && selected.isNotEmpty) {
      setState(() => _idProofType = selected);
    }
  }

  Future<void> _selectBrand() async {
    final selected = await AppSearchableBottomSheet.show(
      context,
      title: 'Select Mobile Brand',
      options: _catalogBrands,
      selectedValues: _brandController.text.isNotEmpty ? [_brandController.text] : [],
      searchHint: 'Search mobile brand...',
      addCustomHint: '+ Add Custom Brand',
      onAddCustomOption: (custom) async {
        if (!_catalogBrands.contains(custom)) {
          setState(() => _catalogBrands.insert(0, custom));
        }
      },
    );
    if (selected != null && selected is String && selected.isNotEmpty) {
      setState(() {
        _brandController.text = selected;
        _modelController.clear();
      });
      _fetchModelsCatalog(selected);
    }
  }

  Future<void> _selectModel() async {
    if (_brandController.text.trim().isEmpty) {
      AppFeedback.showError(
        context,
        title: 'Brand Required',
        message: 'Please select Brand first to view its models.',
      );
      return;
    }

    final selected = await AppSearchableBottomSheet.show(
      context,
      title: 'Select ${_brandController.text.trim()} Model',
      options: _catalogModels.isNotEmpty ? _catalogModels : ['Standard Model'],
      selectedValues: _modelController.text.isNotEmpty ? [_modelController.text] : [],
      searchHint: 'Search model name...',
      addCustomHint: '+ Add Custom Model',
      onAddCustomOption: (custom) async {
        if (!_catalogModels.contains(custom)) {
          setState(() => _catalogModels.insert(0, custom));
        }
      },
    );
    if (selected != null && selected is String && selected.isNotEmpty) {
      setState(() => _modelController.text = selected);
    }
  }

  Future<void> _selectRam() async {
    final selected = await AppSearchableBottomSheet.show(
      context,
      title: 'Select RAM',
      options: _ramOptions,
      selectedValues: _ramController.text.isNotEmpty ? [_ramController.text] : [],
      searchHint: 'Search RAM...',
      addCustomHint: '+ Enter Custom RAM (e.g. 18 GB)',
      onAddCustomOption: (custom) async {
        if (!_ramOptions.contains(custom)) {
          setState(() => _ramOptions.insert(0, custom));
        }
      },
    );
    if (selected != null && selected is String && selected.isNotEmpty) {
      setState(() => _ramController.text = selected);
    }
  }

  Future<void> _selectStorage() async {
    final selected = await AppSearchableBottomSheet.show(
      context,
      title: 'Select Storage',
      options: _storageOptions,
      selectedValues: _storageController.text.isNotEmpty ? [_storageController.text] : [],
      searchHint: 'Search Storage...',
      addCustomHint: '+ Enter Custom Storage (e.g. 2 TB)',
      onAddCustomOption: (custom) async {
        if (!_storageOptions.contains(custom)) {
          setState(() => _storageOptions.insert(0, custom));
        }
      },
    );
    if (selected != null && selected is String && selected.isNotEmpty) {
      setState(() => _storageController.text = selected);
    }
  }

  Future<void> _selectPaymentMode() async {
    final selected = await AppSearchableBottomSheet.show(
      context,
      title: 'Select Payment Mode',
      options: _paymentModes,
      selectedValues: [_paymentMode],
      searchHint: 'Search payment mode...',
    );
    if (selected != null && selected is String && selected.isNotEmpty) {
      setState(() => _paymentMode = selected);
    }
  }

  Future<void> _saveEntry() async {
    // Trigger inline validation errors on form fields
    _formKey.currentState?.validate();

    // 1. Seller Name
    final sellerName = _sellerNameController.text.trim();
    if (sellerName.isEmpty) {
      AppFeedback.showError(
        context,
        title: 'Seller Name Required',
        message: 'Please enter the seller / original owner name *.',
      );
      return;
    }

    // 2. Seller Mobile
    final sellerPhone = _sellerPhoneController.text.trim();
    final cleanPhone = sellerPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) {
      AppFeedback.showError(
        context,
        title: 'Mobile Number Required',
        message: 'Please enter seller 10-digit mobile number *.',
      );
      return;
    }
    if (cleanPhone.length < 10) {
      AppFeedback.showError(
        context,
        title: 'Invalid Mobile Number',
        message: 'Seller mobile number must be 10 digits (currently ${cleanPhone.length} digits).',
      );
      return;
    }

    // 3. ID Proof (Optional)
    final idNumber = _idProofNumberController.text.trim();

    // 4. Brand
    final brand = _brandController.text.trim();
    if (brand.isEmpty) {
      AppFeedback.showError(
        context,
        title: 'Brand Required',
        message: 'Please select or enter the device brand *.',
      );
      return;
    }

    // 5. Model
    final model = _modelController.text.trim();
    if (model.isEmpty) {
      AppFeedback.showError(
        context,
        title: 'Model Required',
        message: 'Please select or enter the device model *.',
      );
      return;
    }

    // 6. Primary IMEI 1 (Optional)
    final imei1 = _imei1Controller.text.trim();

    // 7. Purchase Price
    final purchasePriceText = _purchasePriceController.text.trim();
    if (purchasePriceText.isEmpty) {
      AppFeedback.showError(
        context,
        title: 'Purchase Price Required',
        message: 'Please enter the purchase amount paid to seller *.',
      );
      return;
    }
    final purchasePrice = double.tryParse(purchasePriceText) ?? 0.0;
    if (purchasePrice <= 0) {
      AppFeedback.showError(
        context,
        title: 'Invalid Purchase Price',
        message: 'Purchase price must be greater than ₹0.',
      );
      return;
    }

    setState(() => _isLoading = true);

    // Combine accessory chips + custom other accessories text
    final finalAccessories = Set<String>.from(_selectedAccessories);
    final otherAcc = _otherAccessoriesController.text.trim();
    if (otherAcc.isNotEmpty) {
      final customItems = otherAcc.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
      finalAccessories.addAll(customItems);
    }

    // Convert photos to base64 if newly picked
    String? idProofFrontPayload = _idProofFrontUrl;
    if (_idProofFrontFile != null) {
      final bytes = await _idProofFrontFile!.readAsBytes();
      idProofFrontPayload = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }

    String? idProofBackPayload = _idProofBackUrl;
    if (_idProofBackFile != null) {
      final bytes = await _idProofBackFile!.readAsBytes();
      idProofBackPayload = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }

    final payload = <String, dynamic>{
      'seller_name': _sellerNameController.text.trim(),
      'seller_phone': sellerPhone,
      if (_sellerAddressController.text.trim().isNotEmpty)
        'seller_address': _sellerAddressController.text.trim(),
      'id_proof_type': _idProofType,
      'id_proof_number': idNumber.isNotEmpty ? idNumber : null,
      if (idProofFrontPayload != null)
        'id_proof_photo': idProofFrontPayload,
      if (idProofBackPayload != null)
        'id_proof_back_photo': idProofBackPayload,

      'brand': _brandController.text.trim(),
      'model': _modelController.text.trim(),
      'imei1': imei1.isNotEmpty ? imei1 : null,
      if (_imei2Controller.text.trim().isNotEmpty)
        'imei2': _imei2Controller.text.trim(),
      if (_serialController.text.trim().isNotEmpty)
        'serial_number': _serialController.text.trim(),
      if (_ramController.text.trim().isNotEmpty)
        'ram': _ramController.text.trim(),
      if (_storageController.text.trim().isNotEmpty)
        'storage': _storageController.text.trim(),
      if (_colorController.text.trim().isNotEmpty)
        'color': _colorController.text.trim(),
      if (_batteryHealthController.text.trim().isNotEmpty)
        'battery_health': _batteryHealthController.text.trim(),

      'device_condition': _deviceCondition,
      if (_conditionNotesController.text.trim().isNotEmpty)
        'condition_notes': _conditionNotesController.text.trim(),
      'accessories_included': finalAccessories.toList(),

      'purchase_price': purchasePrice,
      'payment_mode': _paymentMode,
      'purchase_date': _purchaseDate.toIso8601String().split('T').first,
      if (_purchaseNotesController.text.trim().isNotEmpty)
        'purchase_notes': _purchaseNotesController.text.trim(),
    };

    if (_isEdit) {
      final res = await _repo.updateUsedMobile(widget.mobileToEdit!.id, payload);
      setState(() => _isLoading = false);

      if (res.success && res.data != null) {
        if (!mounted) return;
        Navigator.pop(context, res.data);
        AppFeedback.showSuccess(
          context,
          title: 'Mobile Updated',
          message: '${res.data!.deviceDisplayName} details updated successfully.',
        );
      } else {
        if (!mounted) return;
        AppFeedback.showError(
          context,
          title: 'Update Failed',
          message: res.message.isNotEmpty ? res.message : 'Failed to update details.',
        );
      }
    } else {
      final res = await _repo.buyUsedMobile(payload);
      setState(() => _isLoading = false);

      if (res.success && res.data != null) {
        if (!mounted) return;
        final created = res.data!;
        Navigator.pop(context, true);
        AppFeedback.showSuccess(
          context,
          title: 'Purchase Recorded',
          message: '${created.deviceDisplayName} (#${created.purchaseRefNumber}) saved to inventory.',
        );
      } else {
        if (!mounted) return;
        AppFeedback.showError(
          context,
          title: 'Purchase Failed',
          message: res.message.isNotEmpty ? res.message : 'Failed to save purchase. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Used Mobile Details' : 'Buy Old Mobile (Second-Hand)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section 1: Seller Verification
              _buildSectionHeader('1. Seller Information & Verification', Icons.person_pin_rounded, AppColors.primary),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _sellerNameController,
                      label: 'Seller Full Name *',
                      hint: 'Customer selling the phone',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter seller name' : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _sellerPhoneController,
                      label: 'Seller Mobile Number *',
                      hint: '10-digit mobile number',
                      prefixIcon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter mobile number' : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _sellerAddressController,
                      label: 'Seller Address / City (Optional)',
                      hint: 'Area or Residential address',
                      prefixIcon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 12),

                    // ID Proof Type (Tap to open Bottom Sheet) & ID Number (Optional)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildSelectField(
                            label: 'ID Proof Type',
                            value: _idProofType,
                            hint: 'Select ID',
                            prefixIcon: Icons.credit_card_rounded,
                            onTap: _selectIdProofType,
                            isRequired: false,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 6,
                          child: CustomTextField(
                            controller: _idProofNumberController,
                            label: 'ID / Aadhaar No. (Optional)',
                            hint: 'Full or Last 4 ID digits',
                            prefixIcon: Icons.badge_outlined,
                            isRequired: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Front & Back Document Photo Upload Cards (Front Required *, Back Optional)
                    _buildDocumentUploadSection(isDark),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 2: Device Specs & IMEI
              _buildSectionHeader('2. Device Specifications & IMEI', Icons.phone_android_rounded, Colors.indigo),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Brand & Model Selection',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            setState(() => _isManualBrandModel = !_isManualBrandModel);
                          },
                          child: Row(
                            children: [
                              Icon(
                                _isManualBrandModel ? Icons.list_alt_rounded : Icons.edit_note_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isManualBrandModel ? 'Select from List' : 'Enter Manually',
                                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (!_isManualBrandModel) ...[
                      // Brand Selector (Opens Searchable Bottom Sheet with devices.json catalog)
                      _buildSelectField(
                        label: 'Device Brand',
                        value: _brandController.text,
                        hint: 'Tap to select Brand (e.g. Apple, Samsung, Vivo)',
                        prefixIcon: Icons.business_rounded,
                        isLoading: _isLoadingBrands,
                        onTap: _selectBrand,
                        isRequired: true,
                      ),
                      const SizedBox(height: 12),

                      // Model Selector (Opens Searchable Bottom Sheet with models for selected brand)
                      _buildSelectField(
                        label: 'Device Model',
                        value: _modelController.text,
                        hint: _brandController.text.isEmpty
                            ? 'Select Brand first'
                            : 'Tap to select ${_brandController.text} model',
                        prefixIcon: Icons.devices_other_rounded,
                        isLoading: _isLoadingModels,
                        onTap: _selectModel,
                        isRequired: true,
                      ),
                    ] else ...[
                      CustomTextField(
                        controller: _brandController,
                        label: 'Brand Name',
                        hint: 'e.g. Apple, Samsung, OnePlus',
                        prefixIcon: Icons.business_rounded,
                        isRequired: true,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter brand' : null,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _modelController,
                        label: 'Model Name / Number',
                        hint: 'e.g. iPhone 13 / Galaxy S21 / Note 10 Pro',
                        prefixIcon: Icons.devices_other_rounded,
                        isRequired: true,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter model' : null,
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Auto-scan box / phone shortcut
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Device IMEI Identifiers',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _scanBoxTogether,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF10B981)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.qr_code_scanner_rounded, size: 13, color: Color(0xFF10B981)),
                                SizedBox(width: 4),
                                Text(
                                  '⚡ Auto-Scan Box',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Primary IMEI 1 (Optional)
                    CustomTextField(
                      controller: _imei1Controller,
                      label: 'Primary IMEI 1 (Optional)',
                      hint: 'Dial *#06# on phone or tap scanner',
                      prefixIcon: Icons.qr_code_2_rounded,
                      keyboardType: TextInputType.text,
                      isRequired: false,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                        tooltip: 'Scan Box / Phone with camera',
                        onPressed: _scanBoxTogether,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Secondary IMEI 2 (Full Width)
                    CustomTextField(
                      controller: _imei2Controller,
                      label: 'Secondary IMEI 2 (Optional)',
                      hint: 'Secondary 15-digit IMEI',
                      prefixIcon: Icons.qr_code_rounded,
                      keyboardType: TextInputType.number,
                      isRequired: false,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                        tooltip: 'Scan Box / Phone with camera',
                        onPressed: _scanBoxTogether,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Serial Number (Full Width)
                    CustomTextField(
                      controller: _serialController,
                      label: 'Serial No. (Optional)',
                      hint: 'Manufacturer Serial #',
                      prefixIcon: Icons.tag_rounded,
                      isRequired: false,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                        tooltip: 'Scan Serial # with camera',
                        onPressed: _scanBoxTogether,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // RAM & Storage (2 spacious columns)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildSelectField(
                            label: 'RAM',
                            value: _ramController.text,
                            hint: 'Select RAM',
                            prefixIcon: Icons.memory_rounded,
                            onTap: _selectRam,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSelectField(
                            label: 'Storage',
                            value: _storageController.text,
                            hint: 'Select Storage',
                            prefixIcon: Icons.sd_storage_rounded,
                            onTap: _selectStorage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Color & Battery Health (2 spacious columns)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _colorController,
                            label: 'Color (Optional)',
                            hint: 'e.g. Black / Blue',
                            prefixIcon: Icons.palette_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextField(
                            controller: _batteryHealthController,
                            label: 'Battery (Optional)',
                            hint: 'e.g. 85% / Good',
                            prefixIcon: Icons.battery_charging_full_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 3: Condition & Accessories
              _buildSectionHeader('3. Device Condition & Accessories', Icons.fact_check_rounded, Colors.teal),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Physical Condition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _conditionChip('mint', 'Mint (Like New)', Colors.green),
                        _conditionChip('good', 'Good Condition', Colors.blue),
                        _conditionChip('fair', 'Fair (Minor Flaws)', Colors.orange),
                        _conditionChip('damaged', 'Damaged / For Parts', Colors.red),
                      ],
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _conditionNotesController,
                      label: 'Condition / Scratches / Fault Notes',
                      hint: 'e.g. Minor scratches on bezel, display 100% genuine',
                      prefixIcon: Icons.edit_note_rounded,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 14),
                    const Text('Accessories Included with Phone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _accessoryOptions.map((acc) {
                        final isChecked = _selectedAccessories.contains(acc);
                        return FilterChip(
                          label: Text(acc),
                          selected: isChecked,
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                _selectedAccessories.add(acc);
                              } else {
                                _selectedAccessories.remove(acc);
                              }
                            });
                          },
                          selectedColor: Colors.teal.shade100,
                          checkmarkColor: Colors.teal.shade800,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                            color: isChecked ? Colors.teal.shade900 : AppColors.textPrimary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Optional Other Accessories Text Field
                    CustomTextField(
                      controller: _otherAccessoriesController,
                      label: 'Other Accessories (Optional)',
                      hint: 'e.g. Stylus pen, Tempered glass, Extra case',
                      prefixIcon: Icons.add_box_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 4: Purchase Pricing & Payment
              _buildSectionHeader('4. Purchase Amount & Payment', Icons.payments_rounded, AppColors.accent),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _purchasePriceController,
                      label: 'Purchase Price Paid to Seller (₹) *',
                      hint: 'Amount paid to customer',
                      prefixIcon: Icons.currency_rupee_rounded,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter purchase price';
                        final n = double.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Enter valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Payment Mode (Tap opens Searchable Bottom Sheet)
                        Expanded(
                          child: _buildSelectField(
                            label: 'Payment Mode',
                            value: _paymentMode,
                            hint: 'Select mode',
                            prefixIcon: Icons.payment_rounded,
                            onTap: _selectPaymentMode,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: 'Purchase Date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    letterSpacing: 0.1,
                                    fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _purchaseDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) setState(() => _purchaseDate = picked);
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkBackground : AppColors.inputFill,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          DateHelper.formatDate(_purchaseDate.toIso8601String()),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textMuted, size: 22),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      controller: _purchaseNotesController,
                      label: 'Notes / Remarks (Optional)',
                      hint: 'e.g. Seller brought box without bill',
                      prefixIcon: Icons.notes_rounded,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Submit Button
              CustomButton(
                text: _isLoading
                    ? 'Saving...'
                    : (_isEdit ? 'Update Used Mobile' : 'Confirm Purchase & Add to Stock'),
                icon: _isEdit ? Icons.save_rounded : Icons.add_shopping_cart_rounded,
                isLoading: _isLoading,
                backgroundColor: AppColors.primary,
                onPressed: _isLoading ? null : _saveEntry,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectField({
    required String label,
    required String value,
    required String hint,
    required IconData prefixIcon,
    required VoidCallback onTap,
    bool isLoading = false,
    bool isRequired = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final hasValue = value.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: labelColor,
              letterSpacing: 0.1,
              fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
            ),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]
                : [],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.inputFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: Row(
              children: [
                Icon(prefixIcon, size: 18, color: hasValue ? AppColors.primary : AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: isLoading
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Text(
                          hasValue ? value : hint,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                            color: hasValue
                                ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                                : AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textMuted, size: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUploadSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Govt ID Document Proof',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Optional', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSinglePhotoCard(
                title: 'Front Side',
                subtitle: 'Photo & Name (Optional)',
                file: _idProofFrontFile,
                url: _idProofFrontUrl,
                isRequired: false,
                onTap: () => _showPhotoPickerSheet(isFront: true),
                onRemove: () => setState(() {
                  _idProofFrontFile = null;
                  _idProofFrontUrl = null;
                }),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSinglePhotoCard(
                title: 'Back Side',
                subtitle: 'Address (Optional)',
                file: _idProofBackFile,
                url: _idProofBackUrl,
                isRequired: false,
                onTap: () => _showPhotoPickerSheet(isFront: false),
                onRemove: () => setState(() {
                  _idProofBackFile = null;
                  _idProofBackUrl = null;
                }),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSinglePhotoCard({
    required String title,
    required String subtitle,
    required File? file,
    required String? url,
    required bool isRequired,
    required VoidCallback onTap,
    required VoidCallback onRemove,
    required bool isDark,
  }) {
    final hasLocal = file != null;
    final hasRemote = url != null && url.isNotEmpty;
    final hasPhoto = hasLocal || hasRemote;

    if (!hasPhoto) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : AppColors.inputFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRequired ? AppColors.primary.withOpacity(0.4) : Colors.grey.shade400,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_a_photo_rounded,
                size: 24,
                color: isRequired ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isRequired ? AppColors.primary : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isRequired)
                    const Text(' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: onRemove,
                child: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 70,
              width: double.infinity,
              child: hasLocal
                  ? Image.file(file, fit: BoxFit.cover)
                  : Image.network(
                      url!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey, size: 28),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 12, color: AppColors.accent),
                  SizedBox(width: 3),
                  Text('Attached', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent)),
                ],
              ),
              InkWell(
                onTap: onTap,
                child: const Text('Change', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _conditionChip(String value, String label, Color color) {
    final isSelected = _deviceCondition == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (sel) {
        if (sel) setState(() => _deviceCondition = value);
      },
      selectedColor: color.withOpacity(0.18),
      side: BorderSide(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? color : AppColors.textPrimary,
      ),
    );
  }
}
