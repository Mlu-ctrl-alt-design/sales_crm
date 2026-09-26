import 'package:flutter/foundation.dart';

/// Which Daystar site the app talks to.
///
/// Development and profile builds use staging; release builds use the live
/// site. Override either with `--dart-define=SITE_URL=https://...` (for
/// example a local bench).
class Env {
  static const liveUrl = 'https://crm.thedaystar.co.za';
  static const stagingUrl = 'https://crm-staging.thedaystar.co.za';

  static const _override = String.fromEnvironment('SITE_URL');

  static String get siteUrl =>
      _override.isNotEmpty ? _override : (kReleaseMode ? liveUrl : stagingUrl);

  /// Must match `package_name` on the site's Mobile Configuration.
  static const packageName = 'za.co.thedaystar.daystar_sales';
}
