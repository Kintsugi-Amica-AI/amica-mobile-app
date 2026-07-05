class Validators {
  const Validators._();

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredMessage = required(value, fieldName: 'Email');
    if (requiredMessage != null) {
      return requiredMessage;
    }
    final emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailPattern.hasMatch(value!.trim()) ? null : 'Enter a valid email';
  }

  static String? phone(String? value) {
    final requiredMessage = required(value, fieldName: 'Phone number');
    if (requiredMessage != null) {
      return requiredMessage;
    }
    final digits = value!.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 7 ? null : 'Enter a valid phone number';
  }
}
