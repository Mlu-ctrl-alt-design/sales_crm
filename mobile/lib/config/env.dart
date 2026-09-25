/// Build-time configuration, passed with `--dart-define`.
///
///   flutter run --dart-define=SITE_URL=https://staging.example.com
class Env {
  /// The Daystar ERPNext site. Override for staging or a local bench.
  static const siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: 'https://crm.thedaystar.co.za',
  );

  /// Must match `package_name` on the site's Mobile Configuration.
  static const packageName = 'za.co.thedaystar.daystar_sales';
}
