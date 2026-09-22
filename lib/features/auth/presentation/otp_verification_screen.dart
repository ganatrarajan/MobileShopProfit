import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../data/auth_repository.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String mobile;
  final int cooldownSeconds;
  final String? otpDebug;
  final bool isProfileUpdate;
  final bool isForgotPassword;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.mobile,
    this.cooldownSeconds = 60,
    this.otpDebug,
    this.isProfileUpdate = false,
    this.isForgotPassword = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  final _authRepository = AuthRepository();
  late String _currentVerificationId;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  Timer? _timer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _secondsRemaining = widget.cooldownSeconds > 0 ? widget.cooldownSeconds : 60;
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = widget.cooldownSeconds > 0 ? widget.cooldownSeconds : 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  String get _formattedMobile {
    final clean = widget.mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 10) {
      return '+91 ' + clean;
    } else if (clean.length == 12 && clean.startsWith('91')) {
      return '+91 ' + clean.substring(2);
    } else if (widget.mobile.trim().isNotEmpty) {
      return widget.mobile.startsWith('+') ? widget.mobile : '+91 ' + widget.mobile;
    }
    return 'your mobile number';
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _handleVerify() async {
    final otp = _otpCode.trim();
    if (otp.length < 4) {
      setState(() {
        _errorMessage = 'Please enter all 4 digits of the OTP.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.isProfileUpdate) {
        final response = await _authRepository.verifyProfileOtp(
          verificationId: _currentVerificationId,
          otp: otp,
        );

        if (mounted) {
          if (response.success) {
            Navigator.pop(context, true);
          } else {
            setState(() {
              _errorMessage = response.message ?? 'OTP verification failed. Please try again.';
            });
          }
        }
      } else if (widget.isForgotPassword) {
        final response = await _authRepository.verifyForgotPasswordOtp(
          verificationId: _currentVerificationId,
          otp: otp,
        );

        if (mounted) {
          if (response.success) {
            final data = response.data is Map ? response.data['data'] ?? response.data : {};
            final vId = data['verification_id']?.toString() ?? _currentVerificationId;
            Navigator.pop(context, vId);
          } else {
            setState(() {
              _errorMessage = response.message ?? 'OTP verification failed. Please try again.';
            });
          }
        }
      } else {
        final response = await _authRepository.verifyRegisterOtp(
          verificationId: _currentVerificationId,
          otp: otp,
        );

        if (mounted) {
          if (response.success) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (route) => false);
          } else {
            setState(() {
              _errorMessage = response.message ?? 'OTP verification failed. Please try again.';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final response = widget.isForgotPassword
          ? await _authRepository.sendForgotPasswordOtp(mobile: widget.mobile)
          : await _authRepository.resendRegisterOtp(verificationId: _currentVerificationId);

      if (mounted) {
        if (response.success && response.data != null) {
          final data = response.data is Map ? response.data['data'] ?? response.data : {};
          if (data['verification_id'] != null) {
            _currentVerificationId = data['verification_id'].toString();
          }
          for (var c in _controllers) {
            c.clear();
          }
          _focusNodes[0].requestFocus();
          _startCountdown();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A new OTP code has been sent to your mobile SMS.'),
              backgroundColor: AppColors.primary,
            ),
          );
        } else {
          setState(() {
            _errorMessage = response.message ?? 'Failed to resend OTP.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isProfileUpdate
            ? 'Verify Mobile Update'
            : (widget.isForgotPassword ? 'Reset Password OTP' : 'OTP Verification')),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isProfileUpdate
                    ? 'Verify New Mobile Number'
                    : (widget.isForgotPassword ? 'Reset Password Verification' : 'Verify Mobile Number'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  children: [
                    const TextSpan(text: 'We have sent a 4-digit SMS verification code to '),
                    TextSpan(
                      text: _formattedMobile,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    TextSpan(
                      text: widget.isProfileUpdate
                          ? '. Enter it below to verify and save your mobile update.'
                          : (widget.isForgotPassword
                              ? '. Enter it below to verify and reset your password.'
                              : '. Enter it below to complete registration.'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.5)),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 54,
                    height: 60,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (_otpCode.length == 4) {
                          _handleVerify();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: widget.isProfileUpdate
                    ? 'Verify & Update Mobile'
                    : (widget.isForgotPassword ? 'Verify OTP Code' : 'Verify & Create Shop Account'),
                isLoading: _isLoading,
                onPressed: _handleVerify,
                icon: Icons.verified_user_rounded,
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    if (_secondsRemaining > 0)
                      Text(
                        'Resend OTP in  seconds',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                      )
                    else
                      TextButton.icon(
                        onPressed: _isResending ? null : _handleResend,
                        icon: _isResending
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Resend OTP SMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        widget.isProfileUpdate
                            ? 'Cancel & Back to Profile'
                            : (widget.isForgotPassword ? 'Back to Login' : 'Edit Registration Details / Mobile'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

