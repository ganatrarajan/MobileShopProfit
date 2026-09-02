import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authRepository = AuthRepository();
  bool _isLoading = false;
  String? _message;

  Future<void> _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final response = await _authRepository.requestPasswordReset(
        login: _loginController.text.trim(),
        password: _newPasswordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message.isNotEmpty ? response.message : 'Password updated successfully. Please log in.'),
              backgroundColor: AppColors.accent,
            ),
          );
          Navigator.pop(context);
        } else {
          setState(() => _message = response.message);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reset Owner Password'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Password Reset',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter your registered mobile number, new password, and confirm to update directly.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                if (_message != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Text(
                      _message!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                CustomTextField(
                  label: 'Registered Mobile Number or Email *',
                  hint: 'e.g. 9876543210 or owner@shop.com',
                  controller: _loginController,
                  prefixIcon: Icons.phone_android_rounded,
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter registered mobile or email' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'New Password *',
                  hint: 'Enter new password',
                  controller: _newPasswordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (val) => (val == null || val.length < 6) ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Confirm New Password *',
                  hint: 'Re-enter new password',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_clock_outlined,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please confirm your new password';
                    if (val != _newPasswordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                CustomButton(
                  text: 'Update Password',
                  isLoading: _isLoading,
                  onPressed: _handleUpdatePassword,
                  icon: Icons.check_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
