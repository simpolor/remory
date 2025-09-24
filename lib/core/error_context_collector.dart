import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 에러 발생 시점의 상황을 상세히 수집하는 클래스 (경량 버전)
class ErrorContextCollector {
  static ErrorContextCollector? _instance;
  static ErrorContextCollector get instance {
    _instance ??= ErrorContextCollector._();
    return _instance!;
  }
  ErrorContextCollector._();

  // 현재 사용자 행동 추적
  String? _currentScreen;
  String? _lastUserAction;
  Map<String, dynamic> _userSession = {};
  List<UserAction> _userActionHistory = [];

  /// 현재 화면 등록
  void setCurrentScreen(String screenName) {
    _currentScreen = screenName;
    _addUserAction('navigate_to', {'screen': screenName});
  }

  /// 사용자 액션 기록
  void recordUserAction(String action, [Map<String, dynamic>? params]) {
    _lastUserAction = action;
    _addUserAction(action, params);
  }

  /// 세션 정보 업데이트
  void updateSession(Map<String, dynamic> sessionData) {
    _userSession.addAll(sessionData);
  }

  void _addUserAction(String action, [Map<String, dynamic>? params]) {
    _userActionHistory.add(UserAction(
      action: action,
      timestamp: DateTime.now(),
      params: params,
    ));

    // 최근 20개 액션만 유지
    if (_userActionHistory.length > 20) {
      _userActionHistory.removeAt(0);
    }
  }

  /// 에러 발생 시점의 전체 컨텍스트 수집
  Future<Map<String, dynamic>> collectErrorContext({
    String? additionalContext,
    Map<String, dynamic>? customData,
  }) async {
    return {
      // 🎯 사용자 행동 컨텍스트
      'user_context': {
        'current_screen': _currentScreen,
        'last_action': _lastUserAction,
        'recent_actions': _userActionHistory.take(5).map((a) => a.toJson()).toList(),
        'session_data': _userSession,
      },

      // 🎯 앱 상태 정보
      'app_context': {
        'build_mode': kReleaseMode ? 'release' : (kDebugMode ? 'debug' : 'profile'),
        'dart_version': Platform.version,
      },

      // 🎯 디바이스 환경 (기본 정보만)
      'device_context': {
        'platform': Platform.operatingSystem,
        'platform_version': Platform.operatingSystemVersion,
        'dart_version': Platform.version.split(' ').first,
      },

      // 🎯 시스템 상태
      'system_context': {
        'platform': Platform.operatingSystem,
        'locale': Platform.localeName,
        'environment': Platform.environment.keys.length,
      },

      // 🎯 추가 컨텍스트
      if (additionalContext != null) 'additional_context': additionalContext,
      if (customData != null) 'custom_data': customData,

      // 🎯 메타데이터
      'collection_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 디버깅용 현재 상태 출력
  void printCurrentState() {
    print('🔍 Current Error Context:');
    print('  Screen: $_currentScreen');
    print('  Last Action: $_lastUserAction');
    print('  Recent Actions: ${_userActionHistory.length}');
    print('  Session Keys: ${_userSession.keys}');
  }
}

class UserAction {
  final String action;
  final DateTime timestamp;
  final Map<String, dynamic>? params;

  UserAction({
    required this.action,
    required this.timestamp,
    this.params,
  });

  Map<String, dynamic> toJson() => {
    'action': action,
    'timestamp': timestamp.toIso8601String(),
    'params': params,
  };
}
