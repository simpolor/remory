import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/presentation/models/analytics_model.dart';
import 'package:remory/provider/db_provider.dart';
import 'package:remory/repository/analytics_repository.dart';
import 'package:remory/service/analytics_service.dart';

final analyticsRepositoryProvider = Provider((ref) {
  final db = ref.watch(dbProvider);
  return AnalyticsRepository(db);
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final repository = ref.watch(analyticsRepositoryProvider);
  return AnalyticsService(repository);
});

final analyticsProvider = FutureProvider<AnalyticsModel>((ref) async {
  final service = ref.read(analyticsServiceProvider);

  final total = await service.totalMemos();
  final recent7 = await service.recent7Days();
  final recent30 = await service.recent30Days();

  final topTagsRaw = await service.topTags();
  final topWeekdaysRaw = await service.topWeekdays();
  final topHoursRaw = await service.topHours();
  final streaksRaw = await service.streaks();

  return AnalyticsModel(
    totalMemos: total,
    recent7DaysCount: recent7,
    recent30DaysCount: recent30['count'] ?? 0,
    topTags: topTagsRaw.map((e) => TagUsageModel(name: e['name'], count: e['count'])).toList(),
    topWeekdays: topWeekdaysRaw.map((e) => WeekdayUsageModel(weekday: (e['weekday']), count: e['count'])).toList(),
    topHours: topHoursRaw.map((e) => HourUsageModel(hour: (e['hour']), count: e['count'])).toList(),
    streaks: StreakModel(
      maxStreak: streaksRaw['maxStreak'] ?? 0,
      currentStreak: streaksRaw['currentStreak'] ?? 0,
    ),
  );
});