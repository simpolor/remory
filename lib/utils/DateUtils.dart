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