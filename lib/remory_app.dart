import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/data/seed/seed_provider.dart';
import 'package:remory/routers/app_router.dart';
import 'package:remory/widgets/error_snackbar_listener.dart';

class RemoryApp extends ConsumerWidget {
  const RemoryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbInitState = ref.watch(dbInitProvider);

    return dbInitState.when(
      data: (_) {
        return ErrorSnackBarListener(
          child: MaterialApp.router(
            routerConfig: appRouter,
            title: 'Remory',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'NotoSans',
              // 추가적인 텍스트 테마 설정 (선택사항)
              textTheme: Theme.of(context).textTheme.apply(
                fontFamily: 'NotoSans',
              ),
            ),
          ),
        );
      },
      loading: () {
        return MaterialApp(
          theme: ThemeData(fontFamily: 'NotoSans'),
          home: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
      error: (error, stack) {
        return MaterialApp(
          theme: ThemeData(fontFamily: 'NotoSans'),
          home: Scaffold(
            body: Center(child: Text('DB 초기화 실패: $error')),
          ),
        );
      },
    );
  }
}