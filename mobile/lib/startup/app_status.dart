import 'version.dart';

/// What the app is allowed to do right now, from Mobile Configuration.
enum AppGate { open, disabled, maintenance, updateRequired }

/// The public subset of the site's Mobile Configuration.
class AppStatus {
  const AppStatus({
    required this.enabled,
    required this.maintenanceMode,
    this.maintenanceMessage,
    this.minimumAppVersion,
  });

  final bool enabled;
  final bool maintenanceMode;
  final String? maintenanceMessage;
  final String? minimumAppVersion;

  factory AppStatus.fromJson(Map<String, dynamic> json) => AppStatus(
        enabled: _truthy(json['enabled']),
        maintenanceMode: _truthy(json['maintenance_mode']),
        maintenanceMessage: _blankToNull(json['maintenance_message']),
        minimumAppVersion: _blankToNull(json['minimum_app_version']),
      );

  /// Disabled wins over maintenance, and maintenance over an outdated build,
  /// so the user always sees the most fundamental reason first.
  AppGate evaluate(String installedVersion) {
    if (!enabled) return AppGate.disabled;
    if (maintenanceMode) return AppGate.maintenance;
    final minimum = minimumAppVersion;
    if (minimum != null && compareVersions(installedVersion, minimum) < 0) {
      return AppGate.updateRequired;
    }
    return AppGate.open;
  }

  static bool _truthy(Object? v) => v == true || v == 1 || v == '1';

  static String? _blankToNull(Object? v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }
}
