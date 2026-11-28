import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/pattern_lock_widget.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/widgets/app_shimmer.dart';
import 'repair_invoice_pdf_screen.dart';
import '../../warranty/models/warranty.dart';
import '../data/repair_repository.dart';
import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/storage/preferences_storage.dart';
import '../../../core/services/profit_visibility_service.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/whatsapp_icon.dart';
import '../../warranty/presentation/warranty_details_screen.dart';
import '../../warranty/presentation/widgets/quick_add_warranty_modal.dart';

import '../../warranty/data/warranty_repository.dart';
import '../../device/data/device_repository.dart';
import '../models/repair.dart';
import 'add_repair_part_dialog.dart';
import 'collect_repair_payment_dialog.dart';
import 'update_status_dialog.dart';
import '../../../core/widgets/barcode_scanner_screen.dart';
import '../../settings/presentation/widgets/security_pin_dialogs.dart';

class RepairDetailsScreen extends StatefulWidget {
  final Repair repair;
  const RepairDetailsScreen({super.key, required this.repair});

  @override
  State<RepairDetailsScreen> createState() => _RepairDetailsScreenState();
}

class _RepairDetailsScreenState extends State<RepairDetailsScreen> {
  
  final RepairRepository _repairRepository = RepairRepository();
  final WarrantyRepository _warrantyRepository = WarrantyRepository();
  final DeviceRepository _deviceRepository = DeviceRepository();
  late Repair _repair;
  bool _isLoading = false;
  bool _isOwner = true;
  bool _obscurePasscode = true;

  static const Map<String, Color> _statusColors = {
    'received': Colors.blue,
    'diagnosing': Colors.orange,
    'waiting_customer': Colors.purple,
    'waiting_parts': Colors.amber,
    'repairing': Colors.indigo,
    'ready': Colors.green,
    'delivered': Colors.teal,
    'cancelled': Colors.red,
  };

  static const Map<String, String> _statusLabels = {
    'received': 'Received',
    'diagnosing': 'Diagnosing',
    'waiting_customer': 'Waiting Customer Approval',
    'waiting_parts': 'Waiting for Parts',
    'repairing': 'Under Repair',
    'ready': 'Ready for Pickup',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };

  @override
  void initState() {
    super.initState();
    _repair = widget.repair;
    AuthStorage().isOwner().then((val) {
      if (mounted) setState(() => _isOwner = val);
    });
    _refreshDetails();
  }

  Future<void> _refreshDetails() async {
    setState(() => _isLoading = true);
    try {
      final res = await _repairRepository.getRepairDetails(_repair.id);
      if (mounted) {
        if (res.success && res.data != null) {
          var fetchedRepair = res.data!;
          // Ensure warranty belongs strictly to this repair and is active
          if (fetchedRepair.warranty != null &&
              fetchedRepair.warranty!.repairId == fetchedRepair.id &&
              (fetchedRepair.warranty!.status == 'active' || fetchedRepair.warranty!.status == 'expiring_soon')) {
            // Keep backend warranty relation
          } else {
            // Fallback query filtering strictly by repairId
            final wRes = await _warrantyRepository.getWarranties(repairId: fetchedRepair.id);
            Warranty? matchingWarranty;
            if (wRes.success && wRes.data != null && wRes.data!.isNotEmpty) {
              final activeW = wRes.data!.where((w) =>
                  w.repairId == fetchedRepair.id &&
                  (w.status == 'active' || w.status == 'expiring_soon')).toList();
              if (activeW.isNotEmpty) {
                matchingWarranty = activeW.first;
              }
            }

            fetchedRepair = Repair(
              id: fetchedRepair.id,
              shopId: fetchedRepair.shopId,
              customerId: fetchedRepair.customerId,
              deviceId: fetchedRepair.deviceId,
              technicianId: fetchedRepair.technicianId,
              technicianName: fetchedRepair.technicianName,
              technicianEarning: fetchedRepair.technicianEarning,
              technicianPaidAmount: fetchedRepair.technicianPaidAmount,
              technicianPayable: fetchedRepair.technicianPayable,
              shopShare: fetchedRepair.shopShare,
              technicianPaymentStatus: fetchedRepair.technicianPaymentStatus,
              jobNumber: fetchedRepair.jobNumber,
              dateReceived: fetchedRepair.dateReceived,
              expectedDeliveryDate: fetchedRepair.expectedDeliveryDate,
              deliveredDate: fetchedRepair.deliveredDate,
              problemDescription: fetchedRepair.problemDescription,
              deviceCondition: fetchedRepair.deviceCondition,
              conditionNotes: fetchedRepair.conditionNotes,
              accessoriesReceived: fetchedRepair.accessoriesReceived,
              accessoriesNotes: fetchedRepair.accessoriesNotes,
              pinPasscode: fetchedRepair.pinPasscode,
              devicePhoto: fetchedRepair.devicePhoto,
              devicePhotoBack: fetchedRepair.devicePhotoBack,
              customerPhoto: fetchedRepair.customerPhoto,
              estimatedCost: fetchedRepair.estimatedCost,
              finalCost: fetchedRepair.finalCost,
              labourCost: fetchedRepair.labourCost,
              amountPaid: fetchedRepair.amountPaid,
              amountDue: fetchedRepair.amountDue,
              repairStatus: fetchedRepair.repairStatus,
              customerNotes: fetchedRepair.customerNotes,
              internalNotes: fetchedRepair.internalNotes,
              createdBy: fetchedRepair.createdBy,
              creatorName: fetchedRepair.creatorName,
              customer: fetchedRepair.customer,
              device: fetchedRepair.device,
              parts: fetchedRepair.parts,
              payments: fetchedRepair.payments,
              warranty: matchingWarranty,
              createdAt: fetchedRepair.createdAt,
              updatedAt: fetchedRepair.updatedAt,
            );
          }

          setState(() {
            _repair = fetchedRepair;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePhotoAction(String slot, {bool isChange = false}) async {
    if (_repair.repairStatus == 'delivered') {
      AppFeedback.showError(context, error: 'Photos cannot be changed or retaken after the repair is delivered.');
      return;
    }

    String title = 'Device Photo';
    String desc = 'Take a clear photo';
    if (slot == 'front') {
      title = 'Mobile Front Photo';
      desc = 'Take or upload front screen condition photo';
    } else if (slot == 'back') {
      title = 'Mobile Back Photo';
      desc = 'Take or upload rear body and camera condition photo';
    } else if (slot == 'customer') {
      title = 'Customer Live Photo';
      desc = 'Capture live photo of the customer receiving or handing over the device';
    }

    final ImagePicker picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isChange ? 'Change $title' : 'Add $title',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: Text(
                  slot == 'customer' ? 'Capture Live with Camera' : 'Take Photo with Camera',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(slot == 'customer' ? 'Click live photo now' : 'Capture condition right now'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.accent),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Select existing photo from device storage'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await picker.pickImage(source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
      if (picked == null) return;

      final bytes = await File(picked.path).readAsBytes();
      final base64Payload = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      await _savePhotoPayload(slot, base64Payload);
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, error: 'Error picking photo: $e');
      }
    }
  }

  Future<void> _removePhoto(String slot) async {
    if (_repair.repairStatus == 'delivered') {
      AppFeedback.showError(context, error: 'Photos cannot be removed after the repair is delivered.');
      return;
    }

    String label = slot == 'front' ? 'Front Photo' : slot == 'back' ? 'Back Photo' : 'Customer Photo';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove $label?'),
        content: Text('Are you sure you want to delete this $label? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _savePhotoPayload(slot, '');
    }
  }

  Future<void> _savePhotoPayload(String slot, String payload) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
                const SizedBox(width: 16),
                Text(payload.isEmpty ? 'Removing photo...' : 'Saving photo...', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final res = await _repairRepository.updateRepair(
        id: _repair.id,
        devicePhoto: slot == 'front' ? payload : null,
        devicePhotoBack: slot == 'back' ? payload : null,
        customerPhoto: slot == 'customer' ? payload : null,
      );

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (res.success && res.data != null) {
        setState(() => _repair = res.data!);
        _refreshDetails();
        if (mounted) {
          AppFeedback.showSuccess(
            context,
            title: payload.isEmpty ? 'Photo Removed' : 'Photo Saved',
            message: payload.isEmpty ? 'Photo removed successfully.' : 'Photo updated successfully.',
          );
        }
      } else {
        if (mounted) {
          AppFeedback.showError(context, error: res.message.isNotEmpty ? res.message : 'Failed to update photo');
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        AppFeedback.showError(context, error: 'Error: $e');
      }
    }
  }

  Future<void> _updateStatus() async {
    String? securityPin;
    if (_repair.repairStatus == 'delivered') {
      if (!_isOwner) {
        if (mounted) {
          AppFeedback.showError(context, error: 'Job Card is Delivered & finalized. Only shop admin can change status.');
        }
        return;
      }

      final pin = await SecurityPinPromptDialog.show(
        context,
        title: 'Modify Delivered Status',
        message: 'This job card is marked as Delivered. Please enter your 4-digit Security PIN to change its status.',
        confirmLabel: 'Verify & Proceed',
      );

      if (pin == null || pin.isEmpty) {
        return;
      }
      securityPin = pin;
    }

    if (!mounted) return;
    final result = await UpdateStatusDialog.show(context, repair: _repair);

    if (result != null && result['status'] != null) {
      final String targetStatus = result['status'];
      final String? statusNotes = result['notes'];

      if (targetStatus == 'delivered' && _repair.amountDue > 0) {
        final shouldCollect = await _showPaymentDueDeliveryWarningSheet(_repair.amountDue);
        if (shouldCollect == true) {
          await _collectPayment();
          if (_repair.amountDue > 0) {
            if (mounted) {
              AppFeedback.showError(context, error: 'Cannot deliver job card. Remaining balance of \u20B9${_repair.amountDue.toStringAsFixed(2)} is still due!');
            }
            return;
          }
        } else {
          return; // Cancelled
        }
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(width: 16),
                  Text('Updating status...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      );

      final res = await _repairRepository.updateStatus(
        id: _repair.id,
        repairStatus: targetStatus,
        notes: statusNotes,
        securityPin: securityPin,
        customerPhoto: result['customer_photo'],
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
      }

      if (res.success && res.data != null) {
        setState(() => _repair = res.data!);
        _refreshDetails();
        
        if (mounted) {
          final initialLangCode = await PreferencesStorage().getWhatsAppLanguage();
          var selectedStatusLang = WhatsAppLanguage.fromCode(initialLangCode);

          if (!context.mounted) return;

          await showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (ctx) => StatefulBuilder(
              builder: (context, setSheetState) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          WhatsAppIcon(size: 26),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text('Send WhatsApp Update?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Send status update notification to ${_repair.customer != null ? _repair.customer!.name : "Customer"} on WhatsApp?'),
                      const SizedBox(height: 14),
                      WhatsAppLanguageSelector(
                        compact: true,
                        selectedLanguage: selectedStatusLang,
                        onLanguageChanged: (lang) {
                          setSheetState(() {
                            selectedStatusLang = lang;
                          });
                          PreferencesStorage().saveWhatsAppLanguage(lang.code);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Not Now'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await WhatsAppHelper.sendRepairStatusWhatsAppMessage(
                                  context,
                                  _repair,
                                  targetStatus,
                                  statusNotes: statusNotes,
                                  language: selectedStatusLang,
                                );
                              },
                              icon: const WhatsAppIcon(size: 16, showBackground: false),
                              label: const Text('Send WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          AppFeedback.showError(context, error: res.message);
        }
      }
    }
  }

  Future<bool?> _showPaymentDueDeliveryWarningSheet(double amountDue) {
    return showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Payment Due - Cannot Deliver',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  '⚠️ Remaining Balance Due: \u20B9${amountDue.toStringAsFixed(2)}\n\nDelivery is blocked until full payment is collected!',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.add_card_rounded, color: Colors.white, size: 18),
                  label: Text('Collect Payment (\u20B9${amountDue.toStringAsFixed(2)})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addPart() async {
    if (_repair.repairStatus == 'delivered') {
      AppFeedback.showError(context, error: 'Job Card is Delivered. Cannot add parts.');
      return;
    }

    final result = await AddRepairPartDialog.show(context, repair: _repair);
    if (result != null) {
      if (result is Repair) {
        setState(() => _repair = result);
      }
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          title: 'Part Added',
          message: 'Part added to repair successfully.',
        );
      }
      _refreshDetails();
    }
  }

  Future<void> _collectPayment() async {
    final result = await CollectRepairPaymentDialog.show(context, repair: _repair);
    if (result != null) {
      if (result is Repair) {
        setState(() => _repair = result);
      }
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          title: 'Payment Recorded',
          message: 'Payment recorded successfully.',
        );
      }
      _refreshDetails();
    }
  }

  Future<void> _showEditDeviceImeiDialog() async {
    if (_repair.repairStatus == 'delivered') {
      AppFeedback.showError(context, error: 'Job Card is Delivered & finalized. IMEI cannot be modified.');
      return;
    }

    final device = _repair.device;
    if (device == null) {
      AppFeedback.showError(context, error: 'No device associated with this repair.');
      return;
    }

    final imei1Controller = TextEditingController(text: device.imei1 ?? '');
    final imei2Controller = TextEditingController(text: device.imei2 ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    String? errorMessage;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: bottomInset + 16,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Header Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Edit Device IMEI',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${device.brand} ${device.model}',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                              onPressed: isSaving ? null : () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Info banner
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF475569)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Update 15-digit IMEI numbers for Job Card #${_repair.jobNumber.isNotEmpty ? _repair.jobNumber : _repair.id}. IMEIs are searchable across the app and printed on invoices.',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Box Auto-Scan Shortcut Button
                        InkWell(
                          onTap: isSaving
                              ? null
                              : () async {
                                  final result = await BarcodeScannerScreen.scanBox(
                                    sheetContext,
                                    title: 'Auto-Scan Phone Box',
                                    instruction: 'Point camera at box sticker with IMEIs',
                                  );
                                  if (!sheetContext.mounted) return;
                                  if (result != null) {
                                    setSheetState(() {
                                      if (result.imei1 != null && result.imei1!.isNotEmpty) {
                                        imei1Controller.text = result.imei1!;
                                      }
                                      if (result.imei2 != null && result.imei2!.isNotEmpty) {
                                        imei2Controller.text = result.imei2!;
                                      }
                                    });
                                    if (result.hasBothImeis) {
                                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                                        const SnackBar(
                                          content: Text('✓ Both IMEI 1 & IMEI 2 captured from scan!'),
                                          duration: Duration(seconds: 2),
                                          backgroundColor: Color(0xFF10B981),
                                        ),
                                      );
                                    }
                                  }
                                },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_scanner_rounded, size: 16, color: Color(0xFF10B981)),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Auto-Scan Box Barcode (Capture Both IMEIs)',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Error message if any
                        if (errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.error.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // IMEI 1 Field
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(
                              child: Text(
                                'IMEI 1 (Primary)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (imei1Controller.text.trim().isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: imei1Controller.text.trim().length == 15
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  imei1Controller.text.trim().length == 15
                                      ? '✓ 15/15 Digits'
                                      : '${imei1Controller.text.trim().length}/15 Digits',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: imei1Controller.text.trim().length == 15
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: imei1Controller,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(15),
                          ],
                          style: const TextStyle(fontSize: 14.5, fontFamily: 'monospace', letterSpacing: 1.2, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Enter 15-digit IMEI 1',
                            hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400, fontFamily: 'sans-serif', letterSpacing: 0, fontWeight: FontWeight.normal),
                            prefixIcon: const Icon(Icons.smartphone_rounded, size: 18, color: AppColors.primary),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (imei1Controller.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                                    onPressed: () {
                                      imei1Controller.clear();
                                      setSheetState(() {});
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.content_paste_rounded, size: 18, color: AppColors.primary),
                                  tooltip: 'Paste',
                                  onPressed: () async {
                                    final data = await Clipboard.getData('text/plain');
                                    if (data?.text != null) {
                                      final clean = data!.text!.replaceAll(RegExp(r'\D'), '');
                                      if (clean.isNotEmpty) {
                                        imei1Controller.text = clean.length > 15 ? clean.substring(0, 15) : clean;
                                        setSheetState(() {});
                                      }
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: AppColors.primary),
                                  tooltip: 'Scan Barcode',
                                  onPressed: () async {
                                    final scanned = await BarcodeScannerScreen.scan(sheetContext, title: 'Scan IMEI 1');
                                    if (!sheetContext.mounted) return;
                                    if (scanned != null && scanned.isNotEmpty) {
                                      final clean = scanned.replaceAll(RegExp(r'\D'), '');
                                      imei1Controller.text = clean.length > 15 ? clean.substring(0, 15) : clean;
                                      setSheetState(() {});
                                    }
                                  },
                                ),
                              ],
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          ),
                          onChanged: (_) => setSheetState(() {}),
                        ),
                        const SizedBox(height: 14),

                        // IMEI 2 Field
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(
                              child: Text(
                                'IMEI 2 (Secondary / Optional)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (imei2Controller.text.trim().isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: imei2Controller.text.trim().length == 15
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  imei2Controller.text.trim().length == 15
                                      ? '✓ 15/15 Digits'
                                      : '${imei2Controller.text.trim().length}/15 Digits',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: imei2Controller.text.trim().length == 15
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: imei2Controller,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(15),
                          ],
                          style: const TextStyle(fontSize: 14.5, fontFamily: 'monospace', letterSpacing: 1.2, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Enter 15-digit IMEI 2 (Optional)',
                            hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400, fontFamily: 'sans-serif', letterSpacing: 0, fontWeight: FontWeight.normal),
                            prefixIcon: const Icon(Icons.smartphone_outlined, size: 18, color: AppColors.textMuted),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (imei2Controller.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                                    onPressed: () {
                                      imei2Controller.clear();
                                      setSheetState(() {});
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.content_paste_rounded, size: 18, color: AppColors.primary),
                                  tooltip: 'Paste',
                                  onPressed: () async {
                                    final data = await Clipboard.getData('text/plain');
                                    if (data?.text != null) {
                                      final clean = data!.text!.replaceAll(RegExp(r'\D'), '');
                                      if (clean.isNotEmpty) {
                                        imei2Controller.text = clean.length > 15 ? clean.substring(0, 15) : clean;
                                        setSheetState(() {});
                                      }
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: AppColors.primary),
                                  tooltip: 'Scan Barcode',
                                  onPressed: () async {
                                    final scanned = await BarcodeScannerScreen.scan(sheetContext, title: 'Scan IMEI 2');
                                    if (!sheetContext.mounted) return;
                                    if (scanned != null && scanned.isNotEmpty) {
                                      final clean = scanned.replaceAll(RegExp(r'\D'), '');
                                      imei2Controller.text = clean.length > 15 ? clean.substring(0, 15) : clean;
                                      setSheetState(() {});
                                    }
                                  },
                                ),
                              ],
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          ),
                          onChanged: (_) => setSheetState(() {}),
                        ),
                        const SizedBox(height: 20),

                        // Action Buttons: Cancel & Save
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                onPressed: isSaving ? null : () => Navigator.pop(sheetContext),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        final imei1 = imei1Controller.text.trim();
                                        final imei2 = imei2Controller.text.trim();

                                        if (imei1.isNotEmpty && imei1.length != 15) {
                                          setSheetState(() => errorMessage = 'IMEI 1 must be exactly 15 digits');
                                          return;
                                        }
                                        if (imei2.isNotEmpty && imei2.length != 15) {
                                          setSheetState(() => errorMessage = 'IMEI 2 must be exactly 15 digits');
                                          return;
                                        }
                                        if (imei1.isNotEmpty && imei2.isNotEmpty && imei1 == imei2) {
                                          setSheetState(() => errorMessage = 'IMEI 1 and IMEI 2 cannot be identical');
                                          return;
                                        }

                                        setSheetState(() {
                                          isSaving = true;
                                          errorMessage = null;
                                        });

                                        final res = await _deviceRepository.updateDeviceImei(
                                          id: device.id,
                                          brand: device.brand,
                                          model: device.model,
                                          deviceType: device.deviceType,
                                          imei1: imei1.isNotEmpty ? imei1 : null,
                                          imei2: imei2.isNotEmpty ? imei2 : null,
                                        );

                                        if (!sheetContext.mounted) return;

                                        if (res.success) {
                                          Navigator.pop(sheetContext);

                                          final updatedDevice = device.copyWith(
                                            imei1: imei1.isNotEmpty ? imei1 : null,
                                            imei2: imei2.isNotEmpty ? imei2 : null,
                                          );

                                          if (mounted) {
                                            setState(() {
                                              _repair = _repair.copyWith(device: updatedDevice);
                                            });
                                            AppFeedback.showSuccess(
                                              context,
                                              title: 'IMEI Updated',
                                              message: 'Device IMEI numbers updated successfully.',
                                            );
                                            _refreshDetails();
                                          }
                                        } else {
                                          setSheetState(() {
                                            isSaving = false;
                                            errorMessage = res.message.isNotEmpty
                                                ? res.message
                                                : 'Failed to update device IMEI numbers.';
                                          });
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  elevation: 0,
                                ),
                                child: isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_circle_outline_rounded, size: 18),
                                          SizedBox(width: 6),
                                          Text('Save IMEI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeletePart(RepairPart part) async {
    if (_repair.repairStatus == 'delivered') {
      AppFeedback.showError(context, error: 'Job Card is Delivered. Cannot remove parts.');
      return;
    }

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Remove Part', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Remove part "${part.partName}" from this repair?'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                      child: const Text('Remove Part'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      final res = await _repairRepository.deletePart(part.id);
      if (mounted && res.success && res.data != null) {
        setState(() => _repair = res.data!);
        AppFeedback.showSuccess(
          context,
          title: 'Part Removed',
          message: 'Part removed from repair successfully.',
        );
        _refreshDetails();
      }
    }
  }

  Future<void> _confirmDeleteRepair() async {
    if (!_isOwner) {
      AppFeedback.showError(context, error: 'Only shop admin can delete repair jobs.');
      return;
    }

    final pin = await SecurityPinPromptDialog.show(
      context,
      title: 'Delete Job Card',
      message: 'Are you sure you want to delete job card ${_repair.jobNumber}? This action cannot be undone.\n\nEnter your 4-digit Security PIN to confirm deletion.',
      confirmLabel: 'Delete Job Card',
      isDanger: true,
      onConfirmAction: (enteredPin) => _repairRepository.deleteRepair(_repair.id, securityPin: enteredPin),
    );

    if (pin == null || pin.isEmpty) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Job Card ${_repair.jobNumber} deleted successfully.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[_repair.repairStatus] ?? AppColors.primary;
    final statusLabel = _statusLabels[_repair.repairStatus] ?? _repair.repairStatus.toUpperCase();
    final bool isDelivered = (_repair.repairStatus == 'delivered');
    final bool isTechEmpty = (_repair.technicianName == null || _repair.technicianName!.trim().isEmpty);
    final bool isPartsEmpty = _repair.parts.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          _repair.jobNumber.isNotEmpty ? 'Job #${_repair.jobNumber}' : 'Job Details',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          const ProfitVisibilityToggle(),
          if (!isDelivered)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              onPressed: () async {
                final updated = await Navigator.pushNamed(context, AppRoutes.editRepair, arguments: _repair);
                if (updated == true) _refreshDetails();
              },
              tooltip: 'Edit Job Card',
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            tooltip: 'More Options',
            onSelected: (value) async {
              if (value == 'pdf') {
                RepairInvoicePdfScreen.show(context, _repair);
              } else if (value == 'whatsapp') {
                WhatsAppHelper.showRepairWhatsAppOptions(context, _repair);
              } else if (value == 'edit') {
                final updated = await Navigator.pushNamed(context, AppRoutes.editRepair, arguments: _repair);
                if (updated == true) _refreshDetails();
              } else if (value == 'refresh') {
                _refreshDetails();
              } else if (value == 'status') {
                _updateStatus();
              } else if (value == 'delete') {
                _confirmDeleteRepair();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, size: 20, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text('View PDF Bill / Ticket'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'whatsapp',
                child: Row(
                  children: [
                    WhatsAppIcon(size: 20),
                    SizedBox(width: 10),
                    Text('WhatsApp Options'),
                  ],
                ),
              ),
              if (!isDelivered)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 20, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text('Edit Job Card'),
                    ],
                  ),
                ),
              if (!isDelivered || _isOwner)
                PopupMenuItem(
                  value: 'status',
                  child: Row(
                    children: [
                      Icon(
                        isDelivered ? Icons.lock_open_rounded : Icons.published_with_changes_rounded,
                        size: 20,
                        color: isDelivered ? Colors.orange.shade800 : AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(isDelivered ? 'Change Delivered Status' : 'Change Status'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 20, color: AppColors.textPrimary),
                    SizedBox(width: 10),
                    Text('Refresh Details'),
                  ],
                ),
              ),
              if (_isOwner)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                      SizedBox(width: 10),
                      Text('Delete Job Card', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (!isDelivered) ...[
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _updateStatus,
                      icon: const Icon(Icons.published_with_changes_rounded, size: 18),
                      label: const Text('Change Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ),
                if (_repair.amountDue > 0) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _collectPayment,
                        icon: const Icon(Icons.add_card_rounded, size: 16),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Collect ₹${_repair.amountDue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ] else if (_isOwner) ...[
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _updateStatus,
                      icon: const Icon(Icons.lock_open_rounded, size: 18),
                      label: const Text('Change Delivered Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_rounded, size: 18, color: Colors.grey),
                        SizedBox(width: 6),
                        Text(
                          'Delivered - Finalized (Read Only)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      body: _isLoading
          ? AppShimmer.detailsLoading()
          : RefreshIndicator(
              onRefresh: _refreshDetails,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Job Overview Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [statusColor, statusColor.withOpacity(0.85)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _repair.jobNumber,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                              const SizedBox(width: 6),
                              Text('Received: ${DateHelper.formatDate(_repair.dateReceived)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                          if (_repair.expectedDeliveryDate != null && _repair.expectedDeliveryDate!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.event_available_rounded, size: 14, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text('Expected: ${DateHelper.formatDate(_repair.expectedDeliveryDate)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ],
                          if (_repair.deliveredDate != null && _repair.deliveredDate!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.task_alt_rounded, size: 14, color: Colors.white70),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text('Delivered: ${DateHelper.formatDateTime(_repair.deliveredDate)}', style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick Share Buttons Row (WhatsApp, PDF Bill)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => WhatsAppHelper.showRepairWhatsAppOptions(context, _repair),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 1,
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  WhatsAppIcon(size: 15, showBackground: false),
                                  SizedBox(width: 4),
                                  Text('WhatsApp Ticket', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => RepairInvoicePdfScreen.show(context, _repair),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 1,
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.picture_as_pdf_rounded, size: 15),
                                  SizedBox(width: 4),
                                  Text('PDF Invoice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Warranty Status Card
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: _repair.warranty != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.verified_user_rounded, color: Colors.green, size: 20),
                                        SizedBox(width: 8),
                                        Text('Warranty Active', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _repair.warranty!.status == 'active' ? Colors.green.shade100 : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _repair.warranty!.status.toUpperCase(),
                                        style: TextStyle(
                                          color: _repair.warranty!.status == 'active' ? Colors.green.shade900 : Colors.orange.shade900,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Warranty #: ${_repair.warranty!.warrantyNumber}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Valid until: ${DateHelper.formatDate(_repair.warranty!.warrantyEndDate)} (${_repair.warranty!.daysRemaining} days remaining)',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                if (_repair.warranty!.warrantyTerms != null && _repair.warranty!.warrantyTerms!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Coverage: ${_repair.warranty!.warrantyTerms}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => WarrantyDetailsScreen(warranty: _repair.warranty!),
                                        ),
                                      );
                                      if (mounted) {
                                        _refreshDetails();
                                      }
                                    },
                                    icon: const Icon(Icons.shield_rounded, size: 16),
                                    label: const Text('View Warranty', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Row(
                                    children: [
                                      Icon(Icons.shield_outlined, color: AppColors.textSecondary, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('No Warranty Linked', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                            Text('Add a warranty for this repair', style: TextStyle(fontSize: 11, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isDelivered) ...[
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final newW = await QuickWarrantyModal.show(context, repair: _repair);
                                      if (newW != null) {
                                        _refreshDetails();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                                    label: const Text('Add Warranty', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Customer Info Card
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.person_pin_rounded, color: AppColors.accent, size: 20),
                              SizedBox(width: 8),
                              Text('Customer Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_repair.customer != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_repair.customer!.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text('Mobile: ${_repair.customer!.mobile}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                      if (_repair.customer!.city != null)
                                        Text('City: ${_repair.customer!.city}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => WhatsAppHelper.showRepairWhatsAppOptions(context, _repair),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF25D366).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFF25D366), width: 1.2),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        WhatsAppIcon(size: 18),
                                        SizedBox(width: 5),
                                        Text(
                                          'WhatsApp',
                                          style: TextStyle(
                                            color: Color(0xFF128C7E),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const Text('Customer ID recorded', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3. Device Info Card
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.phone_android_rounded, color: AppColors.accent, size: 20),
                                  SizedBox(width: 8),
                                  Text('Device Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              if (_repair.device != null && !isDelivered)
                                InkWell(
                                  onTap: _showEditDeviceImeiDialog,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_outlined, size: 13, color: AppColors.primary),
                                        SizedBox(width: 4),
                                        Text(
                                          'Edit IMEI',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_repair.device != null) ...[
                            Text('${_repair.device!.brand} ${_repair.device!.model}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            if (_repair.device!.variant != null && _repair.device!.variant!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text('Variant: ${_repair.device!.variant}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ),
                            const SizedBox(height: 8),
                            _buildDeviceImeiSection(),
                          ],
                          if (_repair.pinPasscode != null && _repair.pinPasscode!.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Builder(
                              builder: (ctx) {
                                final isPattern = PatternHelper.isPattern(_repair.pinPasscode);
                                final patternPoints = isPattern ? PatternHelper.parsePattern(_repair.pinPasscode) : <int>[];

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.amber.shade300),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(isPattern ? Icons.pattern_rounded : Icons.lock_rounded, size: 18, color: Colors.amber.shade900),
                                              const SizedBox(width: 6),
                                              Text(
                                                isPattern ? 'Device Pattern Lock' : 'Device PIN / Password',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.amber.shade900,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: () => setState(() => _obscurePasscode = !_obscurePasscode),
                                                borderRadius: BorderRadius.circular(6),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: Colors.amber.shade300),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        _obscurePasscode ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                                        size: 15,
                                                        color: Colors.amber.shade900,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _obscurePasscode ? 'View' : 'Hide',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.amber.shade900,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              IconButton(
                                                icon: const Icon(Icons.copy_rounded, size: 17),
                                                color: Colors.amber.shade900,
                                                tooltip: isPattern ? 'Copy Pattern Sequence' : 'Copy PIN',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () {
                                                  final copyText = isPattern
                                                      ? PatternHelper.toReadableString(patternPoints)
                                                      : _repair.pinPasscode!;
                                                  Clipboard.setData(ClipboardData(text: copyText));
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(isPattern ? 'Pattern sequence copied' : 'PIN copied to clipboard'),
                                                      duration: const Duration(seconds: 1),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Secret Display (Obscured vs Revealed)
                                      if (_obscurePasscode) ...[
                                        Text(
                                          isPattern ? '••••••••  (Pattern Lock Protected)' : '••••••••',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade900,
                                            letterSpacing: 2.0,
                                          ),
                                        ),
                                      ] else ...[
                                        if (isPattern) ...[
                                          // Pattern Revealed
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              PatternPreviewWidget(
                                                dimension: 110,
                                                pattern: patternPoints,
                                                lineColor: Colors.amber.shade900,
                                                activeDotColor: Colors.amber.shade900,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Connect in order:',
                                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    SelectableText(
                                                      PatternHelper.toReadableString(patternPoints),
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.amber.shade900,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    InkWell(
                                                      onTap: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (_) => Dialog(
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(20),
                                                              child: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Row(
                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                    children: [
                                                                      Text(
                                                                        'Device Pattern Lock',
                                                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                                                      ),
                                                                      IconButton(
                                                                        icon: const Icon(Icons.close_rounded),
                                                                        onPressed: () => Navigator.pop(context),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  const SizedBox(height: 12),
                                                                  PatternPreviewWidget(
                                                                    dimension: 220,
                                                                    pattern: patternPoints,
                                                                    lineColor: Colors.amber.shade900,
                                                                    activeDotColor: Colors.amber.shade900,
                                                                  ),
                                                                  const SizedBox(height: 14),
                                                                  Text(
                                                                    'Sequence: ${PatternHelper.toReadableString(patternPoints)}',
                                                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.amber.shade100,
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(Icons.zoom_in_rounded, size: 14, color: Colors.amber.shade900),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              'Enlarge Pattern',
                                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ] else ...[
                                          // PIN / Password Revealed
                                          SelectableText(
                                            _repair.pinPasscode!,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber.shade900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3b. Assigned Technician Card (Hide if delivered and unassigned)
                    if (!(isDelivered && isTechEmpty)) ...[
                      CustomCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.engineering_rounded, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Assigned Technician', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _repair.technicianName != null && _repair.technicianName!.isNotEmpty
                                        ? _repair.technicianName!
                                        : 'Unassigned',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _repair.technicianName != null && _repair.technicianName!.isNotEmpty
                                          ? AppColors.textPrimary
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                  if (_repair.technicianName != null && _repair.technicianName!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    ValueListenableBuilder<bool>(
                                      valueListenable: ProfitVisibilityService().isHiddenNotifier,
                                      builder: (context, _, __) {
                                        final fee = (_repair.technicianEarning > 0 ? _repair.technicianEarning : _repair.labourCost);
                                        return Text(
                                          'Technician Fee: ${ProfitVisibilityService().format(fee, decimals: 2)}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (_repair.technicianName != null && _repair.technicianName!.isNotEmpty)
                              ValueListenableBuilder<bool>(
                                valueListenable: ProfitVisibilityService().isHiddenNotifier,
                                builder: (context, _, __) {
                                  final fee = (_repair.technicianEarning > 0 ? _repair.technicianEarning : _repair.labourCost);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Text(
                                      ProfitVisibilityService().format(fee, decimals: 2),
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 4. Problem & Intake Condition Checklist
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.build_circle_outlined, size: 18, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('Reported Fault / Problem', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              _repair.problemDescription.isNotEmpty ? _repair.problemDescription : 'No problem description entered.',
                              style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.3),
                            ),
                          ),

                          // Device Physical Condition
                          if (_repair.deviceCondition.isNotEmpty || (_repair.conditionNotes != null && _repair.conditionNotes!.trim().isNotEmpty)) ...[
                            const SizedBox(height: 14),
                            const Row(
                              children: [
                                Icon(Icons.phonelink_setup_rounded, size: 17, color: Color(0xFFD97706)),
                                SizedBox(width: 8),
                                Text('Physical Condition', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ],
                            ),
                            if (_repair.deviceCondition.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _repair.deviceCondition.map((c) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Text('⚠️ $c', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade800)),
                                )).toList(),
                              ),
                            ],
                            if (_repair.conditionNotes != null && _repair.conditionNotes!.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  'Condition Note: ${_repair.conditionNotes!}',
                                  style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: Colors.grey.shade800),
                                ),
                              ),
                            ],
                          ],

                          // Accessories Received
                          if (_repair.accessoriesReceived.isNotEmpty || (_repair.accessoriesNotes != null && _repair.accessoriesNotes!.trim().isNotEmpty)) ...[
                            const SizedBox(height: 14),
                            const Row(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 17, color: Color(0xFF0D9488)),
                                SizedBox(width: 8),
                                Text('Accessories Received', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ],
                            ),
                            if (_repair.accessoriesReceived.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _repair.accessoriesReceived.map((a) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.teal.shade200),
                                  ),
                                  child: Text('📦 $a', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.teal.shade800)),
                                )).toList(),
                              ),
                            ],
                            if (_repair.accessoriesNotes != null && _repair.accessoriesNotes!.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  'Accessories Note: ${_repair.accessoriesNotes!}',
                                  style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: Colors.grey.shade800),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4a. Customer Notes & Internal Shop Notes (Prominently displayed)
                    if ((_repair.customerNotes != null && _repair.customerNotes!.trim().isNotEmpty) ||
                        (_repair.internalNotes != null && _repair.internalNotes!.trim().isNotEmpty)) ...[
                      CustomCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.description_outlined, size: 18, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text('Repair Notes & Remarks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ],
                            ),
                            if (_repair.customerNotes != null && _repair.customerNotes!.trim().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.notes_rounded, size: 15, color: Color(0xFF1D4ED8)),
                                        SizedBox(width: 6),
                                        Text(
                                          'CUSTOMER NOTES',
                                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8), letterSpacing: 0.5),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    SelectableText(
                                      _repair.customerNotes!,
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (_repair.internalNotes != null && _repair.internalNotes!.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.lock_outline_rounded, size: 15, color: Color(0xFFB45309)),
                                        SizedBox(width: 6),
                                        Text(
                                          'INTERNAL SHOP NOTES (PRIVATE)',
                                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309), letterSpacing: 0.5),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    SelectableText(
                                      _repair.internalNotes!,
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 4b. Repair & Handover Photos (Front, Back, Customer Live)
                    _buildPhotosSection(),
                    const SizedBox(height: 14),

                    // 5. Parts Used List (Hide if delivered and empty)
                    if (!(isDelivered && isPartsEmpty)) ...[
                      CustomCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.build_rounded, color: AppColors.accent, size: 20),
                                    SizedBox(width: 8),
                                    Text('Parts Used', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                if (!isDelivered)
                                  ElevatedButton.icon(
                                    onPressed: _addPart,
                                    icon: const Icon(Icons.add_rounded, size: 16),
                                    label: const Text('Add Part', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (_repair.parts.isEmpty)
                              const Text('No parts added yet.', style: TextStyle(fontSize: 13, color: AppColors.textMuted))
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _repair.parts.length,
                                separatorBuilder: (_, __) => const Divider(height: 12),
                                itemBuilder: (ctx, idx) {
                                  final p = _repair.parts[idx];
                                  return ValueListenableBuilder<bool>(
                                    valueListenable: ProfitVisibilityService().isHiddenNotifier,
                                    builder: (context, _, __) {
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(p.partName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                                Text('${p.quantity} x ${ProfitVisibilityService().format(p.sellingPrice, decimals: 2)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                              ],
                                            ),
                                          ),
                                          Text(ProfitVisibilityService().format(p.quantity * p.sellingPrice, decimals: 2), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          if (!isDelivered)
                                            IconButton(
                                              icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                                              onPressed: () => _confirmDeletePart(p),
                                            ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 6. Cost & Payment Summary Card
                    Builder(
                      builder: (ctx) {
                        final double totalPartsCost = _repair.parts.fold<double>(0.0, (sum, p) => sum + (p.quantity * p.sellingPrice));
                        final double techFee = _repair.technicianEarning > 0 ? _repair.technicianEarning : _repair.labourCost;
                        final double netProfit = _repair.netCost - totalPartsCost - techFee;

                        return CustomCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cost Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              _buildRow('Estimated Repair Cost', '\u20B9 ${_repair.estimatedCost.toStringAsFixed(2)}'),
                              if (_repair.finalCost > 0)
                                _buildRow('Final Repair Cost', '\u20B9 ${_repair.finalCost.toStringAsFixed(2)}', isBold: true),
                              if (totalPartsCost > 0)
                                ValueListenableBuilder<bool>(
                                  valueListenable: ProfitVisibilityService().isHiddenNotifier,
                                  builder: (context, _, __) => _buildRow(
                                    'Parts Cost Total',
                                    ProfitVisibilityService().format(totalPartsCost, prefix: '₹ ', decimals: 2),
                                    color: AppColors.accent,
                                    isBold: true,
                                  ),
                                ),
                              if (techFee > 0)
                                ValueListenableBuilder<bool>(
                                  valueListenable: ProfitVisibilityService().isHiddenNotifier,
                                  builder: (context, _, __) => _buildRow(
                                    'Technician Fee',
                                    ProfitVisibilityService().format(techFee, prefix: '₹ ', decimals: 2),
                                  ),
                                ),
                              const Divider(height: 16),
                              _buildRow('TOTAL NET AMOUNT', '\u20B9 ${_repair.netCost.toStringAsFixed(2)}', isBold: true, fontSize: 16),
                              if (_isOwner)
                                ValueListenableBuilder<bool>(
                                  valueListenable: ProfitVisibilityService().isHiddenNotifier,
                                  builder: (context, isHidden, _) {
                                    return _buildRow(
                                      'NET PROFIT',
                                      ProfitVisibilityService().format(netProfit, prefix: '₹ ', decimals: 2),
                                      color: netProfit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                      isBold: true,
                                      fontSize: 16,
                                    );
                                  },
                                ),
                              const SizedBox(height: 6),
                              _buildRow('Total Paid / Advance', '\u20B9 ${_repair.amountPaid.toStringAsFixed(2)}', color: Colors.green.shade700, isBold: true),
                              _buildRow(
                                'AMOUNT DUE',
                                '\u20B9 ${_repair.amountDue.toStringAsFixed(2)}',
                                color: _repair.amountDue > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                isBold: true,
                                fontSize: 16,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // 7. Payment History Card
                    if (_repair.payments.isNotEmpty) ...[
                      CustomCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Payment History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _repair.payments.length,
                              separatorBuilder: (_, __) => const Divider(height: 12),
                              itemBuilder: (ctx, idx) {
                                final p = _repair.payments[idx];
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '\u20B9 ${p.amount.toStringAsFixed(2)} (${p.paymentMethod.toUpperCase()})',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green.shade700),
                                        ),
                                        if (p.paymentDate != null)
                                          Text(DateHelper.formatDateTime(p.paymentDate), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      ],
                                    ),
                                    if (p.notes != null && p.notes!.isNotEmpty)
                                      Text(p.notes!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildDeviceImeiSection() {
    final device = _repair.device;
    if (device == null) return const SizedBox.shrink();

    final hasImei1 = device.imei1 != null && device.imei1!.trim().isNotEmpty;
    final hasImei2 = device.imei2 != null && device.imei2!.trim().isNotEmpty;
    final isDelivered = _repair.repairStatus == 'delivered';

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded, size: 16, color: Colors.blueGrey.shade700),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Device IMEI Numbers',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.blueGrey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isDelivered) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: _showEditDeviceImeiDialog,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                    child: Text(
                      (hasImei1 || hasImei2) ? 'Change' : '+ Add IMEI',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (!hasImei1 && !hasImei2) ...[
            if (!isDelivered)
              InkWell(
                onTap: _showEditDeviceImeiDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'No IMEI registered. Tap to add',
                          style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 15, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      'No IMEI registered',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
          ] else ...[
            if (hasImei1)
              _buildImeiRow(label: 'IMEI 1', value: device.imei1!),
            if (hasImei1 && hasImei2)
              const Divider(height: 12, thickness: 0.5),
            if (hasImei2)
              _buildImeiRow(label: 'IMEI 2', value: device.imei2!),
          ],
        ],
      ),
    );
  }

  Widget _buildImeiRow({required String label, required String value}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                letterSpacing: 0.8,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            AppFeedback.showSuccess(context, title: 'Copied', message: '$label copied to clipboard');
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(Icons.copy_rounded, size: 15, color: Colors.blueGrey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    final isDelivered = _repair.repairStatus == 'delivered';

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Repair & Handover Photos',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (isDelivered)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 12, color: AppColors.textMuted),
                      SizedBox(width: 4),
                      Text('Delivered (Locked)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Tap to zoom', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isDelivered
                ? 'Job Card is delivered. Device condition & handover photos are locked.'
                : 'Manage device front & back condition photos and live customer handover photo',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),

          // 1. Mobile Front Photo
          _buildDetailPhotoTile(
            title: '1. Mobile Front Photo',
            subtitle: 'Screen & display condition',
            icon: Icons.smartphone_rounded,
            imageUrl: _repair.devicePhoto,
            badgeColor: AppColors.primary,
            slot: 'front',
            isDelivered: isDelivered,
          ),
          const SizedBox(height: 10),

          // 2. Mobile Back Photo
          _buildDetailPhotoTile(
            title: '2. Mobile Back Photo',
            subtitle: 'Rear body, camera & panel condition',
            icon: Icons.flip_to_back_rounded,
            imageUrl: _repair.devicePhotoBack,
            badgeColor: Colors.deepPurple,
            slot: 'back',
            isDelivered: isDelivered,
          ),
          const SizedBox(height: 10),

          // 3. Customer Live Photo
          _buildDetailPhotoTile(
            title: '3. Customer Live Photo',
            subtitle: 'Live photo when customer received or handed over mobile',
            icon: Icons.person_pin_circle_rounded,
            imageUrl: _repair.customerPhoto,
            badgeColor: Colors.teal,
            slot: 'customer',
            isDelivered: isDelivered,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPhotoTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String? imageUrl,
    required Color badgeColor,
    required String slot,
    required bool isDelivered,
  }) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasImage ? badgeColor.withOpacity(0.4) : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: badgeColor, size: 18),
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
              if (hasImage)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: const Text('Saved', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasImage) ...[
            InkWell(
              onTap: () => _showFullImageDialog(context, imageUrl),
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey),
                              SizedBox(height: 6),
                              Text('Failed to load image', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Zoom', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isDelivered || slot == 'customer') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handlePhotoAction(slot, isChange: true),
                      icon: Icon(slot == 'customer' ? Icons.camera_alt_rounded : Icons.refresh_rounded, size: 15),
                      label: Text(slot == 'customer' ? 'Retake Photo' : 'Change Photo', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: badgeColor,
                        side: BorderSide(color: badgeColor.withOpacity(0.6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _removePhoto(slot),
                    icon: const Icon(Icons.delete_outline_rounded, size: 15),
                    label: const Text('Remove', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            if (!isDelivered || slot == 'customer') ...[
              InkWell(
                onTap: () => _handlePhotoAction(slot, isChange: false),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: badgeColor.withOpacity(0.35), width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(slot == 'customer' ? Icons.camera_alt_rounded : Icons.add_a_photo_outlined, size: 18, color: badgeColor),
                      const SizedBox(width: 8),
                      Text(
                        slot == 'front'
                            ? '📸 Add Front Photo'
                            : slot == 'back'
                                ? '📸 Add Back Photo'
                                : '📸 Click Live Customer Photo Now',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
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
}