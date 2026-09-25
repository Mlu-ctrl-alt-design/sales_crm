import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app.dart';
import 'auth/biometric_lock.dart';
import 'auth/device_prefs.dart';
import 'auth/key_value_store.dart';
import 'auth/mobile_control_auth.dart';
import 'auth/token_store.dart';
import 'config/env.dart';
import 'startup/app_status_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final info = await PackageInfo.fromPlatform();
  runApp(
    DaystarApp(
      statusService: HttpAppStatusService(siteUrl: Env.siteUrl),
      auth: MobileControlAuthRepository(
        siteUrl: Env.siteUrl,
        tokens: TokenStore(SecureKeyValueStore()),
      ),
      prefs: SecureDevicePrefs(),
      biometrics: LocalAuthBiometricLock(),
      installedVersion: info.version,
    ),
  );
}
