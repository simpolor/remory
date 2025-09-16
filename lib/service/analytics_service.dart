import 'package:remory/repository/analytics_repository.dart';

class AnalyticsService {
  final AnalyticsRepository analyticsRepository;

  AnalyticsService(this.analyticsRepository);

  Future<int> totalMemos() => analyticsRepository.totalMemos();

  Future<int> recent7Days() => analyticsRepository.recent7Days();

  Future<Map<String, dynamic>> recent30Days() => analyticsRepository.recent30Days();

  Future<List<Map<String, dynamic>>> topTags() => analyticsRepository.topTags();

  Future<List<Map<String, dynamic>>> topWeekdays() => analyticsRepository.topWeekdays();

  Future<List<Map<String, dynamic>>> topHours() => analyticsRepository.topHours();

  Future<Map<String, int>> streaks() => analyticsRepository.streaks();
}