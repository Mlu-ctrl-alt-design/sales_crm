import 'package:daystar_sales/theme/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String plain(String s) => s.replaceAll(' ', ' ');

  test('formats Rand the South African way', () {
    expect(plain(formatZar(12400)), 'R 12 400,00');
    expect(plain(formatZar(6578.5)), 'R 6 578,50');
    expect(plain(formatZar(999)), 'R 999,00');
    expect(plain(formatZar(1250000.456)), 'R 1 250 000,46');
  });

  test('whole Rand and negatives', () {
    expect(plain(formatZar(48250, cents: false)), 'R 48 250');
    expect(plain(formatZar(-138150)), '−R 138 150,00');
  });

  test('never breaks across lines', () {
    expect(formatZar(12400).contains(' '), isFalse);
  });
}
