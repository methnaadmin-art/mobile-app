import 'package:get/get.dart';

class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'email_required'.tr;
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'email_invalid'.tr;
    return null;
  }

  static String? loginIdentifier(String? value) {
    if (value == null || value.isEmpty) return 'identifier_required'.tr;
    final normalized = value.trim().replaceAll(' ', '');
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    if (phoneRegex.hasMatch(normalized)) {
      return null;
    }
    // If it contains @, treat as email, else as username
    if (value.contains('@')) {
      return email(value);
    }
    // Else check as username
    if (value.length < 3) return 'username_min'.tr;
    final regex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!regex.hasMatch(value)) return 'username_format'.tr;
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'password_required'.tr;
    if (value.length < 8) return 'password_min_length'.tr;
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'password_uppercase'.tr;
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'password_lowercase'.tr;
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'password_number'.tr;
    return null;
  }

  static String? required(String? value, [String field = '']) {
    if (value == null || value.trim().isEmpty) {
      return 'field_required'.trParams({'field': field});
    }
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.isEmpty) return 'username_required'.tr;
    if (value.length < 3) return 'username_min'.tr;
    if (value.length > 20) return 'username_max'.tr;
    final regex = RegExp(r'^[a-zA-Z0-9_.]+$');
    if (!regex.hasMatch(value)) return 'username_format'.tr;
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'phone_required'.tr;
    final regex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!regex.hasMatch(value.replaceAll(' ', ''))) return 'phone_invalid'.tr;
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.isEmpty) return 'otp_required'.tr;
    if (value.length != 6) return 'otp_length'.tr;
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'name_required'.tr;
    if (value.trim().length < 2) return 'name_min'.tr;
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() getPassword) {
    return (String? value) {
      if (value == null || value.isEmpty) return 'confirm_password_required'.tr;
      if (value != getPassword()) return 'passwords_no_match'.tr;
      return null;
    };
  }
}
