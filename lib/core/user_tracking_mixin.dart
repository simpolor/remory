import 'package:flutter/material.dart';
import 'package:remory/core/error_context_collector.dart';

/// 화면과 사용자 액션을 자동 추적하는 Mixin
mixin UserTrackingMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    
    // 화면 진입 추적
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenName = widget.runtimeType.toString().replaceAll('Screen', '');
      ErrorContextCollector.instance.setCurrentScreen(screenName);
    });
  }

  /// 사용자 액션 기록 (버튼 클릭, 검색 등)
  void trackUserAction(String action, [Map<String, dynamic>? params]) {
    ErrorContextCollector.instance.recordUserAction(action, params);
  }

  /// 데이터 로딩 시작/종료 추적
  void trackDataOperation(String operation, {bool isStart = true}) {
    final action = isStart ? '${operation}_start' : '${operation}_end';
    trackUserAction(action);
  }
}

/// HookConsumerWidget용 확장
extension UserTrackingExtension on ErrorContextCollector {
  void trackScreenEntry(String screenName) {
    setCurrentScreen(screenName);
  }
  
  void trackButtonTap(String buttonName, [Map<String, dynamic>? context]) {
    recordUserAction('button_tap', {'button': buttonName, ...?context});
  }
  
  void trackSearch(String query, [String? category]) {
    recordUserAction('search', {
      'query': query,
      if (category != null) 'category': category,
    });
  }
  
  void trackItemAction(String action, String itemType, [dynamic itemId]) {
    recordUserAction(action, {
      'item_type': itemType,
      if (itemId != null) 'item_id': itemId.toString(),
    });
  }
}
