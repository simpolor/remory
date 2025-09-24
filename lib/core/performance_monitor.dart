import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 성능 모니터링 클래스
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Logger _logger = Logger();
  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<int>> _measurements = {};

  /// 작업 시작 시간 기록
  void startMeasurement(String operationName) {
    _startTimes[operationName] = DateTime.now();
  }

  /// 작업 종료 및 성능 측정
  void endMeasurement(String operationName) {
    final startTime = _startTimes.remove(operationName);
    if (startTime == null) {
      _logger.w('No start time found for operation: $operationName');
      return;
    }

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    
    // 측정값 저장
    _measurements.putIfAbsent(operationName, () => []).add(duration);
    
    // 느린 작업 경고
    if (duration > 1000) {
      _logger.w('⚠️ Slow operation detected: $operationName took ${duration}ms');
    } else if (duration > 500) {
      _logger.i('⏱️ Operation: $operationName took ${duration}ms');
    }

    // 개발 모드에서만 상세 로그
    if (kDebugMode) {
      _logger.d('📊 $operationName: ${duration}ms');
    }
  }

  /// 함수 실행 시간 측정 유틸리티
  Future<T> measureAsync<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startMeasurement(operationName);
    try {
      final result = await operation();
      endMeasurement(operationName);
      return result;
    } catch (e) {
      endMeasurement(operationName);
      _logger.e('Error in measured operation $operationName: $e');
      rethrow;
    }
  }

  /// 동기 함수 실행 시간 측정
  T measureSync<T>(
    String operationName,
    T Function() operation,
  ) {
    startMeasurement(operationName);
    try {
      final result = operation();
      endMeasurement(operationName);
      return result;
    } catch (e) {
      endMeasurement(operationName);
      _logger.e('Error in measured operation $operationName: $e');
      rethrow;
    }
  }

  /// 성능 통계 조회
  Map<String, PerformanceStats> getStatistics() {
    final stats = <String, PerformanceStats>{};
    
    for (final entry in _measurements.entries) {
      final measurements = entry.value;
      if (measurements.isNotEmpty) {
        final sorted = List<int>.from(measurements)..sort();
        final avg = measurements.reduce((a, b) => a + b) / measurements.length;
        
        stats[entry.key] = PerformanceStats(
          operationName: entry.key,
          count: measurements.length,
          average: avg.round(),
          min: sorted.first,
          max: sorted.last,
          p50: sorted[(sorted.length * 0.5).floor()],
          p95: sorted[(sorted.length * 0.95).floor()],
        );
      }
    }
    
    return stats;
  }

  /// 통계 초기화
  void clearStatistics() {
    _measurements.clear();
    _startTimes.clear();
  }

  /// 성능 리포트 생성
  String generateReport() {
    final stats = getStatistics();
    if (stats.isEmpty) return 'No performance data available';

    final buffer = StringBuffer();
    buffer.writeln('📊 Performance Report');
    buffer.writeln('=' * 50);
    
    final sortedStats = stats.values.toList()
      ..sort((a, b) => b.average.compareTo(a.average));
    
    for (final stat in sortedStats) {
      buffer.writeln('${stat.operationName}:');
      buffer.writeln('  Count: ${stat.count}');
      buffer.writeln('  Average: ${stat.average}ms');
      buffer.writeln('  Min/Max: ${stat.min}ms / ${stat.max}ms');
      buffer.writeln('  P50/P95: ${stat.p50}ms / ${stat.p95}ms');
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}

/// 성능 통계 모델
class PerformanceStats {
  final String operationName;
  final int count;
  final int average;
  final int min;
  final int max;
  final int p50;
  final int p95;

  PerformanceStats({
    required this.operationName,
    required this.count,
    required this.average,
    required this.min,
    required this.max,
    required this.p50,
    required this.p95,
  });

  Map<String, dynamic> toJson() => {
    'operationName': operationName,
    'count': count,
    'average': average,
    'min': min,
    'max': max,
    'p50': p50,
    'p95': p95,
  };
}

/// 성능 측정을 위한 Mixin
mixin PerformanceMonitorMixin {
  final PerformanceMonitor _monitor = PerformanceMonitor();

  Future<T> measurePerformance<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    return _monitor.measureAsync(operationName, operation);
  }

  T measurePerformanceSync<T>(
    String operationName,
    T Function() operation,
  ) {
    return _monitor.measureSync(operationName, operation);
  }
}
