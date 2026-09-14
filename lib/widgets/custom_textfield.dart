import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Themed text field used across auth and form screens.
class CustomTextField extends StatefulWidget {
  final String label;
  final bool isPassword;
  final IconData? icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.label,
    this.isPassword = false,
    this.icon,
    this.controller,
    this.keyboardType,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscure : false,
      keyboardType: widget.keyboardType,
      style: AppText.body,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: widget.icon != null
            ? Icon(widget.icon, color: AppColors.textSecondary, size: 20)
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}
