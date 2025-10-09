/// Email validator
/// Returns null if valid, error message if invalid
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }

  // Regular expression for email validation
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  if (!emailRegex.hasMatch(value)) {
    return 'Enter a valid email address';
  }

  return null;
}

/// Password validator (US24 requirements)
/// Returns null if valid, error message if invalid
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }

  if (value.length < 8) {
    return 'Password must be at least 8 characters';
  }

  // Check for special character
  if (!value.contains(RegExp(r'[!@#$%^&*(),.?":[]|<>]'))) {
    return 'Password must contain a special character';
  }

  // Check for uppercase letter
  if(!value.contains(RegExp(r'[A-Z]'))) {
    return 'Password must contain an uppercase letter';
  }

  // Check for number
  if (!value.contains(RegExp(r'[0-9]'))) {
    return 'Password must contain a number';
  }

  return null;
}

String? requiredText(String? v, {String label = 'Field'}) {
  if (v == null || v.trim().isEmpty) return '$label is required';
  return null;
}

String? phone(String? v) {
  if (v == null || v.trim().isEmpty) return 'Phone is required';
  final onlyDigits = v.replaceAll(RegExp(r'[^0-9+]'), '');
  if (onlyDigits.length < 8) return 'Enter a valid phone number';
  return null;
}