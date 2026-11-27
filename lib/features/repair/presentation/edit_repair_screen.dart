import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/pattern_lock_widget.dart';
import '../../technician/data/technician_repository.dart';
import '../../technician/models/technician.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/repair_repository.dart';
import '../models/repair.dart';

class EditRepairScreen extends StatefulWidget {
  final Repair repair;
  const EditRepairScreen({super.key, required this.repair});

  @override
  State<EditRepairScreen> createState() => _EditRepairScreenState();
}

class _EditRepairScreenState extends State<EditRepairScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repairRepository = RepairRepository();
  final _technicianRepository = TechnicianRepository();
  final ScrollController _scrollController = ScrollController();
  Technician? _selectedTechnician;
  List<Technician> _technicianList = [];
  bool _isLoadingTechnicians = false;

  final ImagePicker _picker = ImagePicker();
  // Front Photo
  File? _newFrontPhotoFile;
  String? _existingFrontPhotoUrl;
  bool _frontPhotoRemoved = false;

  // Back Photo
  File? _newBackPhotoFile;
  String? _existingBackPhotoUrl;
  bool _backPhotoRemoved = false;

  // Customer Live Photo
  File? _newCustomerPhotoFile;
  String? _existingCustomerPhotoUrl;
  bool _customerPhotoRemoved = false;

  late TextEditingController _problemController;
  late TextEditingController _conditionNotesController;
  late TextEditingController _accessoriesNotesController;
  late TextEditingController _pinPasscodeController;
  late TextEditingController _estimatedCostController;
  late TextEditingController _finalCostController;
  late TextEditingController _technicianEarningController;
  late TextEditingController _labourCostController;
  late TextEditingController _customerNotesController;
  late TextEditingController _internalNotesController;

  DateTime? _expectedDeliveryDate;
  bool _obscurePin = true;
  bool _isPatternMode = false;
  List<int> _patternPoints = [];

  Future<void> _openPatternDialog() async {
    final result = await PatternLockDialog.show(context, initialPattern: _patternPoints);
    if (result != null && result.length >= 2) {
      setState(() {
        _isPatternMode = true;
        _patternPoints = result;
        _pinPasscodeController.text = PatternHelper.formatPattern(_patternPoints);
      });
    }
  }

  final List<String> _availableConditions = [
    'Screen damaged',
    'Body damaged',
    'Back glass damaged',
    'Camera damaged',
    'Water damage',
    'No visible damage',
    'Speaker issue',
    'Other',
  ];
  late Set<String> _selectedConditions;

  final List<String> _availableAccessories = [
    'Charger',
    'Cable',
    'SIM',
    'Memory Card',
    'Cover',
    'Box',
    'Other',
  ];
  late Set<String> _selectedAccessories;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initControllers(widget.repair);
    _loadTechnicians();
    _fetchLatestRepairDetails();
  }

  void _initControllers(Repair r) {
    _problemController = TextEditingController(text: r.problemDescription);
    _conditionNotesController = TextEditingController(text: r.conditionNotes);
    _accessoriesNotesController = TextEditingController(text: r.accessoriesNotes);
    _pinPasscodeController = TextEditingController(text: r.pinPasscode);
    _estimatedCostController = TextEditingController(text: r.estimatedCost > 0 ? r.estimatedCost.toStringAsFixed(2) : '');
    _finalCostController = TextEditingController(text: r.finalCost > 0 ? r.finalCost.toStringAsFixed(2) : '');
    _technicianEarningController = TextEditingController(text: r.technicianEarning > 0 ? r.technicianEarning.toStringAsFixed(2) : '');
    _labourCostController = TextEditingController(text: r.labourCost > 0 ? r.labourCost.toStringAsFixed(2) : '');
    _customerNotesController = TextEditingController(text: r.customerNotes);
    _internalNotesController = TextEditingController(text: r.internalNotes);

    _existingFrontPhotoUrl = r.devicePhoto;
    _newFrontPhotoFile = null;
    _frontPhotoRemoved = false;

    _existingBackPhotoUrl = r.devicePhotoBack;
    _newBackPhotoFile = null;
    _backPhotoRemoved = false;

    _existingCustomerPhotoUrl = r.customerPhoto;
    _newCustomerPhotoFile = null;
    _customerPhotoRemoved = false;

    _selectedConditions = Set.from(r.deviceCondition);
    _selectedAccessories = Set.from(r.accessoriesReceived);

    if (r.pinPasscode != null && PatternHelper.isPattern(r.pinPasscode)) {
      _isPatternMode = true;
      _patternPoints = PatternHelper.parsePattern(r.pinPasscode);
    } else {
      _isPatternMode = false;
      _patternPoints = [];
    }

    if (r.expectedDeliveryDate != null) {
      _expectedDeliveryDate = DateTime.tryParse(r.expectedDeliveryDate!);
    }

    if (r.technicianId != null) {
      _selectedTechnician = Technician(
        id: r.technicianId!,
        shopId: 0,
        name: r.technicianName ?? 'Technician #${r.technicianId}',
        isActive: true,
        workload: TechnicianWorkload(
          pendingJobs: 0,
          inProgressJobs: 0,
          completedJobs: 0,
          totalJobs: 0,
          totalValueHandled: 0,
        ),
      );
    }
  }

  Future<void> _fetchLatestRepairDetails() async {
    try {
      final res = await _repairRepository.getRepairDetails(widget.repair.id);
      if (mounted && res.success && res.data != null) {
        final r = res.data!;
        setState(() {
          _problemController.text = r.problemDescription;
          _conditionNotesController.text = r.conditionNotes ?? '';
          _accessoriesNotesController.text = r.accessoriesNotes ?? '';
          _pinPasscodeController.text = r.pinPasscode ?? '';
          _estimatedCostController.text = r.estimatedCost > 0 ? r.estimatedCost.toStringAsFixed(2) : '';
          _finalCostController.text = r.finalCost > 0 ? r.finalCost.toStringAsFixed(2) : '';
          _technicianEarningController.text = r.technicianEarning > 0 ? r.technicianEarning.toStringAsFixed(2) : '';
          _labourCostController.text = r.labourCost > 0 ? r.labourCost.toStringAsFixed(2) : '';
          _customerNotesController.text = r.customerNotes ?? '';
          _internalNotesController.text = r.internalNotes ?? '';
        });
      }
    } catch (_) {}
  }

    Future<void> _loadTechnicians() async {
    setState(() => _isLoadingTechnicians = true);
    try {
      // Fetch active technicians only for assignment dropdown
      final res = await _technicianRepository.getTechnicians(status: 'active');
      if (mounted && res.success && res.data != null) {
        setState(() {
          _technicianList = res.data!.technicians;
          if (widget.repair.technicianId != null) {
            final existingIndex = _technicianList.indexWhere((t) => t.id == widget.repair.technicianId);
            if (existingIndex != -1) {
              _selectedTechnician = _technicianList[existingIndex];
            } else if (_selectedTechnician != null) {
              // If previously assigned technician was deactivated, keep in list with label
              _technicianList.insert(0, _selectedTechnician!);
            }
          }
          _isLoadingTechnicians = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTechnicians = false);
    }
  }

  @override
  void dispose() {
    _problemController.dispose();
    _conditionNotesController.dispose();
    _accessoriesNotesController.dispose();
    _pinPasscodeController.dispose();
    _estimatedCostController.dispose();
    _finalCostController.dispose();
    _technicianEarningController.dispose();
    _labourCostController.dispose();
    _customerNotesController.dispose();
    _internalNotesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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

  Future<void> _showPhotoPickerSheet(String slot) async {
    if (widget.repair.repairStatus == 'delivered') {
      AppFeedback.showError(context, error: 'Photos cannot be changed or retaken after the repair is delivered.');
      return;
    }

    String title = 'Device Photo';
    String desc = 'Take a clear photo';
    if (slot == 'front') {
      title = 'Mobile Front Photo';
      desc = 'Take a clear photo of the screen and front condition';
    } else if (slot == 'back') {
      title = 'Mobile Back Photo';
      desc = 'Take a clear photo of the rear panel, camera or body condition';
    } else if (slot == 'customer') {
      title = 'Customer Live Photo';
      desc = 'Capture customer photo live when receiving or delivering device';
    }

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
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
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
                  title: Text(
                    slot == 'customer' ? 'Capture Live Customer Photo (Camera)' : 'Take Photo with Camera',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    slot == 'customer' ? 'Capture live photo of the customer right now' : 'Capture condition right now',
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickImage(slot, ImageSource.camera);
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
                  subtitle: const Text('Select photo from gallery'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickImage(slot, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(String slot, ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          if (slot == 'front') {
            _newFrontPhotoFile = File(picked.path);
            _frontPhotoRemoved = false;
          } else if (slot == 'back') {
            _newBackPhotoFile = File(picked.path);
            _backPhotoRemoved = false;
          } else if (slot == 'customer') {
            _newCustomerPhotoFile = File(picked.path);
            _customerPhotoRemoved = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, message: 'Failed to pick image: $e');
      }
    }
  }

  Widget _buildPhotoSlot({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? newFile,
    required String? existingUrl,
    required bool isRemoved,
    required VoidCallback onPick,
    required VoidCallback onRemove,
    Color activeColor = AppColors.primary,
  }) {
    final isDelivered = widget.repair.repairStatus == 'delivered';
    final hasPhoto = newFile != null || (!isRemoved && existingUrl != null && existingUrl.isNotEmpty);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasPhoto ? activeColor.withOpacity(0.5) : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: activeColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (hasPhoto)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 12, color: Colors.green),
                      SizedBox(width: 4),
                      Text('Attached', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasPhoto) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: newFile != null
                      ? Image.file(
                          newFile,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          existingUrl!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 140,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey),
                            ),
                          ),
                        ),
                ),
                if (!isDelivered) ...[
                  Positioned(
                    top: 6,
                    right: 6,
                    child: InkWell(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: InkWell(
                      onTap: onPick,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded, size: 13, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Change', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            if (!isDelivered) ...[
              InkWell(
                onTap: onPick,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: activeColor.withOpacity(0.35), width: 1.2),
                    borderRadius: BorderRadius.circular(10),
                    color: activeColor.withOpacity(0.04),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 18, color: activeColor),
                      const SizedBox(width: 8),
                      Text('Tap to Capture or Upload', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: activeColor)),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 15, color: Colors.grey),
                    SizedBox(width: 6),
                    Text('No photo uploaded (Locked)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) {
      _showFormError('Please check the highlighted errors in the form.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final estimatedCost = double.tryParse(_estimatedCostController.text.trim()) ?? 0.0;
      final finalCost = double.tryParse(_finalCostController.text.trim()) ?? 0.0;
      final labourCost = double.tryParse(_labourCostController.text.trim()) ?? 0.0;

      final dateStr = _expectedDeliveryDate != null
          ? '${_expectedDeliveryDate!.year}-${_expectedDeliveryDate!.month.toString().padLeft(2, '0')}-${_expectedDeliveryDate!.day.toString().padLeft(2, '0')}'
          : null;

      String? frontPayload;
      if (_newFrontPhotoFile != null) {
        final bytes = await _newFrontPhotoFile!.readAsBytes();
        frontPayload = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } else if (_frontPhotoRemoved) {
        frontPayload = '';
      } else {
        frontPayload = _existingFrontPhotoUrl;
      }

      String? backPayload;
      if (_newBackPhotoFile != null) {
        final bytes = await _newBackPhotoFile!.readAsBytes();
        backPayload = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } else if (_backPhotoRemoved) {
        backPayload = '';
      } else {
        backPayload = _existingBackPhotoUrl;
      }

      String? customerPayload;
      if (_newCustomerPhotoFile != null) {
        final bytes = await _newCustomerPhotoFile!.readAsBytes();
        customerPayload = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } else if (_customerPhotoRemoved) {
        customerPayload = '';
      } else {
        customerPayload = _existingCustomerPhotoUrl;
      }

      final res = await _repairRepository.updateRepair(
        id: widget.repair.id,
        technicianId: _selectedTechnician?.id,
        technicianEarning: double.tryParse(_technicianEarningController.text) ?? 0.0,
        problemDescription: _problemController.text.trim(),
        deviceCondition: _selectedConditions.toList(),
        conditionNotes: _conditionNotesController.text.trim(),
        accessoriesReceived: _selectedAccessories.toList(),
        accessoriesNotes: _accessoriesNotesController.text.trim(),
        pinPasscode: _pinPasscodeController.text.trim(),
        devicePhoto: frontPayload,
        devicePhotoBack: backPayload,
        customerPhoto: customerPayload,
        expectedDeliveryDate: dateStr,
        estimatedCost: estimatedCost,
        finalCost: finalCost,
        labourCost: labourCost,
        customerNotes: _customerNotesController.text.trim(),
        internalNotes: _internalNotesController.text.trim(),
      );

      if (mounted) {
        if (res.success && res.data != null) {
          AppFeedback.showSuccess(
            context,
            title: '✅ Job Card Updated',
            message: 'Job Card #${widget.repair.jobNumber} updated successfully.',
          );
          Navigator.pop(context, true);
        } else {
          _showFormError(res.message);
        }
      }
    } catch (e) {
      if (mounted) _showFormError(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showTechnicianSearchBottomSheet() {
    String filterQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredTechs = _technicianList.where((t) {
              final q = filterQuery.toLowerCase();
              return t.name.toLowerCase().contains(q) ||
                  (t.mobile != null && t.mobile!.contains(q)) ||
                  (t.specialization != null && t.specialization!.toLowerCase().contains(q));
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Technician',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  TextField(
                    onChanged: (val) {
                      setModalState(() => filterQuery = val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search technician name or skill...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isLoadingTechnicians
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : filteredTechs.isEmpty
                            ? const Center(child: Text('No technicians found', style: TextStyle(color: AppColors.textSecondary)))
                            : ListView.separated(
                                itemCount: filteredTechs.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final tech = filteredTechs[idx];
                                  final isSelected = _selectedTechnician?.id == tech.id;
                                  final spec = tech.specialization ?? 'General Technician';
                                  return ListTile(
                                    title: Text(
                                      tech.name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                    subtitle: Text(spec, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedTechnician = tech;
                                      });
                                      Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit Job Card #${widget.repair.jobNumber}'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(8)),
                  child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],

                            // Technician Selection Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.engineering_rounded, color: AppColors.accent, size: 20),
                        SizedBox(width: 8),
                        Text('Assigned Technician', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Change or assign technician for this repair job', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _showTechnicianSearchBottomSheet,
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Assigned Technician',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.engineering_rounded, color: AppColors.primary),
                          suffixIcon: const Icon(Icons.search_rounded, size: 22, color: AppColors.primary),
                        ),
                        child: Text(
                          _selectedTechnician != null
                              ? '${_selectedTechnician!.name}${_selectedTechnician!.specialization != null ? ' (${_selectedTechnician!.specialization})' : ''}'
                              : (_isLoadingTechnicians ? 'Loading technicians...' : 'Tap to search & select technician (${_technicianList.length} available)'),
                          style: TextStyle(
                            color: _selectedTechnician == null ? AppColors.textMuted : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: _selectedTechnician != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (_selectedTechnician != null) ...[
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Technician Earning (\u{20B9})',
                        hint: 'Enter fixed earning for technician (e.g. 200)',
                        controller: _technicianEarningController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.currency_rupee_rounded,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (ctx) {
                          final fCost = double.tryParse(_finalCostController.text) ?? 0.0;
                          final eCost = double.tryParse(_estimatedCostController.text) ?? 0.0;
                          final repairCost = fCost > 0 ? fCost : eCost;
                          final techEarning = double.tryParse(_technicianEarningController.text) ?? 0.0;
                          final shopShare = (repairCost - techEarning) < 0 ? 0.0 : (repairCost - techEarning);
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Shop Share: \u{20B9}${shopShare.toStringAsFixed(2)}',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tech Earning: \u{20B9}${techEarning.toStringAsFixed(2)}',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Problem & Complaint
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Customer Complaint / Problem', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Problem Description *',
                      controller: _problemController,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Device Condition
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Device Condition', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableConditions.map((cond) {
                        final isSelected = _selectedConditions.contains(cond);
                        return FilterChip(
                          label: Text(cond),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedConditions.add(cond);
                              } else {
                                _selectedConditions.remove(cond);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Condition Notes',
                      hint: 'Enter device condition notes...',
                      controller: _conditionNotesController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Accessories Received
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Accessories Received', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableAccessories.map((acc) {
                        final isSelected = _selectedAccessories.contains(acc);
                        return FilterChip(
                          label: Text(acc),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAccessories.add(acc);
                              } else {
                                _selectedAccessories.remove(acc);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Accessories Notes',
                      hint: 'Enter accessories received notes...',
                      controller: _accessoriesNotesController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Device Photo Card (3 Photos)
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Repair & Customer Photos',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('3 Photos', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Capture or update mobile front, back condition photos and live customer photo',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (widget.repair.repairStatus == 'delivered') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_rounded, size: 16, color: Colors.amber),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Job Card is Delivered. Photos are locked and cannot be changed.',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Slot 1: Mobile Front Photo
                    _buildPhotoSlot(
                      title: '1. Mobile Front Photo',
                      subtitle: 'Front screen condition & display scratches',
                      icon: Icons.smartphone_rounded,
                      newFile: _newFrontPhotoFile,
                      existingUrl: _existingFrontPhotoUrl,
                      isRemoved: _frontPhotoRemoved,
                      onPick: () => _showPhotoPickerSheet('front'),
                      onRemove: () {
                        setState(() {
                          _newFrontPhotoFile = null;
                          _frontPhotoRemoved = true;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),

                    // Slot 2: Mobile Back Photo
                    _buildPhotoSlot(
                      title: '2. Mobile Back Photo',
                      subtitle: 'Rear body, back panel & camera condition',
                      icon: Icons.flip_to_back_rounded,
                      newFile: _newBackPhotoFile,
                      existingUrl: _existingBackPhotoUrl,
                      isRemoved: _backPhotoRemoved,
                      onPick: () => _showPhotoPickerSheet('back'),
                      onRemove: () {
                        setState(() {
                          _newBackPhotoFile = null;
                          _backPhotoRemoved = true;
                        });
                      },
                      activeColor: Colors.deepPurple,
                    ),

                    // Slot 3: Customer Live Photo
                    _buildPhotoSlot(
                      title: '3. Customer Live Photo',
                      subtitle: 'Click live photo when customer receives or hands over mobile',
                      icon: Icons.person_pin_circle_rounded,
                      newFile: _newCustomerPhotoFile,
                      existingUrl: _existingCustomerPhotoUrl,
                      isRemoved: _customerPhotoRemoved,
                      onPick: () => _showPhotoPickerSheet('customer'),
                      onRemove: () {
                        setState(() {
                          _newCustomerPhotoFile = null;
                          _customerPhotoRemoved = true;
                        });
                      },
                      activeColor: Colors.teal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Costs & Financials
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Repair Pricing & Labour', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Estimated Cost (\u{20B9})',
                            hint: '0.00',
                            controller: _estimatedCostController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomTextField(
                            label: 'Final Cost (\u{20B9})',
                            hint: '0.00',
                            controller: _finalCostController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Labour Amount (\u{20B9})',
                      hint: '0.00',
                      controller: _labourCostController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Security & Delivery Schedule
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, color: AppColors.accent, size: 20),
                        SizedBox(width: 8),
                        Text('Security & Delivery Schedule', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Lock Type Selector
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.password_rounded, size: 15),
                              SizedBox(width: 4),
                              Text('PIN / Password', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          selected: !_isPatternMode,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _isPatternMode = false;
                                if (PatternHelper.isPattern(_pinPasscodeController.text)) {
                                  _pinPasscodeController.clear();
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pattern_rounded, size: 15),
                              SizedBox(width: 4),
                              Text('Pattern Lock', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          selected: _isPatternMode,
                          onSelected: (val) {
                            if (val) {
                              setState(() => _isPatternMode = true);
                              if (_patternPoints.isEmpty) {
                                _openPatternDialog();
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (!_isPatternMode) ...[
                      TextField(
                        controller: _pinPasscodeController,
                        obscureText: _obscurePin,
                        decoration: InputDecoration(
                          labelText: 'PIN / Password (Optional)',
                          hintText: 'Enter lock PIN or password...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          prefixIcon: const Icon(Icons.password_rounded, color: AppColors.accent),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted),
                            onPressed: () => setState(() => _obscurePin = !_obscurePin),
                          ),
                        ),
                      ),
                    ] else ...[
                      if (_patternPoints.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              PatternPreviewWidget(
                                dimension: 85,
                                pattern: _patternPoints,
                                lineColor: Colors.amber.shade900,
                                activeDotColor: Colors.amber.shade900,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pattern Set (${_patternPoints.length} dots)',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      PatternHelper.toReadableString(_patternPoints),
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: _openPatternDialog,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.amber.shade400),
                                            ),
                                            child: Text('Redraw', style: TextStyle(color: Colors.amber.shade900, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _patternPoints.clear();
                                              _pinPasscodeController.clear();
                                            });
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                            child: Text('Clear', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        InkWell(
                          onTap: _openPatternDialog,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primary, width: 1.2),
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.primary.withOpacity(0.04),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.pattern_rounded, color: AppColors.primary, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Tap to Draw Customer Pattern Lock',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _expectedDeliveryDate ?? DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _expectedDeliveryDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _expectedDeliveryDate != null
                                    ? 'Expected Delivery: ${_expectedDeliveryDate!.day}/${_expectedDeliveryDate!.month}/${_expectedDeliveryDate!.year}'
                                    : 'Expected Delivery Date (Tap to select)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _expectedDeliveryDate != null ? AppColors.textPrimary : AppColors.textMuted,
                                  fontWeight: _expectedDeliveryDate != null ? FontWeight.bold : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_expectedDeliveryDate != null)
                              InkWell(
                                onTap: () => setState(() => _expectedDeliveryDate = null),
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notes Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notes_rounded, color: AppColors.accent, size: 20),
                        SizedBox(width: 8),
                        Text('Repair Notes & Log', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Customer Notes',
                      hint: 'Enter customer notes...',
                      controller: _customerNotesController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Internal Technician Log',
                      hint: 'Enter internal technician notes...',
                      controller: _internalNotesController,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: 'Save Changes',
                isLoading: _isSubmitting,
                onPressed: _submitUpdate,
                icon: Icons.save_rounded,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
