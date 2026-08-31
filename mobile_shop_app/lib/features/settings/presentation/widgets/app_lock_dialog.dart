import 'package:flutter/material.dart';
import '../../../../core/storage/preferences_storage.dart';
import '../../../../core/theme/app_colors.dart';

class AppLockDialog extends StatefulWidget {
  final bool isCurrentlyEnabled;

  const AppLockDialog({super.key, required this.isCurrentlyEnabled});

  @override
  State<AppLockDialog> createState() => _AppLockDialogState();
}

class _AppLockDialogState extends State<AppLockDialog> {
  final PreferencesStorage _prefs = PreferencesStorage();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _toggleLock(bool enable) async {
    if (!enable) {
      await _prefs.setAppLockEnabled(false);
      if (mounted) Navigator.pop(context, false);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    await _prefs.saveAppLockPin(_pinController.text.trim());
    await _prefs.setAppLockEnabled(true);

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App Lock enabled successfully with 4-digit PIN!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.security_rounded, color: AppColors.primary),
          SizedBox(width: 10),
          Text('App Security Lock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: widget.isCurrentlyEnabled
            ? const Text('App Lock is currently ENABLED. Would you like to disable it?')
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Protect your shop app with a 4-digit security PIN upon app open.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Set 4-Digit PIN',
                        prefixIcon: Icon(Icons.pin_outlined, size: 20),
                        counterText: '',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length != 4 || int.tryParse(v) == null) {
                          return 'Enter a valid 4-digit numeric PIN';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPinController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm 4-Digit PIN',
                        prefixIcon: Icon(Icons.check_circle_outline, size: 20),
                        counterText: '',
                      ),
                      validator: (v) {
                        if (v != _pinController.text) {
                          return 'PINs do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _toggleLock(!widget.isCurrentlyEnabled),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isCurrentlyEnabled ? AppColors.error : AppColors.primary,
            minimumSize: const Size(100, 40),
          ),
          child: Text(widget.isCurrentlyEnabled ? 'Disable' : 'Enable Lock'),
        ),
      ],
    );
  }
}
