import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'api/api_client.dart';
import 'app.dart';
import 'auth/biometric_lock.dart';
import 'auth/device_prefs.dart';
import 'auth/key_value_store.dart';
import 'auth/mobile_control_auth.dart';
import 'auth/token_store.dart';
import 'config/env.dart';
import 'quick_send/quick_send_api.dart';
import 'startup/app_status_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final info = await PackageInfo.fromPlatform();
  final store = SecureKeyValueStore();
  final auth = MobileControlAuthRepository(
    siteUrl: Env.siteUrl,
    tokens: TokenStore(store),
  );
  final api = ApiClient(siteUrl: Env.siteUrl, accessToken: auth.accessToken);
  runApp(
    DaystarApp(
      statusService: HttpAppStatusService(siteUrl: Env.siteUrl),
      auth: auth,
      prefs: SecureDevicePrefs(),
      biometrics: LocalAuthBiometricLock(),
      installedVersion: info.version,
      quickSend: HttpQuickSendApi(api),
      drafts: store,
    ),
  );
}
