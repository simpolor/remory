import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/core/error_handler.dart';
import 'package:remory/core/performance_monitor.dart';

/// Riverpod Provider들을 자동으로 인터셉트하는 클래스
class ErrorInterceptorObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    // 모든 Provider 에러를 자동 캐치!
    ErrorHandler().handleError(
      error,
      stackTrace: stackTrace,
      type: _classifyError(error),
      context: 'Provider: ${provider.name ?? provider.runtimeType.toString()}',
      additionalData: {
        'provider_type': provider.runtimeType.toString(),
        'provider_name': provider.name,
      },
    );
    
    super.providerDidFail(provider, error, stackTrace, container);
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    // 성능 모니터링도 가능
    if (provider.name != null) {
      PerformanceMonitor().endMeasurement('provider_${provider.name}');
    }
    super.didUpdateProvider(provider, previousValue, newValue, container);
  }

  ErrorType _classifyError(Object error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('database') || 
        errorString.contains('sqlite') ||
        errorString.contains('drift')) {
      return ErrorType.database;
    } else if (errorString.contains('network') || 
               errorString.contains('socket') ||
               errorString.contains('http')) {
      return ErrorType.network;
    } else if (errorString.contains('permission')) {
      return ErrorType.permission;
    } else if (errorString.contains('file') || errorString.contains('path')) {
      return ErrorType.fileSystem;
    }
    
    return ErrorType.unknown;
  }
}
