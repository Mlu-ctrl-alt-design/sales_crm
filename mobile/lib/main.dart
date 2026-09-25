import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app.dart';
import 'auth/auth_repository.dart';
import 'auth/biometric_lock.dart';
import 'auth/device_prefs.dart';
import 'config/env.dart';
import 'startup/app_status_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final info = await PackageInfo.fromPlatform();
  runApp(
    DaystarApp(
      statusService: HttpAppStatusService(siteUrl: Env.siteUrl),
      auth: PendingMobileControlAuthRepository(),
      prefs: SecureDevicePrefs(),
      biometrics: LocalAuthBiometricLock(),
      installedVersion: info.version,
    ),
  );
}
