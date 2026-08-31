import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/warranty_repository.dart';
import '../models/warranty.dart';

class UpdateClaimStatusDialog extends StatefulWidget {
  final WarrantyClaim claim;
  const UpdateClaimStatusDialog({super.key, required this.claim});

  @override
  State<UpdateClaimStatusDialog> createState() => _UpdateClaimStatusDialogState();
}

class _UpdateClaimStatusDialogState extends State<UpdateClaimStatusDialog> {
  final _warrantyRepository = WarrantyRepository();
  late String _selectedStatus;
  late TextEditingController _complaintController;
  late TextEditingController _resolutionController;
  late TextEditingController _notesController;

  bool _isSubmitting = false;
  String? _errorMessage;

  final Map<String, String> _statusLabels = {
    'open': 'Open',
    'checking': 'Checking',
    'approved': 'Approved',
    'rejected': 'Rejected',
    'repairing': 'Repairing',
    'resolved': 'Resolved',
    'closed': 'Closed',
  };

  final Map<String, Color> _statusColors = {
    'open': Colors.blue.shade700,
    'checking': Colors.purple.shade700,
    'approved': Colors.teal.shade700,
    'rejected': Colors.red.shade700,
    'repairing': Colors.indigo.shade700,
    'resolved': Colors.green.shade700,
    'closed': Colors.grey.shade700,
  };

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.claim.claimStatus;
    _complaintController = TextEditingController(text: widget.claim.complaint);
    _resolutionController = TextEditingController(text: widget.claim.resolution);
    _notesController = TextEditingController(text: widget.claim.notes);
  }

  @override
  void dispose() {
    _complaintController.dispose();
    _resolutionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    final complaint = _complaintController.text.trim();
    if (complaint.isEmpty) {
      setState(() => _errorMessage = 'Complaint description cannot be empty.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final res = await _warrantyRepository.updateClaimStatus(
        claimId: widget.claim.id,
        claimStatus: _selectedStatus,
        complaint: complaint,
        resolution: _resolutionController.text.trim(),
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

  Future<void> _confirmDeleteClaim() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Claim'),
          content: Text('Are you sure you want to delete claim ${widget.claim.claimNumber}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final res = await _warrantyRepository.deleteClaim(widget.claim.id);
      if (mounted && res.success) {
        Navigator.pop(context, 'deleted');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[_selectedStatus] ?? AppColors.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.published_with_changes_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Modify Claim & Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(widget.claim.claimNumber, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
            onPressed: _confirmDeleteClaim,
            tooltip: 'Delete Claim',
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

            const Text('Claim Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
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
                    fontSize: 11,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            CustomTextField(
              label: 'Customer Complaint / Fault *',
              hint: 'Describe customer complaint',
              controller: _complaintController,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Resolution Notes',
              hint: 'e.g. Free display replacement done under warranty terms',
              controller: _resolutionController,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Internal Technician Notes',
              hint: 'Technician internal notes',
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
          onPressed: _isSubmitting ? null : _submitUpdate,
          style: ElevatedButton.styleFrom(
            backgroundColor: statusColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save & Update', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
