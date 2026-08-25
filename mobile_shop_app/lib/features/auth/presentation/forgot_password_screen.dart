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
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authRepository = AuthRepository();
  bool _isLoading = false;
  bool _codeGenerated = false;
  String? _message;

  Future<void> _handleRequestResetCode() async {
    if (_loginController.text.trim().isEmpty) {
      setState(() => _message = 'Please enter your mobile or email');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final response = await _authRepository.requestPasswordReset(login: _loginController.text.trim());
      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _codeGenerated = true;
            _tokenController.text = response.data['reset_token'] ?? '';
            _message = 'Reset code generated: ${response.data['reset_token']}';
          });
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

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final response = await _authRepository.resetPassword(
        login: _loginController.text.trim(),
        token: _tokenController.text.trim(),
        password: _newPasswordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully. Please log in.')),
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
    _tokenController.dispose();
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
                  'Password Recovery',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter your mobile number or email to receive a reset verification code.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                if (_message != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _codeGenerated ? AppColors.accentLight : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _message!,
                      style: TextStyle(color: _codeGenerated ? AppColors.accent : AppColors.error, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                CustomTextField(
                  label: 'Registered Mobile or Email',
                  hint: 'e.g. 9876543210',
                  controller: _loginController,
                  prefixIcon: Icons.phone_android_rounded,
                  readOnly: _codeGenerated,
                ),
                const SizedBox(height: 16),
                if (!_codeGenerated) ...[
                  CustomButton(
                    text: 'Get Reset Code',
                    isLoading: _isLoading,
                    onPressed: _handleRequestResetCode,
                  ),
                ] else ...[
                  CustomTextField(
                    label: 'Reset Verification Code *',
                    hint: '6-digit code',
                    controller: _tokenController,
                    prefixIcon: Icons.key_rounded,
                    validator: (val) => (val == null || val.isEmpty) ? 'Enter reset code' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'New Password *',
                    hint: 'At least 8 characters',
                    controller: _newPasswordController,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline_rounded,
                    validator: (val) => (val == null || val.length < 8) ? 'Min 8 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Confirm New Password *',
                    hint: 'Re-enter password',
                    controller: _confirmPasswordController,
                    isPassword: true,
                    prefixIcon: Icons.lock_clock_outlined,
                    validator: (val) {
                      if (val != _newPasswordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Reset Password & Save',
                    isLoading: _isLoading,
                    onPressed: _handleResetPassword,
                    icon: Icons.check_rounded,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}