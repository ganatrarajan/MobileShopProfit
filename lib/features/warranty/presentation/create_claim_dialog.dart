import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/warranty_repository.dart';
import '../models/warranty.dart';

class CreateClaimDialog extends StatefulWidget {
  final Warranty warranty;
  const CreateClaimDialog({super.key, required this.warranty});

  @override
  State<CreateClaimDialog> createState() => _CreateClaimDialogState();
}

class _CreateClaimDialogState extends State<CreateClaimDialog> {
  final _warrantyRepository = WarrantyRepository();
  final _complaintController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _complaintController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitClaim() async {
    final complaint = _complaintController.text.trim();
    if (complaint.isEmpty) {
      setState(() => _errorMessage = 'Please describe the customer complaint.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final res = await _warrantyRepository.createClaim(
        warrantyId: widget.warranty.id,
        complaint: complaint,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        if (res.success && res.data != null) {
          Navigator.pop(context, res.data);
        } else {
          setState(() {
            _errorMessage = res.message;
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.assignment_late_rounded, color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Register Warranty Claim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(widget.warranty.warrantyNumber, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(6)),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
              ),
              const SizedBox(height: 12),
            ],
            CustomTextField(
              label: 'Customer Complaint / Fault *',
              hint: 'e.g. Screen flickering after 10 days of repair',
              controller: _complaintController,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Claim Notes (Optional)',
              hint: 'e.g. Customer brought device with original bill',
              controller: _notesController,
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitClaim,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('File Claim', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
