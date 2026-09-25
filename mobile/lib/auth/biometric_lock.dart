import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricKind { face, fingerprint, other }

/// What the user calls it on their phone.
String biometricName(BiometricKind kind, TargetPlatform platform) {
  final apple = platform == TargetPlatform.iOS;
  return switch (kind) {
    BiometricKind.face => apple ? 'Face ID' : 'face unlock',
    BiometricKind.fingerprint => apple ? 'Touch ID' : 'fingerprint',
    BiometricKind.other => 'biometrics',
  };
}

abstract class BiometricLock {
  /// The strongest enrolled biometric, or null if none can be used.
  Future<BiometricKind?> available();

  /// Shows the system prompt. False if cancelled, failed or locked out.
  Future<bool> unlock(String reason);
}

class LocalAuthBiometricLock implements BiometricLock {
  LocalAuthBiometricLock([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<BiometricKind?> available() async {
    try {
      if (!await _auth.isDeviceSupported() || !await _auth.canCheckBiometrics) {
        return null;
      }
      final types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) return BiometricKind.face;
      if (types.contains(BiometricType.fingerprint)) {
        return BiometricKind.fingerprint;
      }
      return types.isEmpty ? null : BiometricKind.other;
    } on Exception {
      return null;
    }
  }

  @override
  Future<bool> unlock(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false;
    }
  }
}
