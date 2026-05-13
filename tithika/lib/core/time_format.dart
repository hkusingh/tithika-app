String formatLocalTime(DateTime utc, Duration tzOffset) {
  final local = utc.add(tzOffset);
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final m = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '$h:$m $period';
}

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const _monthNamesShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String gregorianMonthName(int month) => _monthNames[month - 1];

/// Returns e.g. "May 12 6:42 AM" — used for tithi start/end times where
/// the date context is needed because the window can span midnight.
String formatLocalDatetime(DateTime utc, Duration tzOffset) {
  final local = utc.add(tzOffset);
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final m = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  final mon = _monthNamesShort[local.month - 1];
  return '$mon ${local.day} $h:$m $period';
}
