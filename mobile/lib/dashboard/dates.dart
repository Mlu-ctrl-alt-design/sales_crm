const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// A date range the short South African way.
///
/// "Aug 2026" for a whole month, "1–27 Sep" within a month,
/// "1 Mar – 27 Sep" across months, with the year added when the range
/// isn't in [thisYear].
String rangeLabel(DateTime from, DateTime to, {int? thisYear}) {
  final year = thisYear ?? DateTime.now().year;
  final wholeMonth =
      from.day == 1 &&
      from.year == to.year &&
      from.month == to.month &&
      DateTime(to.year, to.month + 1, 0).day == to.day;
  if (wholeMonth) return '${_months[to.month - 1]} ${to.year}';

  final suffix = to.year == year ? '' : ' ${to.year}';
  if (from.year == to.year && from.month == to.month) {
    return '${from.day}–${to.day} ${_months[to.month - 1]}$suffix';
  }
  final fromYear = from.year == to.year ? '' : ' ${from.year}';
  return '${from.day} ${_months[from.month - 1]}$fromYear – '
      '${to.day} ${_months[to.month - 1]}$suffix';
}

/// "18:52" today, otherwise "27 Sep, 18:52".
String updatedLabel(DateTime at, DateTime now) {
  String two(int n) => n.toString().padLeft(2, '0');
  final time = '${two(at.hour)}:${two(at.minute)}';
  final sameDay =
      at.year == now.year && at.month == now.month && at.day == now.day;
  return sameDay ? time : '${at.day} ${_months[at.month - 1]}, $time';
}

/// "27 Aug", with the year when it isn't [thisYear].
String dayLabel(DateTime day, {int? thisYear}) {
  final year = thisYear ?? DateTime.now().year;
  return '${day.day} ${_months[day.month - 1]}'
      '${day.year == year ? '' : ' ${day.year}'}';
}
