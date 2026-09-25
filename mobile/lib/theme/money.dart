/// Formats Rand amounts the South African way: "R 12 400,00".
///
/// Thousands are grouped with a non-breaking space so an amount never wraps
/// across lines; the decimal separator is a comma.
String formatZar(num amount, {bool cents = true}) {
  const nbsp = ' ';
  final negative = amount < 0;
  final fixed = amount.abs().toStringAsFixed(cents ? 2 : 0);
  final parts = fixed.split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => nbsp,
  );
  final body = cents ? '$whole,${parts.last}' : whole;
  return '${negative ? '−' : ''}R$nbsp$body';
}
