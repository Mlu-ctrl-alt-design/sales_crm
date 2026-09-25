import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app.dart';
import 'auth/auth_repository.dart';
import 'config/env.dart';
import 'startup/app_status_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  assert(Env.siteUrl.isNotEmpty, 'Pass --dart-define=SITE_URL=https://...');
  final info = await PackageInfo.fromPlatform();
  runApp(DaystarApp(
    statusService: HttpAppStatusService(siteUrl: Env.siteUrl),
    auth: PendingMobileControlAuthRepository(),
    installedVersion: info.version,
  ));
}
