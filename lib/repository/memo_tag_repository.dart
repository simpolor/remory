import 'package:drift/drift.dart';
import 'package:remory/data/app_database.dart';
import 'package:remory/repository/dtos/memo_tag_dto.dart';
import 'package:remory/repository/dtos/tag_dto.dart';

class MemoTagRepository {
  final AppDatabase db;

  MemoTagRepository(this.db);

  Future<void> insertMemoTags(int memoId, List<TagDto> sortTags) async {

    // TagDto → MemoTagDto 변환
    final memoTagDtos = sortTags.asMap().entries.map((entry) {
      final sortOrder = entry.key;
      final tag = entry.value;

      return MemoTagDto(
        memoId: memoId,
        tagId: tag.tagId,
        sortOrder: sortOrder,
      );
    }).toList();

    await db.batch((batch) {
      batch.insertAll(
        db.memoTags,
        memoTagDtos.map((dto) => MemoTagsCompanion(
          memoId: Value(dto.memoId),
          tagId: Value(dto.tagId),
          sortOrder: Value(dto.sortOrder),
        )).toList(),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  Future<void> deleteMemoTags(int memoId) async {
    await (db.delete(db.memoTags)..where((t) => t.memoId.equals(memoId))).go();
  }
}