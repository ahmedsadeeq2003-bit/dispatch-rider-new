import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final bool isPassword;
  final IconData? icon;

  const CustomTextField({
    super.key,
    required this.label,
    this.isPassword = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
