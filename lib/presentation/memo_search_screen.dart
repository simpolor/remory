import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:remory/presentation/layouts/app_scaffold.dart';
import 'package:remory/presentation/layouts/app_bar_config.dart';

class MemoSearchScreen extends HookConsumerWidget {
  const MemoSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return AppScaffold(
      appBar: AppBarConfig(
        title: '타임라인',
        showBackButton: true,
        actions: [],
      ),
      child: Text('text'),
    );
  }
}
