/// Compares dotted numeric versions ("1.2.10" vs "1.2.9").
///
/// Build metadata after `+` and pre-release tags after `-` are ignored.
/// Missing or non-numeric parts count as 0.
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .split('+')
      .first
      .split('-')
      .first
      .split('.')
      .map((p) => int.tryParse(p.trim()) ?? 0)
      .toList();

  final pa = parts(a);
  final pb = parts(b);
  final length = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < length; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}
