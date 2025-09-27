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
              colorScheme: ColorScheme.fromSeed(
                seedColor: Color(0xFF546E7A), // 블루-그레이
                brightness: Brightness.light,
              ),
              inputDecorationTheme: InputDecorationTheme(
                errorStyle: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
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
          theme: ThemeData(
            fontFamily: 'NotoSans',
            colorScheme: ColorScheme.fromSeed(
              seedColor: Color(0xFF546E7A), // 블루-그레이
              brightness: Brightness.light,
            ),
            inputDecorationTheme: InputDecorationTheme(
              errorStyle: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
          home: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
      error: (error, stack) {
        return MaterialApp(
          theme: ThemeData(
            fontFamily: 'NotoSans',
            colorScheme: ColorScheme.fromSeed(
              seedColor: Color(0xFF546E7A), // 블루-그레이
              brightness: Brightness.light,
            ),
            inputDecorationTheme: InputDecorationTheme(
              errorStyle: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
          home: Scaffold(
            body: Center(child: Text('DB 초기화 실패: $error')),
          ),
        );
      },
    );
  }
}