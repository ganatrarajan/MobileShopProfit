import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../data/security_pin_repository.dart';

enum SecurityPinDialogMode { setup, update, forgot }

/// Dialog for managing Security PIN (Setup, Update, or Reset/Forgot).
class SecurityPinSettingsDialog extends StatefulWidget {
  final SecurityPinDialogMode initialMode;

  const SecurityPinSettingsDialog({
    super.key,
    this.initialMode = SecurityPinDialogMode.setup,
  });

  static Future<bool?> show(
    BuildContext context, {
    SecurityPinDialogMode initialMode = SecurityPinDialogMode.setup,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SecurityPinSettingsDialog(initialMode: initialMode),
    );
  }

  @override
  State<SecurityPinSettingsDialog> createState() => _SecurityPinSettingsDialogState();
}

class _SecurityPinSettingsDialogState extends State<SecurityPinSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final SecurityPinRepository _pinRepo = SecurityPinRepository();

  late SecurityPinDialogMode _mode;

  final _passwordController = TextEditingController();
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureCurrentPin = true;
  bool _obscureNewPin = true;
  bool _obscureConfirmPin = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _switchMode(SecurityPinDialogMode newMode) {
    setState(() {
      _mode = newMode;
      _errorMessage = null;
      _passwordController.clear();
      _currentPinController.clear();
      _newPinController.clear();
      _confirmPinController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    dynamic response;
    if (_mode == SecurityPinDialogMode.setup) {
      response = await _pinRepo.setupPin(
        password: _passwordController.text,
        pin: _newPinController.text.trim(),
        pinConfirmation: _confirmPinController.text.trim(),
      );
    } else if (_mode == SecurityPinDialogMode.update) {
      response = await _pinRepo.updatePin(
        currentPin: _currentPinController.text.trim(),
        pin: _newPinController.text.trim(),
        pinConfirmation: _confirmPinController.text.trim(),
      );
    } else {
      response = await _pinRepo.forgotPin(
        password: _passwordController.text,
        pin: _newPinController.text.trim(),
        pinConfirmation: _confirmPinController.text.trim(),
      );
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (response != null && response.success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message.isNotEmpty
              ? response.message
              : 'Security PIN configured successfully!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } else {
      setState(() {
        _errorMessage = (response != null && response.message.isNotEmpty)
            ? response.message
            : 'Action failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Set Up Security PIN';
    String subtitle = 'Enter your login password and choose a 4-digit PIN for shop owner actions.';

    if (_mode == SecurityPinDialogMode.update) {
      title = 'Change Security PIN';
      subtitle = 'Enter your existing 4-digit PIN to choose a new one.';
    } else if (_mode == SecurityPinDialogMode.forgot) {
      title = 'Reset Security PIN';
      subtitle = 'Verify your login password to set a new 4-digit PIN.';
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
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
                  const SizedBox(height: 16),
                ],

                // Setup or Forgot Mode: Need Login Password
                if (_mode == SecurityPinDialogMode.setup || _mode == SecurityPinDialogMode.forgot) ...[
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Account Login Password',
                      hintText: 'Enter account password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Login password is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // Update Mode: Need Current 4-digit PIN
                if (_mode == SecurityPinDialogMode.update) ...[
                  TextFormField(
                    controller: _currentPinController,
                    obscureText: _obscureCurrentPin,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Current 4-Digit PIN',
                      hintText: '••••',
                      counterText: '',
                      prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrentPin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureCurrentPin = !_obscureCurrentPin),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length != 4) {
                        return 'Enter your current 4-digit PIN';
                      }
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _switchMode(SecurityPinDialogMode.forgot),
                      child: const Text('Forgot PIN?', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // New PIN Field
                TextFormField(
                  controller: _newPinController,
                  obscureText: _obscureNewPin,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: _mode == SecurityPinDialogMode.setup ? 'Create 4-Digit PIN' : 'New 4-Digit PIN',
                    hintText: '••••',
                    counterText: '',
                    prefixIcon: const Icon(Icons.dialpad_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureNewPin = !_obscureNewPin),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length != 4) {
                      return 'PIN must be exactly 4 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Confirm PIN Field
                TextFormField(
                  controller: _confirmPinController,
                  obscureText: _obscureConfirmPin,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Confirm 4-Digit PIN',
                    hintText: '••••',
                    counterText: '',
                    prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length != 4) {
                      return 'Confirm your 4-digit PIN';
                    }
                    if (val.trim() != _newPinController.text.trim()) {
                      return 'PINs do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(_mode == SecurityPinDialogMode.setup
                  ? 'Set PIN'
                  : _mode == SecurityPinDialogMode.update
                      ? 'Update PIN'
                      : 'Reset PIN'),
        ),
      ],
    );
  }
}

/// A clean, dedicated PIN entry dialog used before sensitive actions
/// (e.g. deleting a repair or changing status of a delivered repair).
class SecurityPinPromptDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool isDanger;
  final Future<dynamic> Function(String pin)? onConfirmAction;

  const SecurityPinPromptDialog({
    super.key,
    this.title = 'Security PIN Required',
    this.message = 'Please enter your 4-digit Security PIN to confirm this action.',
    this.confirmLabel = 'Confirm',
    this.isDanger = false,
    this.onConfirmAction,
  });

  /// Static helper to display the PIN prompt dialog and return the entered PIN.
  static Future<String?> show(
    BuildContext context, {
    String title = 'Security PIN Required',
    String message = 'Please enter your 4-digit Security PIN to proceed.',
    String confirmLabel = 'Confirm',
    bool isDanger = false,
    Future<dynamic> Function(String pin)? onConfirmAction,
  }) async {
    // Check if user has a PIN configured
    final authStorage = AuthStorage();
    final hasPin = await authStorage.hasSecurityPin();

    if (!context.mounted) return null;

    if (!hasPin) {
      // Prompt user to set up PIN first
      final setupResult = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Security PIN Required', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'You have not set up a Security PIN yet. A 4-digit Security PIN is required for deleting jobs and updating delivered repairs.\n\nWould you like to set it up now?',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Set Up PIN Now'),
            ),
          ],
        ),
      );

      if (setupResult == true && context.mounted) {
        final pinConfigured = await SecurityPinSettingsDialog.show(
          context,
          initialMode: SecurityPinDialogMode.setup,
        );
        if (pinConfigured != true) return null;
      } else {
        return null;
      }
    }

    if (!context.mounted) return null;

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => SecurityPinPromptDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        isDanger: isDanger,
        onConfirmAction: onConfirmAction,
      ),
    );
  }

  @override
  State<SecurityPinPromptDialog> createState() => _SecurityPinPromptDialogState();
}

class _SecurityPinPromptDialogState extends State<SecurityPinPromptDialog> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final SecurityPinRepository _pinRepo = SecurityPinRepository();
  bool _obscurePin = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (!_formKey.currentState!.validate()) return;
    final pin = _pinController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.onConfirmAction != null) {
      final dynamic result = await widget.onConfirmAction!(pin);
      if (!mounted) return;

      bool isSuccess = false;
      String? errorMsg;

      if (result is bool) {
        isSuccess = result;
      } else if (result != null) {
        try {
          isSuccess = (result.success == true);
          errorMsg = result.message?.toString();
        } catch (_) {
          isSuccess = false;
        }
      }

      if (isSuccess) {
        Navigator.pop(context, pin);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = (errorMsg != null && errorMsg.isNotEmpty)
              ? errorMsg
              : 'Invalid Security PIN. Please try again.';
          _pinController.clear();
        });
      }
    } else {
      final res = await _pinRepo.verifyPin(pin);
      if (!mounted) return;

      if (res.success) {
        Navigator.pop(context, pin);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = res.message.isNotEmpty
              ? res.message
              : 'Invalid Security PIN. Please try again.';
          _pinController.clear();
        });
      }
    }
  }

  Future<void> _onForgotPin() async {
    final reset = await SecurityPinSettingsDialog.show(
      context,
      initialMode: SecurityPinDialogMode.forgot,
    );
    if (reset == true && mounted) {
      _pinController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Security PIN reset successfully. Please enter your new PIN.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Row(
        children: [
          Icon(
            widget.isDanger ? Icons.warning_amber_rounded : Icons.shield_rounded,
            color: widget.isDanger ? AppColors.error : AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: widget.isDanger ? AppColors.error : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _pinController,
              autofocus: true,
              enabled: !_isLoading,
              obscureText: _obscurePin,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '••••',
                counterText: '',
                prefixIcon: const Icon(Icons.dialpad_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (val) {
                if (val == null || val.trim().length != 4) {
                  return 'Please enter your 4-digit PIN';
                }
                return null;
              },
              onFieldSubmitted: (_) => _isLoading ? null : _onConfirm(),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _isLoading ? null : _onForgotPin,
                child: const Text('Forgot PIN?', style: TextStyle(fontSize: 12, color: AppColors.primary)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, null),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isDanger ? AppColors.error : AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: _isLoading ? null : _onConfirm,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
