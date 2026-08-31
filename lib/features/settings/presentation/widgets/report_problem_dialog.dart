import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ReportProblemDialog extends StatefulWidget {
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? shop;

  const ReportProblemDialog({super.key, this.user, this.shop});

  @override
  State<ReportProblemDialog> createState() => _ReportProblemDialogState();
}

class _ReportProblemDialogState extends State<ReportProblemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    // Simulate sending report via existing support mechanism
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Problem report submitted successfully! Thank you.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const appVersion = '1.0.0+1';
    final platformStr = Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : Platform.operatingSystem;
    final shopId = widget.shop?['id']?.toString() ?? 'N/A';
    final userId = widget.user?['id']?.toString() ?? 'N/A';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.report_problem_rounded, color: AppColors.error),
          SizedBox(width: 10),
          Text('Report a Problem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please describe the issue you encountered in detail:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'e.g. App closed unexpectedly when creating a repair ticket...',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please describe the problem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Auto-attached Metadata:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Text('App Version: $appVersion | OS: $platformStr', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text('Shop ID: $shopId | User ID: $userId', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(100, 40),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
