import 'package:flutter/material.dart';

class AppBarConfig {
  final String title;
  final bool showBackButton;
  final List<Widget> actions;

  const AppBarConfig({
    required this.title,
    this.showBackButton = false,
    this.actions = const [],
  });
}