bool isToday(DateTime now, DateTime date) =>
    date.year == now.year && date.month == now.month && date.day == now.day;

bool isYesterday(DateTime now, DateTime date) {
  final yesterday = now.subtract(const Duration(days: 1));
  return date.year == yesterday.year &&
      date.month == yesterday.month &&
      date.day == yesterday.day;
}

bool isThisWeek(DateTime now, DateTime date) {
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  return date.isAfter(startOfWeek);
}

bool isThisMonth(DateTime now, DateTime date) =>
    date.year == now.year && date.month == now.month;

String formatSimpleDateTime(DateTime? dateTime) {
  if (dateTime == null) return '알 수 없음';

  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
}