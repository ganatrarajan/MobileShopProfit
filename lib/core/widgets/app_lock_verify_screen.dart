import 'package:flutter/material.dart';
import '../storage/preferences_storage.dart';
import '../theme/app_colors.dart';
import 'app_logo.dart';

class AppLockVerifyScreen extends StatefulWidget {
  const AppLockVerifyScreen({super.key});

  @override
  State<AppLockVerifyScreen> createState() => _AppLockVerifyScreenState();
}

class _AppLockVerifyScreenState extends State<AppLockVerifyScreen> {
  final PreferencesStorage _prefs = PreferencesStorage();
  String _enteredPin = '';
  String? _errorMessage;

  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _errorMessage = null;
        _enteredPin += digit;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _errorMessage = null;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _onClear() {
    setState(() {
      _errorMessage = null;
      _enteredPin = '';
    });
  }

  Future<void> _verifyPin() async {
    final storedPin = await _prefs.getAppLockPin();
    if (storedPin != null && storedPin == _enteredPin) {
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = 'Incorrect PIN. Please try again.';
          _enteredPin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Logo & Header
            const AppLogo(size: AppLogoSize.large),
            const SizedBox(height: 24),
            const Text(
              'App Security Lock',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enter your 4-digit PIN to access Mobile Profits',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isFilled ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error),
              ),
            ],

            const Spacer(),

            // Numeric Keypad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: [
                  _buildKeyRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildKeyRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildKeyRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton('C', _onClear),
                      _buildNumberButton('0'),
                      _buildActionButton('⌫', _onBackspace),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildNumberButton(d)).toList(),
    );
  }

  Widget _buildNumberButton(String digit) {
    return InkWell(
      onTap: () => _onKeyPress(digit),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 68,
        height: 68,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
