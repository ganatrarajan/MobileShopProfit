import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../data/auth_repository.dart';
import 'otp_verification_screen.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();

  final _authRepository = AuthRepository();
  bool _isLoading = false;
  String? _message;

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final mobile = _mobileController.text.trim();

    try {
      final response = await _authRepository.sendForgotPasswordOtp(
        mobile: mobile,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          final data = response.data is Map ? response.data['data'] ?? response.data : {};
          final verificationId = data['verification_id']?.toString() ?? '';

          if (verificationId.isNotEmpty) {
            final dynamic verifiedId = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpVerificationScreen(
                  verificationId: verificationId,
                  mobile: mobile,
                  cooldownSeconds: data['cooldown_seconds'] ?? 60,
                  isForgotPassword: true,
                ),
              ),
            );

            if (mounted && verifiedId != null && verifiedId is String && verifiedId.isNotEmpty) {
              await Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ResetPasswordScreen(
                    verificationId: verifiedId,
                  ),
                ),
              );
            }
          } else {
            setState(() => _message = 'Failed to initiate OTP session.');
          }
        } else {
          setState(() => _message = response.message ?? 'No account found matching this mobile number.');
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
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: AppColors.primary,
        elevation: 0,
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
                  'Enter your registered 10-digit mobile number. We will send a 4-digit MSG91 OTP code to verify your account.',
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
                  label: 'Registered Mobile Number *',
                  hint: 'e.g. 9876543210',
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_android_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter your registered mobile number';
                    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
                    if (clean.length < 10) return 'Please enter a valid 10-digit mobile number';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                CustomButton(
                  text: 'Send MSG91 OTP SMS',
                  isLoading: _isLoading,
                  onPressed: _handleSendOtp,
                  icon: Icons.sms_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
