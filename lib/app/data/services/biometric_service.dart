import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:methna_app/app/data/services/storage_service.dart';

/// Service for biometric (fingerprint / face) authentication.
class BiometricService extends GetxService {
  final LocalAuthentication _auth = LocalAuthentication();
  final StorageService _storage = Get.find<StorageService>();

  final RxBool isAvailable = false.obs;
  final RxBool isEnabled = false.obs;
  final RxList<BiometricType> availableTypes = <BiometricType>[].obs;
  final RxString lastError = ''.obs;

  Future<BiometricService> init() async {
    try {
      lastError.value = '';
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      isAvailable.value = canCheck && isSupported;

      if (isAvailable.value) {
        availableTypes.value = await _auth.getAvailableBiometrics();
        if (availableTypes.isEmpty) {
          isAvailable.value = false;
          lastError.value = 'not_enrolled';
        }
      }

      // Restore user preference
      isEnabled.value =
          _storage.getBool('security_biometric') ??
          (_storage.getBool('biometric_enabled') ?? false);
    } catch (_) {
      isAvailable.value = false;
      lastError.value = 'not_available';
    }
    return this;
  }

  /// Enable or disable biometric login.
  Future<void> setEnabled(bool value) async {
    if (value && !isAvailable.value) return;
    isEnabled.value = value;
    await _storage.saveBool('biometric_enabled', value);
    await _storage.saveBool('security_biometric', value);
  }

  /// Prompt the user for biometric authentication.
  /// Returns `true` if authentication succeeded.
  Future<bool> authenticate({
    String reason = 'Verify your identity',
    bool requireEnabled = true,
  }) async {
    if (!isAvailable.value) {
      lastError.value = 'not_available';
      return false;
    }
    if (requireEnabled && !isEnabled.value) {
      lastError.value = 'not_enabled';
      return false;
    }

    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      lastError.value = authenticated ? '' : 'cancelled';
      return authenticated;
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('notenrolled') || code.contains('not_enrolled')) {
        lastError.value = 'not_enrolled';
      } else if (code.contains('notavailable') || code.contains('not_available')) {
        lastError.value = 'not_available';
      } else if (code.contains('passcode') || code.contains('credential')) {
        lastError.value = 'passcode_not_set';
      } else if (code.contains('lockedout') || code.contains('locked_out')) {
        lastError.value = 'locked_out';
      } else if (code.contains('cancel') || code.contains('user')) {
        lastError.value = 'cancelled';
      } else {
        lastError.value = 'auth_failed';
      }
      return false;
    } catch (_) {
      lastError.value = 'auth_failed';
      return false;
    }
  }

  String get failureMessage {
    switch (lastError.value) {
      case 'not_enrolled':
        return 'No biometric credentials enrolled. Go to device Settings > Security to add fingerprint or face.';
      case 'passcode_not_set':
        return 'Set a device screen lock (PIN/pattern/password) before enabling biometric lock.';
      case 'not_enabled':
        return 'Enable biometric lock first.';
      case 'not_available':
        return 'This device does not support biometric authentication.';
      case 'locked_out':
        return 'Too many failed attempts. Try again later or use your device PIN.';
      case 'cancelled':
        return 'Biometric authentication was cancelled.';
      case 'auth_failed':
        return 'Biometric authentication failed. Please try again.';
      default:
        return 'Biometric authentication failed. Please try again.';
    }
  }

  /// Returns a human-readable label for the primary biometric type.
  String get biometricLabel {
    if (availableTypes.contains(BiometricType.face)) return 'Face ID';
    if (availableTypes.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (availableTypes.contains(BiometricType.iris)) return 'Iris';
    return 'Biometric';
  }
}
