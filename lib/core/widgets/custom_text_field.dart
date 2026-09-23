import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A labelled field. Styling lives in `inputDecorationTheme`; this adds the
/// label-above-the-field arrangement the redesign uses, which keeps the
/// label readable while typing instead of shrinking it into the border.
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
    this.hintText,
    this.textInputAction,
    this.onFieldSubmitted,
    this.enabled = true,
    this.onClear,
    this.clearTooltip,
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
  final String? hintText;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final bool enabled;

  /// When set, a round ✕ appears at the end of the field whenever it has
  /// text; tapping it runs this (which should clear the controller and
  /// anything tied to the value, e.g. a map pin). Needs [controller].
  final VoidCallback? onClear;
  final String? clearTooltip;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: c.plum70,
          ),
        ),
        const SizedBox(height: 7),
        _withClearButton(
          (suffix) => TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            minLines: minLines,
            maxLines: obscureText ? 1 : maxLines,
            enabled: enabled,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            style: TextStyle(color: c.plum, fontSize: 15),
            cursorColor: c.plum,
            decoration: InputDecoration(
              hintText: hintText,
              helperText: helperText,
              prefixIcon: prefixIcon == null
                  ? null
                  : Icon(prefixIcon, color: c.plum45, size: 19),
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }

  /// Rebuilds only the field (not the label) as the text changes, so the ✕
  /// shows exactly when there is something to clear.
  Widget _withClearButton(Widget Function(Widget? suffix) build) {
    final controller = this.controller;
    final onClear = this.onClear;
    if (controller == null || onClear == null) return build(null);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (value.text.isEmpty || !enabled) return build(null);
        final c = Theme.of(context).amica;
        return build(
          IconButton(
            tooltip: clearTooltip ??
                MaterialLocalizations.of(context).deleteButtonTooltip,
            onPressed: onClear,
            icon: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.accentSoft,
              ),
              child: Icon(Icons.close_rounded, size: 16, color: c.accentInk),
            ),
          ),
        );
      },
    );
  }
}
