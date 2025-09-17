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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll(); // 테이블 + (위에 선언한 indexes)까지 반영

      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_memos_created_at_id ON memos(created_at, memo_id)');
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_tags_name_tag_id ON tags(name, tag_id)');
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
