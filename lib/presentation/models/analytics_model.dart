class AnalyticsModel {
  final int totalMemos;
  final int recent7DaysCount;
  final int recent30DaysCount;
  final List<TagUsageModel> topTags;
  final List<WeekdayUsageModel> topWeekdays;
  final List<HourUsageModel> topHours;
  final StreakModel streaks;

  AnalyticsModel({
    required this.totalMemos,
    required this.recent7DaysCount,
    required this.recent30DaysCount,
    required this.topTags,
    required this.topWeekdays,
    required this.topHours,
    required this.streaks,
  });
}

class TagUsageModel {
  final String name;
  final int count;

  TagUsageModel({required this.name, required this.count});
}

class WeekdayUsageModel {
  final int weekday; // 0=일요일 .. 6=토요일
  final int count;

  WeekdayUsageModel({required this.weekday, required this.count});
}

class HourUsageModel {
  final int hour; // 0~23
  final int count;

  HourUsageModel({required this.hour, required this.count});
}

class StreakModel {
  final int maxStreak;
  final int currentStreak;

  StreakModel({required this.maxStreak, required this.currentStreak});
}