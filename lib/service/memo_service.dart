import 'package:remory/data/app_database.dart';
import 'package:remory/presentation/models/memo_model.dart';
import 'package:remory/presentation/models/memo_with_tags_model.dart';
import 'package:remory/provider/state/memo_cursor.dart';
import 'package:remory/repository/dtos/memo_dto.dart';
import 'package:remory/repository/memo_repository.dart';
import 'package:remory/repository/memo_tag_repository.dart';
import 'package:remory/repository/tag_repository.dart';
import 'package:remory/core/error_handler.dart';
import 'package:remory/core/performance_monitor.dart';
import 'package:remory/core/interceptor_decorators.dart';
import 'package:remory/provider/error_provider.dart';

class MemoService with ErrorHandlerMixin, PerformanceMonitorMixin {
  final AppDatabase db;
  final MemoRepository memoRepository;
  final TagRepository tagRepository;
  final MemoTagRepository memoTagRepository;

  MemoService(this.db, this.memoRepository, this.tagRepository, this.memoTagRepository);

  Future<List<MemoModel>> getMemosAfter({
    MemoCursor? memoCursor, 
    required int limit,
    String? searchQuery,
  }) async {
    // 🎯 이게 진짜 AOP! 자동으로 에러처리 + 성능측정
    return await memoRepository.fetchMemosWithAfter(
      memoCursor: memoCursor, 
      limit: limit,
      searchQuery: searchQuery,
    ).then((memoList) => memoList.map(MemoModel.fromDto).toList())
     .withAutoMonitoring(
      'MemoService.getMemosAfter',
      errorType: ErrorType.database,
      context: {
        'limit': limit,
        'hasSearchQuery': searchQuery != null,
      },
    );
  }

  Future<List<MemoModel>> getMemosByTagIdPaged({
    required int tagId,
    MemoCursor? memoCursor,
    required int limit,
  }) async {
    final memoList = await memoRepository.fetchMemosByTagIdPaged(
      tagId: tagId,
      memoCursor: memoCursor,
      limit: limit,
    );
    return memoList.map(MemoModel.fromDto).toList();
  }

  Future<MemoModel?> getMemoById(int memoId) async {
    final dto = await memoRepository.findMemoById(memoId);
    if (dto == null) return null;

    return MemoModel.fromDto(dto);
  }

  Future<MemoWithTagsModel?> getMemoWithTagsById(int memoId) async {
    final dto = await memoRepository.fetchMemoWithTagsById(memoId);
    if (dto == null) return null;

    return MemoWithTagsModel.fromDto(dto);
  }

  Future<int> registerMemoWithTags(String title, List<String> tagNames) async {
    return db.transaction(() async {
      final memoId = await memoRepository.insertMemo(title);

      /*
      final distinctNames = LinkedHashSet<String>.from(tagNames).toList(); // 중복 제거 및 순서 유지
      final existingTags = await tagRepository.findTagsByNames(distinctNames); // 중복 태그 조회
      final existingNames = existingTags.map((t) => t.name).toSet(); // 중복 태그 네임밍 처리

      final newTagNames = distinctNames.where((name) => !existingNames.contains(name)).toList(); // 없는 태그 필터링
      final newTags = await tagRepository.getOrCreateTagsByNames(newTagNames.toList()); // 없는 태그를 삽입

      final allTags = [...existingTags, ...newTags]; // 기존 태그와 신규 태그를 합침
      final tagMap = { for (var tag in allTags) tag.name: tag }; // 합친 것을 맵으로 만듬
      final sortTags = distinctNames.map((name) => tagMap[name]!).toList(); // 정렬을 통해 순서를 맞춤

      await memoTagRepository.insertMemoTags(memoId, sortTags,);
      */

      // getOrCreateTagsByNames가 내부에서 정규화/중복제거/삽입/조회/입력순서보존까지 처리
      final tags = await tagRepository.getOrCreateTagsByNames(tagNames);
      if (tags.isNotEmpty) {
        await memoTagRepository.insertMemoTags(memoId, tags);
      }

      return memoId;
    });
  }

  Future<void> modifyMemoWithTags(int memoId, String title, List<String> tagNames) async {
    await db.transaction(() async {
      final dto = await memoRepository.findMemoById(memoId);
      if (dto == null) return;

      // 메모 업데이트
      final updatedDto = MemoDto(
        memoId: dto.memoId,
        title: title,
        viewCount: dto.viewCount,
        createdAt: dto.createdAt,
        updatedAt: DateTime.now(),
      );

      await memoRepository.updateMemo(updatedDto);

      await memoTagRepository.deleteMemoTags(memoId);
      final tags = await tagRepository.getOrCreateTagsByNames(tagNames);
      if (tags.isNotEmpty) {
        await memoTagRepository.insertMemoTags(memoId, tags);
      }
    });
  }

  Future<void> deleteMemoWithTags(int memoId) async {
    await db.transaction(() async {
      await memoTagRepository.deleteMemoTags(memoId); // 1) 자식 먼저
      await memoRepository.deleteMemo(memoId);        // 2) 부모 나중
    });
  }

  // 🗑️ 휴지통 관련 메서드들
  
  /// 메모를 휴지통으로 이동 (소프트 삭제)
  Future<void> moveToTrash(int memoId) async {
    await memoRepository.moveToTrash(memoId)
      .withAutoMonitoring(
        'MemoService.moveToTrash',
        errorType: ErrorType.database,
        context: {'memoId': memoId},
      );
  }

  /// 휴지통에서 메모 복원
  Future<void> restoreFromTrash(int memoId) async {
    await memoRepository.restoreFromTrash(memoId)
      .withAutoMonitoring(
        'MemoService.restoreFromTrash',
        errorType: ErrorType.database,
        context: {'memoId': memoId},
      );
  }

  /// 휴지통 메모 목록 조회
  Future<List<MemoModel>> getTrashMemos({
    MemoCursor? memoCursor,
    required int limit,
  }) async {
    return await memoRepository.fetchTrashMemos(
      memoCursor: memoCursor,
      limit: limit,
    ).then((memoList) => memoList.map(MemoModel.fromDto).toList())
     .withAutoMonitoring(
      'MemoService.getTrashMemos',
      errorType: ErrorType.database,
      context: {'limit': limit},
    );
  }

  /// 휴지통 메모 영구 삭제
  Future<void> permanentlyDeleteMemo(int memoId) async {
    await db.transaction(() async {
      // 메모-태그 관계는 이미 CASCADE로 설정되어 있음
      await memoRepository.permanentlyDeleteMemo(memoId);
    }).withAutoMonitoring(
      'MemoService.permanentlyDeleteMemo',
      errorType: ErrorType.database,
      context: {'memoId': memoId},
    );
  }

  /// 오래된 휴지통 메모 자동 정리
  Future<int> cleanUpOldTrashMemos({int daysOld = 30}) async {
    return await memoRepository.cleanUpOldTrashMemos(daysOld: daysOld)
      .withAutoMonitoring(
        'MemoService.cleanUpOldTrashMemos',
        errorType: ErrorType.database,
        context: {'daysOld': daysOld},
      );
  }

  /// 휴지통 메모 개수 조회
  Future<int> getTrashCount() async {
    return await memoRepository.getTrashCount()
      .withAutoMonitoring(
        'MemoService.getTrashCount',
        errorType: ErrorType.database,
      );
  }

  Future<void> incrementMemoViewCount(int memoId) async {
    await memoRepository.incrementViewCount(memoId);
  }
}
