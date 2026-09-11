import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/technician_repository.dart';
import '../../models/technician.dart';

class QuickAddTechnicianModal extends StatefulWidget {
  const QuickAddTechnicianModal({super.key});

  static Future<Technician?> show(BuildContext context) async {
    return await showModalBottomSheet<Technician>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const QuickAddTechnicianModal(),
    );
  }

  @override
  State<QuickAddTechnicianModal> createState() => _QuickAddTechnicianModalState();
}

class _QuickAddTechnicianModalState extends State<QuickAddTechnicianModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _specializationController = TextEditingController();
  final _technicianRepository = TechnicianRepository();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final response = await _technicianRepository.createTechnician(
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
        specialization: _specializationController.text.trim().isEmpty ? null : _specializationController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (response.success && response.data != null) {
          final createdTech = response.data!;
          AppFeedback.showSuccess(
            context,
            title: '✅ Technician Added',
            message: '${createdTech.name} has been added successfully.',
          );
          Navigator.pop(context, createdTech);
        } else {
          AppFeedback.showError(context, error: response.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppFeedback.showError(context, error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.build_circle_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Add Technician',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Add technician details for job assignment',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
            const Divider(height: 24),
            CustomTextField(
              label: 'Technician Name',
              hint: 'e.g. Suresh Kumar',
              controller: _nameController,
              isRequired: true,
              prefixIcon: Icons.person_outline,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter technician name.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Mobile Number (Optional)',
              hint: 'e.g. 9876543210',
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Specialization (Optional)',
              hint: 'e.g. Hardware, Display Replacement, Software',
              controller: _specializationController,
              prefixIcon: Icons.handyman_outlined,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: _isSaving ? 'Adding Technician...' : 'Save & Select Technician',
              icon: Icons.check,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
