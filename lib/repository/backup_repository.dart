import 'package:drift/drift.dart';
import 'package:remory/data/app_database.dart';
import 'package:remory/repository/dtos/memo_with_tags_dto.dart';
import 'package:remory/repository/dtos/tag_dto.dart';
import 'package:remory/repository/memo_repository.dart';
import 'package:remory/repository/tag_repository.dart';

class BackupRepository {
  final AppDatabase db;
  final MemoRepository memoRepository;
  final TagRepository tagRepository;

  BackupRepository(this.db, this.memoRepository, this.tagRepository);

  Future<List<MemoWithTagsDto>> fetchAllMemosWithTags() async {

    final memos = await memoRepository.fetchAllMemos();
    final List<MemoWithTagsDto> result = [];

    for (final memo in memos) {
      final memoWithTags = await memoRepository.fetchMemoWithTagsById(memo.memoId);
      if (memoWithTags != null) {
        result.add(memoWithTags);
      }
    }

    return result;
  }

  Future<List<TagDto>> fetchAllTags() async {
    final query = db.select(db.tags)
      ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc),
            (tbl) => OrderingTerm(expression: tbl.tagId, mode: OrderingMode.asc),
      ]);

    final rows = await query.get();
    return rows.map(TagDto.fromEntity).toList();
  }

  Future<Map<int, int>> restoreTags(List<TagDto> dtoList) async {
    final Map<int, int> oldToNewIdMap = {};
    
    for (final dto in dtoList) {
      final newTagId = await db.into(db.tags).insert(TagsCompanion.insert(
        name: dto.name,
        usageCount: Value(dto.usageCount),
        lastUsedAt: Value(dto.lastUsedAt),
        createdAt: Value(dto.createdAt),
        updatedAt: Value(dto.updatedAt),
      ));
      
      // 원본 ID → 새 ID 매핑 저장
      oldToNewIdMap[dto.tagId] = newTagId;
    }
    
    return oldToNewIdMap;
  }

  Future<void> restoreMemosWithTags(List<MemoWithTagsDto> dtoList, Map<int, int> tagIdMap) async {
    for (final dto in dtoList) {
      final memoId = await db.into(db.memos).insert(MemosCompanion.insert(
        title: dto.memo.title,
        createdAt: Value(dto.memo.createdAt),
        updatedAt: Value(dto.memo.updatedAt),
      ));

      for (final tag in dto.tags) {
        // 매핑된 새 태그 ID 사용
        final newTagId = tagIdMap[tag.tagId];
        if (newTagId != null) {
          await db.into(db.memoTags).insert(MemoTagsCompanion.insert(
            memoId: memoId,
            tagId: newTagId,  // ← 새 ID 사용
          ));
        }
      }
    }
  }
}