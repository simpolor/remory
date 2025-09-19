import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remory/provider/db_provider.dart';
import 'package:remory/provider/memo_provider.dart';
import 'package:remory/provider/tag_provider.dart';
import 'package:remory/repository/backup_repository.dart';
import 'package:remory/service/backup_service.dart';

final backupRepositoryProvider = Provider((ref) {
  final db = ref.watch(dbProvider);
  final memoRepository = ref.watch(memoRepositoryProvider);
  final tagRepository = ref.watch(tagRepositoryProvider);

  return BackupRepository(db, memoRepository, tagRepository);
});

final backupServiceProvider = Provider((ref) {
  final db = ref.watch(dbProvider);
  final backupService = ref.watch(backupRepositoryProvider);
  return BackupService(db, backupService);
});

// 백업 생성 Provider
final createBackupProvider = Provider<Future<String> Function()>((ref) {
  final backupService = ref.read(backupServiceProvider);
  
  return () async {
    final file = await backupService.createAndShareBackup();
    return '백업이 생성되었습니다: ${file.path}';
  };
});

// 백업 복원 Provider
final restoreBackupProvider = Provider<Future<String> Function()>((ref) {
  final backupService = ref.read(backupServiceProvider);
  
  return () async {
    final success = await backupService.pickAndRestoreBackup();
    if (success) {
      // 모든 관련 Provider 새로고침
      ref.invalidate(memoPagedProvider);
      ref.invalidate(tagPagedProvider);
      return '복원이 완료되었습니다';
    } else {
      return '복원이 취소되었습니다';
    }
  };
});
