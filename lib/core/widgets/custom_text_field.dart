import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    required this.label,
    super.key,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.minLines,
    this.maxLines = 1,
    this.helperText,
  });

  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final int? minLines;
  final int maxLines;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      minLines: minLines,
      maxLines: obscureText ? 1 : maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      cursorColor: AppColors.secondary,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: AppColors.textSecondary, size: 20),
      ),
    );
  }
}
