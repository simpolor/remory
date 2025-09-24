import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/core/env.dart';
import 'package:remory/core/error_handler.dart';
import 'package:remory/core/performance_monitor.dart';
import 'package:remory/data/seed/seed_repository.dart';
import 'package:remory/data/seed/seed_source_assets.dart';
import 'package:remory/provider/db_provider.dart';
import 'package:remory/provider/memo_provider.dart';
import 'package:remory/provider/memo_tag_provider.dart';
import 'package:remory/provider/tag_provider.dart';

final seedRepositoryProvider = Provider<SeedRepository>((ref) {
  final db = ref.read(dbProvider);
  final memoRepository = ref.read(memoRepositoryProvider);
  final tagRepository = ref.read(tagRepositoryProvider);
  final memoTagRepository = ref.read(memoTagRepositoryProvider);

  return SeedRepository(db, memoRepository, tagRepository, memoTagRepository);
});

final dbInitProvider = FutureProvider<void>((ref) async {
  return await PerformanceMonitor().measureAsync('dbInit', () async {
    try {
      // const env = String.fromEnvironment('APP_ENV', defaultValue: 'prod');
      // if (env != 'local') return; // local에서만
      if(!Env.isLocal) return;

      final seedRepo = ref.read(seedRepositoryProvider);
      final source = SeedSourceAssets();
      final bundle = await source.load();

      await seedRepo.reset();
      await seedRepo.write(bundle);
    } catch (error, stackTrace) {
      await ErrorHandler().handleError(
        error,
        stackTrace: stackTrace,
        type: ErrorType.database,
        context: 'Database Initialization',
        additionalData: {
          'isLocal': Env.isLocal,
        },
      );
      rethrow;
    }
  });
});