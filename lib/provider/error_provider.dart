import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/core/error_handler.dart';

// 글로벌 에러 상태 관리
final globalErrorProvider = StateProvider<AppError?>((ref) => null);

// 에러 핸들링을 위한 Mixin
mixin ErrorHandlerMixin {
  void handleProviderError(
    dynamic error,
    StackTrace stackTrace, {
    ErrorType? type,
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    ErrorHandler().handleError(
      error,
      stackTrace: stackTrace,
      type: type,
      context: context,
      additionalData: additionalData,
    );
  }
}

// AsyncValue 확장 - 에러 처리 자동화
extension AsyncValueErrorHandling<T> on AsyncValue<T> {
  AsyncValue<T> handleErrors({
    ErrorType? errorType,
    String? context,
  }) {
    return when(
      data: (data) => AsyncValue.data(data),
      loading: () => const AsyncValue.loading(),
      error: (error, stackTrace) {
        // 자동 에러 처리
        ErrorHandler().handleError(
          error,
          stackTrace: stackTrace,
          type: errorType,
          context: context,
        );
        return AsyncValue.error(error, stackTrace);
      },
    );
  }
}

// 에러 알림을 위한 Provider
class ErrorNotificationNotifier extends StateNotifier<AppError?> {
  ErrorNotificationNotifier() : super(null) {
    // ErrorHandler 리스너 등록
    ErrorHandler().addListener(_onError);
  }

  void _onError(AppError error) {
    // UI에 표시할 중요한 에러만 필터링
    if (_shouldShowToUser(error)) {
      state = error;
    }
  }

  bool _shouldShowToUser(AppError error) {
    // 사용자에게 보여줄 에러 필터링 로직
    switch (error.type) {
      case ErrorType.network:
      case ErrorType.permission:
      case ErrorType.database:
        return true;
      case ErrorType.unknown:
        // 심각한 에러만 표시
        return error.code != null;
      case ErrorType.fileSystem:
        return false; // 파일시스템 에러는 백그라운드에서만 처리
    }
  }

  void clearError() {
    state = null;
  }

  @override
  void dispose() {
    ErrorHandler().removeListener(_onError);
    super.dispose();
  }
}

final errorNotificationProvider = 
    StateNotifierProvider<ErrorNotificationNotifier, AppError?>((ref) {
  return ErrorNotificationNotifier();
});
