import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/repair.dart';

class UpdateStatusDialog extends StatefulWidget {
  final Repair repair;
  const UpdateStatusDialog({super.key, required this.repair});

  static Future<Map<String, dynamic>?> show(BuildContext context, {required Repair repair}) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: UpdateStatusDialog(repair: repair),
      ),
    );
  }

  @override
  State<UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends State<UpdateStatusDialog> {
  late String _selectedStatus;
  final _notesController = TextEditingController();
  File? _customerPhotoFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickCustomerPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
      if (picked != null) {
        setState(() => _customerPhotoFile = File(picked.path));
      }
    } catch (_) {}
  }

  final Map<String, String> _statusLabels = {
    'received': 'Received',
    'diagnosing': 'Diagnosing',
    'waiting_customer': 'Waiting for Customer',
    'waiting_parts': 'Waiting for Parts',
    'repairing': 'Under Repair',
    'ready': 'Ready for Pickup',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };

  final Map<String, Color> _statusColors = {
    'received': Colors.blue.shade700,
    'diagnosing': Colors.purple.shade700,
    'waiting_customer': Colors.orange.shade800,
    'waiting_parts': Colors.amber.shade900,
    'repairing': Colors.indigo.shade700,
    'ready': Colors.teal.shade700,
    'delivered': Colors.green.shade800,
    'cancelled': Colors.red.shade700,
  };

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.repair.repairStatus;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
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
          // Title Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.published_with_changes_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Update Job Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Job Card: ${widget.repair.jobNumber}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Select New Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statusLabels.entries.map((entry) {
              final isSelected = _selectedStatus == entry.key;
              final color = _statusColors[entry.key] ?? AppColors.primary;
              return ChoiceChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedStatus = entry.key);
                },
                selectedColor: color,
                backgroundColor: Colors.grey.shade100,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Status Change Notes (Optional)',
              hintText: 'e.g. Waiting for customer screen approval',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            maxLines: 2,
          ),
          if (_selectedStatus == 'delivered') ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_pin_circle_rounded, color: Colors.green, size: 18),
                      SizedBox(width: 6),
                      Text('Customer Live Handover Photo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Click live photo of customer receiving the device', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  if (_customerPhotoFile != null) ...[
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_customerPhotoFile!, width: 60, height: 60, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Photo attached', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                              TextButton.icon(
                                onPressed: () => setState(() => _customerPhotoFile = null),
                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                label: const Text('Remove', style: TextStyle(fontSize: 11, color: Colors.red)),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickCustomerPhoto(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_rounded, size: 16),
                            label: const Text('Camera', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green.shade800,
                              side: BorderSide(color: Colors.green.shade400),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickCustomerPhoto(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_rounded, size: 16),
                            label: const Text('Gallery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green.shade800,
                              side: BorderSide(color: Colors.green.shade400),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                String? customerPhotoPayload;
                if (_customerPhotoFile != null) {
                  final bytes = await _customerPhotoFile!.readAsBytes();
                  customerPhotoPayload = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                }
                if (context.mounted) {
                  Navigator.pop(context, {
                    'status': _selectedStatus,
                    'notes': _notesController.text.trim(),
                    if (customerPhotoPayload != null) 'customer_photo': customerPhotoPayload,
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _statusColors[_selectedStatus] ?? AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Update Status Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
