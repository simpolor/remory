import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:remory/data/tables/memo_table.dart';
import 'package:remory/data/tables/tag_table.dart';
import 'package:remory/data/tables/memo_tag_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Memos, Tags, MemoTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1; // 🎯 깔끔하게 버전 1로 단순화

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      // 1) 테이블 생성 (Drift가 생성)
      await m.createAll();

      // 2) 일반 인덱스 (정렬/조인/필터 최적화)
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_memos_created_at_id '
              'ON memos(created_at, memo_id)'
      );
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_tags_name_tag_id '
              'ON tags(name, tag_id)'
      );
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_memo_tags_tag_memo '
              'ON memo_tags(tag_id, memo_id)'
      );
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_memo_tags_memo_tag '
              'ON memo_tags(memo_id, tag_id)'
      );

      // 3) 🗑️ 휴지통 관련 인덱스 (deletedAt 기반)
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_memos_deleted_at '
              'ON memos(deleted_at)'
      );
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_memos_deleted_created_at '
              'ON memos(deleted_at, created_at)'
      );

      // 4) FTS5 가상 테이블 (외부 콘텐츠 모드)
      await customStatement(
          "CREATE VIRTUAL TABLE IF NOT EXISTS memos_fts USING fts5("
              "  title, "
              "  content='memos', "
              "  content_rowid='memo_id', "
              "  tokenize='unicode61', "
              "  prefix='2 3 4'"
              ")"
      );

      // 5) FTS 동기화 트리거 (deletedAt 기반으로 삭제되지 않은 메모만 색인)
      await customStatement(
          'CREATE TRIGGER memos_ai '
          'AFTER INSERT ON memos '
          'WHEN new.deleted_at IS NULL '
          'BEGIN '
          '  INSERT INTO memos_fts(rowid, title) VALUES (new.memo_id, new.title); '
          'END;'
      );
      await customStatement(
          'CREATE TRIGGER memos_ad '
          'AFTER DELETE ON memos '
          'BEGIN '
          "  INSERT INTO memos_fts(memos_fts, rowid, title) VALUES('delete', old.memo_id, old.title); "
          'END;'
      );
      await customStatement(
          'CREATE TRIGGER memos_au '
          'AFTER UPDATE ON memos '
          'WHEN (old.title <> new.title OR old.deleted_at IS NOT new.deleted_at) '
          'BEGIN '
          "  INSERT INTO memos_fts(memos_fts, rowid, title) VALUES('delete', old.memo_id, old.title); "
          '  INSERT INTO memos_fts(rowid, title) '
          '  SELECT new.memo_id, new.title WHERE new.deleted_at IS NULL; '
          'END;'
      );

      // 6) 초기 FTS 색인 (삭제되지 않은 메모만)
      await customStatement(
          'INSERT INTO memos_fts(rowid, title) '
          'SELECT memo_id, title FROM memos WHERE deleted_at IS NULL'
      );

      // 7) FTS 최적화
      await customStatement("INSERT INTO memos_fts(memos_fts) VALUES('optimize')");
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'remory.db'));
    return NativeDatabase(file);
  });
}
