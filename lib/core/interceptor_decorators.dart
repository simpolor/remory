import 'dart:async';
import 'package:remory/core/error_handler.dart';
import 'package:remory/core/performance_monitor.dart';

/// 함수를 자동으로 래핑하는 데코레이터들
class Interceptors {
  
  /// 에러 핸들링 + 성능 모니터링을 자동으로 적용
  static Future<T> withMonitoring<T>(
    String operationName,
    Future<T> Function() operation, {
    ErrorType? errorType,
    Map<String, dynamic>? context,
  }) async {
    final perfMonitor = PerformanceMonitor();
    final errorHandler = ErrorHandler();
    
    perfMonitor.startMeasurement(operationName);
    
    try {
      final result = await operation();
      perfMonitor.endMeasurement(operationName);
      return result;
      
    } catch (error, stackTrace) {
      perfMonitor.endMeasurement(operationName);
      
      await errorHandler.handleError(
        error,
        stackTrace: stackTrace,
        type: errorType ?? _inferErrorType(error),
        context: operationName,
        additionalData: context,
      );
      
      rethrow;
    }
  }

  /// 동기 함수용
  static T withMonitoringSync<T>(
    String operationName,
    T Function() operation, {
    ErrorType? errorType,
    Map<String, dynamic>? context,
  }) {
    final perfMonitor = PerformanceMonitor();
    final errorHandler = ErrorHandler();
    
    perfMonitor.startMeasurement(operationName);
    
    try {
      final result = operation();
      perfMonitor.endMeasurement(operationName);
      return result;
      
    } catch (error, stackTrace) {
      perfMonitor.endMeasurement(operationName);
      
      errorHandler.handleError(
        error,
        stackTrace: stackTrace,
        type: errorType ?? _inferErrorType(error),
        context: operationName,
        additionalData: context,
      );
      
      rethrow;
    }
  }

  static ErrorType _inferErrorType(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('database') || errorStr.contains('sqlite')) {
      return ErrorType.database;
    } else if (errorStr.contains('network') || errorStr.contains('socket')) {
      return ErrorType.network;
    } else if (errorStr.contains('permission')) {
      return ErrorType.permission;
    } else if (errorStr.contains('file')) {
      return ErrorType.fileSystem;
    }
    
    return ErrorType.unknown;
  }
}

/// Annotation 스타일 데코레이터 (미래 확장용)
class Monitor {
  final String operationName;
  final ErrorType? errorType;
  
  const Monitor(this.operationName, {this.errorType});
}

/// 확장 함수로 더 쉽게 사용
extension FutureInterceptor<T> on Future<T> {
  Future<T> withAutoMonitoring(
    String operationName, {
    ErrorType? errorType,
    Map<String, dynamic>? context,
  }) {
    return Interceptors.withMonitoring(
      operationName,
      () => this,
      errorType: errorType,
      context: context,
    );
  }
}

extension FunctionInterceptor<T> on T Function() {
  T withAutoMonitoring(
    String operationName, {
    ErrorType? errorType,
    Map<String, dynamic>? context,
  }) {
    return Interceptors.withMonitoringSync(
      operationName,
      this,
      errorType: errorType,
      context: context,
    );
  }
}
