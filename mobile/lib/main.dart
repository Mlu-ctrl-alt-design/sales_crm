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
import 'dashboard/dashboard_api.dart';
import 'quick_send/quick_send_api.dart';
import 'sales/sales_api.dart';
import 'startup/app_status_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final info = await PackageInfo.fromPlatform();
  final store = SecureKeyValueStore();
  final tokens = TokenStore(store);
  final auth = MobileControlAuthRepository(
    siteUrl: Env.siteUrl,
    tokens: tokens,
  );
  final api = ApiClient(siteUrl: Env.siteUrl, accessToken: auth.accessToken);
  runApp(
    DaystarApp(
      statusService: HttpAppStatusService(siteUrl: Env.siteUrl),
      auth: auth,
      prefs: SecureDevicePrefs(),
      biometrics: LocalAuthBiometricLock(),
      installedVersion: info.version,
      dashboard: HttpDashboardApi(
        api,
        store: store,
        currentUser: () async => (await tokens.load())?.user,
      ),
      quickSend: HttpQuickSendApi(api),
      sales: HttpSalesApi(api),
      drafts: store,
    ),
  );
}
