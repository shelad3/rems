class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    if (value.length < 10) return 'Enter a valid phone number';
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? number(String? value, [String field = 'This field']) {
    if (value == null || value.isEmpty) return '$field is required';
    if (double.tryParse(value) == null) return 'Enter a valid number';
    return null;
  }

  static String? positiveNumber(String? value, [String field = 'This field']) {
    final numVal = double.tryParse(value ?? '');
    if (numVal == null) return 'Enter a valid number';
    if (numVal <= 0) return '$field must be greater than 0';
    return null;
  }
}
