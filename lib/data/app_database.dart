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
  int get schemaVersion => 2; // 버전 증가

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      /*await m.createAll(); // 테이블 + (위에 선언한 indexes)까지 반영

      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_memos_created_at_id ON memos(created_at, memo_id)');
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_tags_name_tag_id ON tags(name, tag_id)');*/
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
      // 태그 AND/OR 필터용 (교차 테이블)
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_memo_tags_tag_id ON memo_tags(tag_id)'
      );
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_memo_tags_memo_id ON memo_tags(memo_id)'
      );

      // 3) FTS5 가상 테이블 (외부 콘텐츠 모드)
      await customStatement(
          "CREATE VIRTUAL TABLE IF NOT EXISTS memos_fts USING fts5("
              "  title, "
              "  content='memos', "
              "  content_rowid='memo_id', "
              "  tokenize='unicode61'"
              ")"
      );

      // 4) 동기화 트리거 (INSERT/DELETE/UPDATE(title) 시 색인 갱신)
      await customStatement('DROP TRIGGER IF EXISTS memos_ai');
      await customStatement('DROP TRIGGER IF EXISTS memos_ad');
      await customStatement('DROP TRIGGER IF EXISTS memos_au');

      await customStatement(
          'CREATE TRIGGER memos_ai AFTER INSERT ON memos BEGIN '
              '  INSERT INTO memos_fts(rowid, title) VALUES (new.memo_id, new.title); '
              'END;'
      );
      await customStatement(
          'CREATE TRIGGER memos_ad AFTER DELETE ON memos BEGIN '
              "  INSERT INTO memos_fts(memos_fts, rowid) VALUES('delete', old.memo_id); "
              'END;'
      );
      await customStatement(
          'CREATE TRIGGER memos_au AFTER UPDATE OF title ON memos '
              'WHEN old.title IS NOT new.title BEGIN '
              "  INSERT INTO memos_fts(memos_fts, rowid) VALUES('delete', old.memo_id); "
              '  INSERT INTO memos_fts(rowid, title) VALUES (new.memo_id, new.title); '
              'END;'
      );

      // 5) (선택) 초기 색인 채우기 — 첫 설치는 비어있겠지만, idempotent하게
      await customStatement('DELETE FROM memos_fts');
      await customStatement(
          'INSERT INTO memos_fts(rowid, title) '
              'SELECT memo_id, title FROM memos'
      );

      // (선택) FTS 최적화
      await customStatement("INSERT INTO memos_fts(memos_fts) VALUES('optimize')");
    },
    beforeOpen: (details) async {
      //await customStatement('PRAGMA foreign_keys = ON');

      await customStatement('PRAGMA foreign_keys = ON');
      // 권장: WAL 모드(동시성·안정성)
      // await customStatement('PRAGMA journal_mode = WAL');
      // await customStatement('PRAGMA synchronous = NORMAL');
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
