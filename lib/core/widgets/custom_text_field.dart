import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final bool readOnly;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool isRequired;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final bool hasError;
  final String? errorText;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.readOnly = false,
    this.onChanged,
    this.maxLines = 1,
    this.isRequired = false,
    this.onTap,
    this.inputFormatters,
    this.hasError = false,
    this.errorText,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFieldInError = widget.hasError || (widget.errorText != null && widget.errorText!.isNotEmpty);
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final labelColor = isFieldInError
        ? AppColors.error
        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary);

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
          inputFormatters: widget.inputFormatters,
          obscureText: widget.isPassword ? _obscureText : false,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          validator: widget.validator,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
          decoration: InputDecoration(
            hintText: effectiveHint,
            errorText: widget.errorText,
            errorStyle: const TextStyle(color: AppColors.error, fontSize: 11.5, fontWeight: FontWeight.w500),
            enabledBorder: isFieldInError
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                  )
                : null,
            focusedBorder: isFieldInError
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error, width: 2.0),
                  )
                : null,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.normal),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    size: 20,
                    color: isFieldInError ? AppColors.error : AppColors.primary,
                  )
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
                : widget.suffixIcon,
          ),
        ),
      ],
    );
  }
}