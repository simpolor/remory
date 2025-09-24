import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/remory_app.dart';
import 'package:remory/service/notification_service.dart';
import 'package:remory/core/error_handler.dart';
import 'package:remory/core/provider_interceptor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 글로벌 에러 핸들러 설정
  await _setupErrorHandling();

  await NotificationService.I.init();

  runApp(
    ProviderScope(
      observers: [ErrorInterceptorObserver()], // 🎯 이게 진짜 AOP!
      child: RemoryApp(),
    ),
  );
}

Future<void> _setupErrorHandling() async {
  // Flutter 프레임워크 에러 처리
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorHandler().handleError(
      details.exception,
      stackTrace: details.stack,
      context: 'Flutter Framework Error',
      additionalData: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );
  };

  // 플랫폼 에러 처리 (네이티브 코드)
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    ErrorHandler().handleError(
      error,
      stackTrace: stackTrace,
      context: 'Platform Error',
    );
    return true;
  };

  // Zone 에러 처리 (비동기 에러)
  runZonedGuarded(
    () {
      // 메인 앱 실행
    },
    (error, stackTrace) {
      ErrorHandler().handleError(
        error,
        stackTrace: stackTrace,
        context: 'Zone Error',
      );
    },
  );
}

