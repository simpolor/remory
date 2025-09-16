import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/data/seed/seed_provider.dart';
import 'package:remory/routers/app_router.dart';

class RemoryApp extends ConsumerWidget {
  const RemoryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbInitState = ref.watch(dbInitProvider);

    return dbInitState.when(
      data: (_) {
        return MaterialApp.router(
          routerConfig: appRouter,
        );
      },
      loading: () {
        return const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
      error: (error, stack) {
        return MaterialApp(
          home: Scaffold(
            body: Center(child: Text('DB 초기화 실패: $error')),
          ),
        );
      },
    );
  }
}