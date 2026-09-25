import 'package:daystar_sales/startup/app_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AppStatus status({
    bool enabled = true,
    bool maintenance = false,
    String? minimum,
  }) =>
      AppStatus(
        enabled: enabled,
        maintenanceMode: maintenance,
        minimumAppVersion: minimum,
      );

  test('parses Frappe check fields sent as 0/1', () {
    final s = AppStatus.fromJson({
      'enabled': 1,
      'maintenance_mode': 0,
      'maintenance_message': '  ',
      'minimum_app_version': '1.0.0',
    });
    expect(s.enabled, isTrue);
    expect(s.maintenanceMode, isFalse);
    expect(s.maintenanceMessage, isNull);
    expect(s.minimumAppVersion, '1.0.0');
  });

  test('open when enabled, no maintenance, version satisfied', () {
    expect(status(minimum: '1.0.0').evaluate('1.0.0'), AppGate.open);
    expect(status().evaluate('0.0.1'), AppGate.open);
  });

  test('disabled wins over everything', () {
    expect(
      status(enabled: false, maintenance: true, minimum: '9.0.0')
          .evaluate('1.0.0'),
      AppGate.disabled,
    );
  });

  test('maintenance wins over an outdated build', () {
    expect(
      status(maintenance: true, minimum: '9.0.0').evaluate('1.0.0'),
      AppGate.maintenance,
    );
  });

  test('blocks builds below the minimum version', () {
    expect(status(minimum: '1.2.0').evaluate('1.1.9'), AppGate.updateRequired);
  });
}
