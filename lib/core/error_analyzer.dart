import 'dart:collection';
import 'package:remory/core/error_handler.dart';

/// 에러 패턴 분석 및 인사이트 제공
class ErrorAnalyzer {
  static final ErrorAnalyzer _instance = ErrorAnalyzer._();
  static ErrorAnalyzer get instance => _instance;
  ErrorAnalyzer._();

  final List<AppError> _errorHistory = [];
  final Map<String, int> _errorFrequency = HashMap();
  final Map<String, DateTime> _firstOccurrence = HashMap();
  final Map<String, DateTime> _lastOccurrence = HashMap();

  void addError(AppError error) {
    _errorHistory.add(error);
    
    // 에러 키 생성 (같은 종류의 에러 그룹핑)
    final errorKey = '${error.type.name}:${error.code ?? 'unknown'}:${_getLocationKey(error)}';
    
    _errorFrequency[errorKey] = (_errorFrequency[errorKey] ?? 0) + 1;
    _firstOccurrence[errorKey] ??= error.timestamp;
    _lastOccurrence[errorKey] = error.timestamp;

    // 메모리 관리: 최근 1000개만 유지
    if (_errorHistory.length > 1000) {
      _errorHistory.removeAt(0);
    }
  }

  String _getLocationKey(AppError error) {
    final context = error.context;
    if (context != null && context['context'] != null) {
      return context['context'].toString().split('.').last; // 마지막 메소드명만
    }
    return 'unknown';
  }

  /// 🎯 실용적인 에러 분석 리포트 생성
  ErrorAnalysisReport generateReport() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final last7Days = now.subtract(const Duration(days: 7));

    final recent24HErrors = _errorHistory.where((e) => e.timestamp.isAfter(last24Hours)).toList();
    final recent7DErrors = _errorHistory.where((e) => e.timestamp.isAfter(last7Days)).toList();

    return ErrorAnalysisReport(
      totalErrors: _errorHistory.length,
      last24HoursErrors: recent24HErrors.length,
      last7DaysErrors: recent7DErrors.length,
      
      // 🔥 가장 빈번한 에러들
      topErrors: _getTopErrors(5),
      
      // 📈 에러 트렌드
      errorTrend: _calculateTrend(recent7DErrors),
      
      // 🎯 심각한 패턴들
      criticalPatterns: _detectCriticalPatterns(),
      
      // 💡 개선 제안
      recommendations: _generateRecommendations(),
      
      // 📊 에러 타입별 분포
      errorsByType: _getErrorsByType(),
      
      // 🔍 최근 에러 상세
      recentErrors: _errorHistory.take(10).toList(),
    );
  }

  List<ErrorFrequencyInfo> _getTopErrors(int limit) {
    return _errorFrequency.entries
        .map((entry) => ErrorFrequencyInfo(
              errorKey: entry.key,
              frequency: entry.value,
              firstSeen: _firstOccurrence[entry.key]!,
              lastSeen: _lastOccurrence[entry.key]!,
            ))
        .toList()
      ..sort((a, b) => b.frequency.compareTo(a.frequency))
      ..take(limit);
  }

  Map<ErrorType, int> _getErrorsByType() {
    final result = <ErrorType, int>{};
    for (final error in _errorHistory) {
      result[error.type] = (result[error.type] ?? 0) + 1;
    }
    return result;
  }

  String _calculateTrend(List<AppError> recentErrors) {
    if (recentErrors.length < 2) return '데이터 부족';
    
    final now = DateTime.now();
    final midPoint = now.subtract(const Duration(days: 3, hours: 12));
    
    final firstHalf = recentErrors.where((e) => e.timestamp.isBefore(midPoint)).length;
    final secondHalf = recentErrors.where((e) => e.timestamp.isAfter(midPoint)).length;
    
    if (secondHalf > firstHalf * 1.5) return '🔺 증가 추세';
    if (firstHalf > secondHalf * 1.5) return '🔻 감소 추세';
    return '➡️ 안정적';
  }

  List<String> _detectCriticalPatterns() {
    final patterns = <String>[];
    
    // 패턴 1: 같은 에러가 짧은 시간에 반복
    for (final entry in _errorFrequency.entries) {
      if (entry.value >= 10) {
        final timeDiff = _lastOccurrence[entry.key]!.difference(_firstOccurrence[entry.key]!);
        if (timeDiff.inHours < 1) {
          patterns.add('⚠️ "${entry.key}" 에러가 1시간 내 ${entry.value}회 발생');
        }
      }
    }
    
    // 패턴 2: 특정 화면에서 에러 집중
    final screenErrors = <String, int>{};
    for (final error in _errorHistory) {
      final screen = error.context?['user_context']?['current_screen'];
      if (screen != null) {
        screenErrors[screen] = (screenErrors[screen] ?? 0) + 1;
      }
    }
    
    final problematicScreen = screenErrors.entries
        .where((e) => e.value > _errorHistory.length * 0.3)
        .map((e) => '🎯 "${e.key}" 화면에서 에러 집중 (${e.value}건)')
        .toList();
    patterns.addAll(problematicScreen);
    
    return patterns;
  }

  List<String> _generateRecommendations() {
    final recommendations = <String>[];
    
    final dbErrors = _errorHistory.where((e) => e.type == ErrorType.database).length;
    final networkErrors = _errorHistory.where((e) => e.type == ErrorType.network).length;
    
    if (dbErrors > _errorHistory.length * 0.4) {
      recommendations.add('💾 데이터베이스 에러가 많습니다. 연결 풀 설정이나 쿼리 최적화를 검토하세요.');
    }
    
    if (networkErrors > _errorHistory.length * 0.3) {
      recommendations.add('🌐 네트워크 에러가 빈번합니다. 재시도 로직이나 오프라인 모드를 고려하세요.');
    }
    
    // 에러 빈도가 높은 기능 식별
    final highFrequencyErrors = _errorFrequency.entries
        .where((e) => e.value > 5)
        .map((e) => e.key)
        .toList();
        
    if (highFrequencyErrors.isNotEmpty) {
      recommendations.add('🔧 다음 기능들의 안정성 개선 필요: ${highFrequencyErrors.take(3).join(", ")}');
    }
    
    return recommendations;
  }

  /// 특정 에러의 상세 분석
  ErrorDetailAnalysis analyzeSpecificError(String errorKey) {
    final relatedErrors = _errorHistory
        .where((e) => '${e.type.name}:${e.code}:${_getLocationKey(e)}' == errorKey)
        .toList();
    
    if (relatedErrors.isEmpty) {
      return ErrorDetailAnalysis(
        errorKey: errorKey,
        occurrences: 0,
        patterns: [],
        userActions: [],
        devicePatterns: [],
      );
    }
    
    // 사용자 액션 패턴 분석
    final userActionPatterns = <String, int>{};
    final devicePatterns = <String, int>{};
    
    for (final error in relatedErrors) {
      final userContext = error.context?['user_context'];
      if (userContext != null) {
        final lastAction = userContext['last_action'];
        if (lastAction != null) {
          userActionPatterns[lastAction] = (userActionPatterns[lastAction] ?? 0) + 1;
        }
      }
      
      final deviceContext = error.context?['device_context'];
      if (deviceContext != null) {
        final model = deviceContext['model'];
        if (model != null) {
          devicePatterns[model] = (devicePatterns[model] ?? 0) + 1;
        }
      }
    }
    
    return ErrorDetailAnalysis(
      errorKey: errorKey,
      occurrences: relatedErrors.length,
      patterns: _identifyPatterns(relatedErrors),
      userActions: userActionPatterns.entries
          .map((e) => '${e.key} (${e.value}회)')
          .toList(),
      devicePatterns: devicePatterns.entries
          .map((e) => '${e.key} (${e.value}회)')
          .toList(),
    );
  }

  List<String> _identifyPatterns(List<AppError> errors) {
    final patterns = <String>[];
    
    // 시간대 패턴
    final hourCounts = <int, int>{};
    for (final error in errors) {
      final hour = error.timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    
    final peakHour = hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    if (peakHour.value > errors.length * 0.3) {
      patterns.add('${peakHour.key}시경에 집중 발생');
    }
    
    return patterns;
  }
}

// 분석 결과 모델들
class ErrorAnalysisReport {
  final int totalErrors;
  final int last24HoursErrors;
  final int last7DaysErrors;
  final List<ErrorFrequencyInfo> topErrors;
  final String errorTrend;
  final List<String> criticalPatterns;
  final List<String> recommendations;
  final Map<ErrorType, int> errorsByType;
  final List<AppError> recentErrors;

  ErrorAnalysisReport({
    required this.totalErrors,
    required this.last24HoursErrors,
    required this.last7DaysErrors,
    required this.topErrors,
    required this.errorTrend,
    required this.criticalPatterns,
    required this.recommendations,
    required this.errorsByType,
    required this.recentErrors,
  });
}

class ErrorFrequencyInfo {
  final String errorKey;
  final int frequency;
  final DateTime firstSeen;
  final DateTime lastSeen;

  ErrorFrequencyInfo({
    required this.errorKey,
    required this.frequency,
    required this.firstSeen,
    required this.lastSeen,
  });
}

class ErrorDetailAnalysis {
  final String errorKey;
  final int occurrences;
  final List<String> patterns;
  final List<String> userActions;
  final List<String> devicePatterns;

  ErrorDetailAnalysis({
    required this.errorKey,
    required this.occurrences,
    required this.patterns,
    required this.userActions,
    required this.devicePatterns,
  });
}
