import 'package:daystar_sales/startup/version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compares numerically, not lexically', () {
    expect(compareVersions('1.2.10', '1.2.9'), greaterThan(0));
    expect(compareVersions('1.2', '1.2.0'), 0);
    expect(compareVersions('0.9.9', '1.0.0'), lessThan(0));
  });

  test('ignores build metadata and pre-release tags', () {
    expect(compareVersions('1.0.0+42', '1.0.0'), 0);
    expect(compareVersions('1.0.0-beta', '1.0.0'), 0);
  });
}
