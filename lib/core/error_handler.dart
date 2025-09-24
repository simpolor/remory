import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:remory/core/error_context_collector.dart';
import 'package:remory/core/error_analyzer.dart';

// 에러 타입 정의
enum ErrorType {
  database,
  network,
  permission,
  fileSystem,
  unknown,
}

// 공통 에러 모델
class AppError {
  final String message;
  final ErrorType type;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic>? context;

  AppError({
    required this.message,
    required this.type,
    this.code,
    this.originalError,
    this.stackTrace,
    DateTime? timestamp,
    this.context,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'message': message,
    'type': type.name,
    'code': code,
    'timestamp': timestamp.toIso8601String(),
    'context': context,
  };
}

class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 5,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  // 에러 리스너들
  final List<void Function(AppError)> _listeners = [];

  void addListener(void Function(AppError) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(AppError) listener) {
    _listeners.remove(listener);
  }

  // 공통 에러 처리 메소드
  Future<void> handleError(
    dynamic error, {
    StackTrace? stackTrace,
    ErrorType? type,
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    // 🎯 상세 컨텍스트 수집
    final errorContext = await ErrorContextCollector.instance.collectErrorContext(
      additionalContext: context,
      customData: additionalData,
    );

    final appError = _createAppError(
      error,
      stackTrace: stackTrace,
      type: type,
      context: context,
      additionalData: errorContext,
    );

    // 🎯 에러 분석기에 추가
    ErrorAnalyzer.instance.addError(appError);

    // 로깅
    _logError(appError);

    // Firebase Crashlytics 전송 (프로덕션에서만)
    if (kReleaseMode) {
      await _sendToCrashlytics(appError);
    }

    // 리스너들에게 알림
    for (final listener in _listeners) {
      try {
        listener(appError);
      } catch (e) {
        _logger.e('Error in error listener: $e');
      }
    }
  }

  AppError _createAppError(
    dynamic error, {
    StackTrace? stackTrace,
    ErrorType? type,
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    String message;
    ErrorType errorType = type ?? ErrorType.unknown;
    String? errorCode;

    // 에러 타입별 분류
    if (error is SocketException) {
      message = '네트워크 연결을 확인해주세요';
      errorType = ErrorType.network;
      errorCode = 'NETWORK_ERROR';
    } else if (error is FileSystemException) {
      message = '파일 작업 중 오류가 발생했습니다';
      errorType = ErrorType.fileSystem;
      errorCode = 'FILE_SYSTEM_ERROR';
    } else if (error is StateError) {
      message = '상태 오류가 발생했습니다';
      errorType = ErrorType.unknown;
      errorCode = 'STATE_ERROR';
    } else if (error.toString().contains('database')) {
      message = '데이터 처리 중 오류가 발생했습니다';
      errorType = ErrorType.database;
      errorCode = 'DATABASE_ERROR';
    } else {
      message = error.toString();
    }

    final contextData = <String, dynamic>{
      if (context != null) 'context': context,
      if (additionalData != null) ...additionalData,
      'platform': Platform.operatingSystem,
      'buildMode': kReleaseMode ? 'release' : (kDebugMode ? 'debug' : 'profile'),
    };

    return AppError(
      message: message,
      type: errorType,
      code: errorCode,
      originalError: error,
      stackTrace: stackTrace,
      context: contextData,
    );
  }

  void _logError(AppError appError) {
    switch (appError.type) {
      case ErrorType.database:
        _logger.e('🗄️ Database Error: ${appError.message}',
            error: appError.originalError, stackTrace: appError.stackTrace);
        break;
      case ErrorType.network:
        _logger.e('🌐 Network Error: ${appError.message}',
            error: appError.originalError, stackTrace: appError.stackTrace);
        break;
      case ErrorType.permission:
        _logger.w('🔒 Permission Error: ${appError.message}',
            error: appError.originalError, stackTrace: appError.stackTrace);
        break;
      case ErrorType.fileSystem:
        _logger.e('📁 FileSystem Error: ${appError.message}',
            error: appError.originalError, stackTrace: appError.stackTrace);
        break;
      case ErrorType.unknown:
      default:
        _logger.e('❌ Unknown Error: ${appError.message}',
            error: appError.originalError, stackTrace: appError.stackTrace);
    }
  }

  Future<void> _sendToCrashlytics(AppError appError) async {
    try {
      // Firebase Crashlytics 연동 코드
      // final crashlytics = FirebaseCrashlytics.instance;
      
      // await crashlytics.setCustomKey('error_type', appError.type.name);
      // await crashlytics.setCustomKey('error_code', appError.code ?? 'unknown');
      // if (appError.context != null) {
      //   for (final entry in appError.context!.entries) {
      //     await crashlytics.setCustomKey(entry.key, entry.value.toString());
      //   }
      // }
      
      // await crashlytics.recordError(
      //   appError.originalError ?? appError.message,
      //   appError.stackTrace,
      //   fatal: false,
      // );
      
      _logger.d('Error sent to Crashlytics: ${appError.code}');
    } catch (e) {
      _logger.e('Failed to send error to Crashlytics: $e');
    }
  }

  // 사용자 피드백용 메시지 생성
  String getUserMessage(AppError error) {
    switch (error.type) {
      case ErrorType.database:
        return '데이터 처리 중 문제가 발생했습니다. 다시 시도해주세요.';
      case ErrorType.network:
        return '인터넷 연결을 확인하고 다시 시도해주세요.';
      case ErrorType.permission:
        return '필요한 권한이 없습니다. 설정에서 권한을 확인해주세요.';
      case ErrorType.fileSystem:
        return '파일 작업 중 오류가 발생했습니다.';
      case ErrorType.unknown:
      default:
        return '예상치 못한 오류가 발생했습니다. 다시 시도해주세요.';
    }
  }
}
