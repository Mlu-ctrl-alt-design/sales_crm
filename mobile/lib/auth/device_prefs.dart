import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small per-device settings for sign-in.
abstract class DevicePrefs {
  Future<String?> lastEmail();
  Future<void> setLastEmail(String email);

  /// Whether opening the app asks for Face ID / fingerprint first.
  Future<bool> biometricUnlock();
  Future<void> setBiometricUnlock(bool enabled);

  /// Whether we've already asked; we ask once, after the first sign-in.
  Future<bool> biometricOffered();
  Future<void> setBiometricOffered();
}

class SecureDevicePrefs implements DevicePrefs {
  SecureDevicePrefs([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _emailKey = 'last_email';
  static const _unlockKey = 'biometric_unlock';
  static const _offeredKey = 'biometric_offered';

  @override
  Future<String?> lastEmail() => _storage.read(key: _emailKey);

  @override
  Future<void> setLastEmail(String email) =>
      _storage.write(key: _emailKey, value: email);

  @override
  Future<bool> biometricUnlock() async =>
      await _storage.read(key: _unlockKey) == '1';

  @override
  Future<void> setBiometricUnlock(bool enabled) =>
      _storage.write(key: _unlockKey, value: enabled ? '1' : '0');

  @override
  Future<bool> biometricOffered() async =>
      await _storage.read(key: _offeredKey) == '1';

  @override
  Future<void> setBiometricOffered() =>
      _storage.write(key: _offeredKey, value: '1');
}
