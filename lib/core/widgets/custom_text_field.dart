import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final bool readOnly;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool isRequired;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.prefixIcon,
    this.validator,
    this.readOnly = false,
    this.onChanged,
    this.maxLines = 1,
    this.isRequired = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final labelColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final cleanLabel = widget.label.replaceAll('*', '').replaceAll('(', '').replaceAll(')', '').replaceAll('₹', '').trim();
    final isDecimalNumber = widget.keyboardType == const TextInputType.numberWithOptions(decimal: true) ||
        widget.keyboardType == const TextInputType.numberWithOptions(signed: true, decimal: true);
    final isNumber = widget.keyboardType == TextInputType.number;

    final String effectiveHint = widget.hint ??
        (isDecimalNumber
            ? '0.00'
            : isNumber
                ? '0'
                : 'Enter $cleanLabel...');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: labelColor,
              letterSpacing: 0.1,
              fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
            ),
            children: widget.isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword ? _obscureText : false,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          readOnly: widget.readOnly,
          onChanged: widget.onChanged,
          validator: widget.validator,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
          decoration: InputDecoration(
            hintText: effectiveHint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.normal),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20, color: AppColors.primary)
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}