class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Enter an email address';
    if (!value.contains('@')) return 'Enter a valid email';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
}