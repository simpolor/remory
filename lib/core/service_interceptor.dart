import 'dart:async';
import 'package:remory/core/error_handler.dart';
import 'package:remory/core/performance_monitor.dart';

/// 서비스 메소드를 자동으로 래핑하는 인터셉터
class ServiceInterceptor {
  static T create<T>(T instance) {
    return _ServiceProxy<T>(instance) as T;
  }
}

class _ServiceProxy<T> {
  final T _target;
  final ErrorHandler _errorHandler = ErrorHandler();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  _ServiceProxy(this._target);

  @override
  dynamic noSuchMethod(Invocation invocation) async {
    final methodName = '${T.toString()}.${invocation.memberName.toString().replaceAll('Symbol("', '').replaceAll('")', '')}';
    
    // 성능 측정 시작
    _performanceMonitor.startMeasurement(methodName);
    
    try {
      final result = Function.apply(
        _target as Function, 
        invocation.positionalArguments, 
        invocation.namedArguments,
      );
      
      // Future인 경우 await하고 에러 처리
      if (result is Future) {
        return await result.catchError((error, stackTrace) {
          _handleError(error, stackTrace, methodName);
          throw error;
        });
      }
      
      _performanceMonitor.endMeasurement(methodName);
      return result;
      
    } catch (error, stackTrace) {
      _handleError(error, stackTrace, methodName);
      _performanceMonitor.endMeasurement(methodName);
      rethrow;
    }
  }

  void _handleError(dynamic error, StackTrace stackTrace, String methodName) {
    _errorHandler.handleError(
      error,
      stackTrace: stackTrace,
      type: _classifyErrorByService(),
      context: methodName,
      additionalData: {
        'service_type': T.toString(),
        'method': methodName,
      },
    );
  }

  ErrorType _classifyErrorByService() {
    final serviceName = T.toString().toLowerCase();
    
    if (serviceName.contains('memo') || serviceName.contains('tag') || serviceName.contains('database')) {
      return ErrorType.database;
    } else if (serviceName.contains('network') || serviceName.contains('api')) {
      return ErrorType.network;
    } else if (serviceName.contains('file') || serviceName.contains('backup')) {
      return ErrorType.fileSystem;
    }
    
    return ErrorType.unknown;
  }
}

/// 사용법을 위한 확장
extension ServiceInterceptorExtension<T> on T {
  T withInterceptor() {
    return ServiceInterceptor.create(this);
  }
}
