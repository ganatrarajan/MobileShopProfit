import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/technician_repository.dart';
import '../models/technician.dart';

class AddEditTechnicianDialog extends StatefulWidget {
  final Technician? technician;
  const AddEditTechnicianDialog({super.key, this.technician});

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

  @override
  void initState() {
    super.initState();
    if (widget.technician != null) {
      _nameController.text = widget.technician!.name;
      _mobileController.text = widget.technician!.mobile ?? '';
      _specializationController.text = widget.technician!.specialization ?? '';
      _isActive = widget.technician!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();
    final specialization = _specializationController.text.trim();

    try {
      if (widget.technician == null) {
        final response = await _repository.createTechnician(
          name: name,
          mobile: mobile,
          specialization: specialization,
          isActive: _isActive,
        );
        if (mounted) {
          if (response.success && response.data != null) {
            Navigator.pop(context, true);
          } else {
            setState(() {
              _errorMessage = response.message;
              _isSaving = false;
            });
          }
        }
      } else {
        final response = await _repository.updateTechnician(
          id: widget.technician!.id,
          name: name,
          mobile: mobile,
          specialization: specialization,
          isActive: _isActive,
        );
        if (mounted) {
          if (response.success && response.data != null) {
            Navigator.pop(context, true);
          } else {
            setState(() {
              _errorMessage = response.message;
              _isSaving = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.technician != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Technician' : 'Add Technician',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Technician Name *',
                    hintText: 'e.g. Rahul Sharma',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter technician name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    hintText: 'e.g. 9876543210',
                    prefixIcon: Icon(Icons.phone_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _specializationController,
                  decoration: const InputDecoration(
                    labelText: 'Specialization',
                    hintText: 'e.g. Screen Replacement, Micro Soldering',
                    prefixIcon: Icon(Icons.build_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active Status'),
                  subtitle: Text(
                    _isActive ? 'Available for job assignment' : 'Inactive (hidden from assignment)',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  activeColor: AppColors.accent,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isEditing ? 'Update Technician' : 'Add Technician',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}