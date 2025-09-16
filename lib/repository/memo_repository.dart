import 'package:remory/data/app_database.dart';
import 'package:drift/drift.dart';
import 'package:remory/repository/dtos/memo_with_tags_dto.dart';
import 'package:remory/provider/state/memo_cursor.dart';
import 'package:remory/repository/dtos/memo_dto.dart';
import 'package:remory/repository/dtos/tag_dto.dart';

class MemoRepository {
  final AppDatabase db;

  MemoRepository(this.db);

  Future<List<MemoDto>> fetchMemosWithAfter({
    MemoCursor? memoCursor,
    required int limit,
  }) async {
    final query = db.select(db.memos)
      ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(expression: tbl.memoId,    mode: OrderingMode.desc),
      ])
      ..limit(limit);

    // 즉, 두 파트가 필요해요:
    // 1. 더 오래된 시간(createdAt이 더 작음) 같은 시간대 안에서는 id로 타이브레이크(id가 더 작음)
    // 2. 그래서 같은 createdAt 안에서 id < cursor.id인 레코드가 없으면, 비록 더 오래된 createdAt 레코드들이 많이 남아 있어도 아예 못 가져옵니다.
    // t.createdAt.isSmallerThanValue(memoCursor.createdAt) 커서 시간보다 작거나 같은 거 조회
    // (t.createdAt.equals(memoCursor.createdAt) & t.memoId.isSmallerThanValue(memoCursor.id): 커서 시간과 같고, 커서 아이디보다 작거나 같은거
    if (memoCursor != null) {
      query.where((tbl) =>
        tbl.createdAt.isSmallerThanValue(memoCursor.createdAt) | // 1) 더 오래된 시간
        (tbl.createdAt.equals(memoCursor.createdAt) & // 2) 같은 시간대면 id로 더 작게
        tbl.memoId.isSmallerThanValue(memoCursor.id))
      );
    }

    final rows = await query.get();
    return rows.map(MemoDto.fromEntity).toList();
  }

  Future<MemoDto?> findMemoById(int memoId) async {
    final memo = await (
        db.select(db.memos)
          ..where((tbl) => tbl.memoId.equals(memoId))
    ).getSingleOrNull();

    if (memo == null) return null;

    return MemoDto.fromEntity(memo);
  }

  Future<MemoWithTagsDto?> fetchMemoWithTagsById(int memoId) async {
    final query = (db.select(db.memos)..where((m) => m.memoId.equals(memoId))).join([
      leftOuterJoin(db.memoTags, db.memoTags.memoId.equalsExp(db.memos.memoId)),
      leftOuterJoin(db.tags, db.tags.tagId.equalsExp(db.memoTags.tagId)),
    ]);

    final rows = await query.get(); // ← watch() 대신 get()

    final memo = rows.first.readTable(db.memos);
    /*final tags = rows
        .map((row) => row.readTableOrNull(db.tags))
        .where((tag) => tag != null)
        .toList();*/
    /*final List<Tag> tagRows = []; // 또는 List<TagsData>
    for (final r in rows) {
      final t = r.readTableOrNull(db.tags); // Tag? / TagsData?
      if (t != null) tagRows.add(t);        // 캐스팅 불필요
    }*/
    final tags = rows
        .map((row) => row.readTableOrNull(db.tags)) // Tag? 또는 TagsData?
        .whereType<Tag>() // 또는 .whereType<TagsData>()
        .toList(); // 여기서 캐스팅 불필요

    return MemoWithTagsDto(
      MemoDto.fromEntity(memo),
      tags.map(TagDto.fromEntity).toList(),  // 시그니처 맞춰서
    );
  }

  Future<int> insertMemo(String title) async {
    final companion = MemosCompanion.insert(title: title);

    return await db.into(db.memos).insert(companion);
  }

  Future<int> updateMemo(MemoDto dto) async {
    final companion = MemosCompanion(
      title: Value(dto.title),
      updatedAt: Value(DateTime.now()),
    );

    return await (db.update(db.memos)..where((t) => t.memoId.equals(dto.memoId)))
        .write(companion);
  }

  Future<int> deleteMemo(int memoId) async {
    return await (db.delete(db.memos)..where((tbl) => tbl.memoId.equals(memoId))).go();
  }
}
