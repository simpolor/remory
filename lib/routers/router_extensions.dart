import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension GoRouterStateExtensions on GoRouterState {
  /// int param을 가져오되, 없으면 이전 화면으로 자동 이동 (또는 홈으로)
  int getIntParamOrGoBack(BuildContext context, String key, {String fallbackPath = '/'}) {
    final raw = pathParameters[key];
    final id = int.tryParse(raw ?? '');
    if (id == null) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(fallbackPath);
      }
      throw Exception('Invalid param: $key');
    }
    return id;
  }
}