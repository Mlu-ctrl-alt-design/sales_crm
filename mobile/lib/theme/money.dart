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

/// [formatZar] for Rand; other currencies as "USD 1 234,50".
String formatMoney(num amount, String? currency) {
  if (currency == null || currency == 'ZAR') return formatZar(amount);
  return formatZar(amount).replaceFirst('R', currency);
}

/// A quantity without a pointless ",0": 2 → "2", 1.5 → "1,5".
String formatQty(num qty) {
  if (qty == qty.roundToDouble()) return qty.toInt().toString();
  return qty.toString().replaceFirst('.', ',');
}
