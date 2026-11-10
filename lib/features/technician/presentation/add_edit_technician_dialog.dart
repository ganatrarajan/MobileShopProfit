import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../data/technician_repository.dart';
import '../models/technician.dart';

class AddEditTechnicianDialog extends StatefulWidget {
  final Technician? technician;
  const AddEditTechnicianDialog({super.key, this.technician});

  static Future<bool?> show(BuildContext context, {Technician? technician}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditTechnicianDialog(technician: technician),
    );
  }

  @override
  State<AddEditTechnicianDialog> createState() => _AddEditTechnicianDialogState();
}

class _AddEditTechnicianDialogState extends State<AddEditTechnicianDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _specializationController = TextEditingController();

  bool _isActive = true;
  bool _isSaving = false;
  String? _errorMessage;

  final TechnicianRepository _repository = TechnicianRepository();

  final List<String> _suggestedSpecializations = [
    'Hardware Specialist',
    'Screen & Glass Replacement',
    'Motherboard / IC Repair',
    'Software & Flashing',
    'General Repairs',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.technician != null) {
      final t = widget.technician!;
      _nameController.text = t.name;
      _mobileController.text = t.mobile ?? '';
      _specializationController.text = t.specialization ?? '';
      _isActive = t.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final name = _nameController.text.trim();
      final mobile = _mobileController.text.trim().isNotEmpty ? _mobileController.text.trim() : null;
      final specialization = _specializationController.text.trim().isNotEmpty ? _specializationController.text.trim() : null;

      if (widget.technician == null) {
        final res = await _repository.createTechnician(
          name: name,
          mobile: mobile,
          specialization: specialization,
          isActive: _isActive,
        );

        if (!mounted) return;

        if (res.success) {
          AppFeedback.showSuccess(context, title: 'Technician added successfully');
          Navigator.pop(context, true);
        } else {
          setState(() => _errorMessage = res.message);
        }
      } else {
        final res = await _repository.updateTechnician(
          id: widget.technician!.id,
          name: name,
          mobile: mobile,
          specialization: specialization,
          isActive: _isActive,
        );

        if (!mounted) return;

        if (res.success) {
          AppFeedback.showSuccess(context, title: 'Technician updated successfully');
          Navigator.pop(context, true);
        } else {
          setState(() => _errorMessage = res.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.technician != null;
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + keyboardSpace),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.build_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Technician' : 'Add New Technician',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Technicians are assigned to repair jobs & service tasks',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Full Name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Technician Name *',
                  hintText: 'e.g. Suresh Patel',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter technician name';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Mobile Number
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number (Optional)',
                  hintText: '10-digit phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              // Specialization
              TextFormField(
                controller: _specializationController,
                decoration: const InputDecoration(
                  labelText: 'Specialization / Skills',
                  hintText: 'e.g. Screen Replacement, Motherboard',
                  prefixIcon: Icon(Icons.handyman_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),

              // Suggestions Chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _suggestedSpecializations.map((skill) {
                  return ActionChip(
                    label: Text(skill, style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.grey.shade100,
                    onPressed: () {
                      _specializationController.text = skill;
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // Active Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Inactive technicians will not appear in new repair assignment', style: TextStyle(fontSize: 12)),
                value: _isActive,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _isActive = v),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? 'Save Changes' : 'Add Technician'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
