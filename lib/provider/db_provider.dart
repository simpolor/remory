import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/data/app_database.dart';

// 앱이 종료할 때 한번만 부름
final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(); // Drift의 LazyDatabase면 생성만으로 OK
  ref.onDispose(() => db.close()); // ProviderScope dispose 시 안전하게 닫기
  return db;
});

