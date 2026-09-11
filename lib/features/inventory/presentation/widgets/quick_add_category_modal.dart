import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class QuickAddCategoryModal extends StatefulWidget {
  final String title;
  final String label;
  final String hint;

  const QuickAddCategoryModal({
    super.key,
    required this.title,
    required this.label,
    required this.hint,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String label,
    required String hint,
  }) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => QuickAddCategoryModal(
        title: title,
        label: label,
        hint: hint,
      ),
    );
  }

  @override
  State<QuickAddCategoryModal> createState() => _QuickAddCategoryModalState();
}

class _QuickAddCategoryModalState extends State<QuickAddCategoryModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final value = _nameController.text.trim();
    AppFeedback.showSuccess(
      context,
      title: '✅ Added',
      message: '$value added successfully.',
    );
    Navigator.pop(context, value);
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
                  child: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),
            CustomTextField(
              label: widget.label,
              hint: widget.hint,
              controller: _nameController,
              isRequired: true,
              prefixIcon: Icons.label_outline,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter a name.';
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Save & Select',
              icon: Icons.check,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
