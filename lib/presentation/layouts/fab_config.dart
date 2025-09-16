import 'package:flutter/material.dart';

class FabConfig {

  final IconData icon;      // FAB 아이콘
  final String route;       // 이동할 라우트
  final String? tooltip;    // 툴팁(옵션)

  const FabConfig({
    required this.icon,
    required this.route,
    this.tooltip,
  });
}