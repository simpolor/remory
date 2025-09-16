import 'package:drift/drift.dart';
import 'package:remory/data/tables/memo_table.dart'; // class Memos extends Table
import 'package:remory/data/tables/tag_table.dart';  // class Tags extends Table

class MemoTags extends Table {
  /// memos.memo_id 참조 (삭제 시 연쇄 삭제)
  IntColumn get memoId =>
      integer().references(Memos, #memoId, onDelete: KeyAction.cascade)();

  /// tags.tag_id 참조 (삭제 시 연쇄 삭제)
  IntColumn get tagId =>
      integer().references(Tags, #tagId, onDelete: KeyAction.cascade)();

  /// 메모 상세 내 태그 노출 정렬용 (기본 0)
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 복합 기본키 (중복 연결 방지)
  @override
  Set<Column> get primaryKey => {memoId, tagId};
}