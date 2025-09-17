import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:remory/presentation/models/tag_with_count_model.dart';
import 'package:remory/provider/state/tag_cursor.dart';
import 'package:remory/provider/state/tag_paged_state.dart';
import 'package:remory/service/tag_service.dart';

class TagPagedNotifier extends StateNotifier<TagPagedState> {
  final TagService service;
  static const int pageSize = 40;

  String? _cursorLastName;
  int? _cursorLastTagId;
  bool _isLoadingInternal = false;

  TagPagedNotifier(this.service) : super(TagPagedState.initial()) {
    loadMore();
  }

  Future<void> refresh() async {
    _cursorLastName = null;
    _cursorLastTagId = null;
    state = state.copyWith(tags: [], hasMore: true, error: null);
    await loadMore();
  }

  Future<void> reloadCurrent() async {
    if (state.tags.isEmpty) {
      return refresh();
    }

    final currentCount = state.tags.length;
    debugPrint('[reloadCurrent] reloading $currentCount tags');

    // 상태 초기화
    _cursorLastName = null;
    _cursorLastTagId = null;
    state = state.copyWith(tags: [], hasMore: true, error: null);

    // 현재 개수만큼 로드 (백필 가능하도록 특별 플래그 추가)
    await _loadExactCount(currentCount);
  }

  // reloadCurrent 전용 로더 (백필 포함)
  Future<void> _loadExactCount(int targetCount) async {
    int loadedCount = 0;
    
    while (loadedCount < targetCount && state.hasMore && !_isLoadingInternal) {
      final remainingCount = targetCount - loadedCount;
      final batchSize = remainingCount > pageSize ? pageSize : remainingCount;
      
      await loadMore(limitOverride: batchSize);
      
      final newLoadedCount = state.tags.length;
      if (newLoadedCount == loadedCount) {
        // 더 이상 로드되지 않으면 중단
        debugPrint('[_loadExactCount] no more data available at $loadedCount/$targetCount');
        break;
      }
      loadedCount = newLoadedCount;
    }
    
    debugPrint('[_loadExactCount] completed: loaded $loadedCount/$targetCount');
  }

  Future<void> loadMore({int? limitOverride}) async {
    if (state.isLoading || !state.hasMore || _isLoadingInternal) return;

    _isLoadingInternal = true;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final TagCursor? tagCursor = (_cursorLastName != null && _cursorLastTagId != null)
          ? TagCursor(_cursorLastName!, _cursorLastTagId!)
          : null;

      final limit = limitOverride ?? pageSize;
      final page = await service.getTagsAfter(tagCursor: tagCursor, limit: limit);
      debugPrint('[loadMore] fetched=${page.length}, requested=$limit');
      debugPrint('[loadMore] cursor: name=$_cursorLastName, id=$_cursorLastTagId');

      _upsertMerge(page);
      _updateCursorFromState();

      // hasMore 판단: 요청한 만큼 받았으면 더 있을 가능성
      final hasMore = page.length == limit;
      
      // 백필 로직: 일반 loadMore()에서만 작동 (limitOverride가 없을 때)
      if (limitOverride == null && page.length < limit && page.length > 0 && hasMore) {
        debugPrint('[loadMore] backfill needed: got ${page.length}, expected $limit');
        final remainingSpace = limit - page.length;
        
        await loadMore(limitOverride: remainingSpace);
        return; // 재귀 호출에서 처리
      }

      state = state.copyWith(
        isLoading: false,
        hasMore: hasMore,
      );

    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _isLoadingInternal = false;
    }
  }

  void removeTag(int tagId) async {
    /*final next = state.tags.where((model) => model.tag.tagId != tagId).toList();
    state = state.copyWith(tags: next);
    _updateCursorFromState();*/

    final i = state.tags.indexWhere((t) => t.tag.tagId == tagId);
    if (i < 0) return;

    // 1) 로컬에서 제거
    final list = List<TagWithCountModel>.from(state.tags)..removeAt(i);
    state = state.copyWith(tags: list);

    // 2) 커서 재계산: 마지막 아이템 기준 (name, tagId)
    _updateCursorFromState();

    // 3) 부족분 한 칸만 백필 (옵션 A: 즉시 백필)
    if (state.hasMore && !_isLoadingInternal) {
      await loadMore(limitOverride: 1);
    }
  }

  void _upsertMerge(List<TagWithCountModel> incoming) {
    if (incoming.isEmpty) return;

    // tagId 기준으로 최신값으로 덮어쓰기
    final map = <int, TagWithCountModel>{
      for (final model in state.tags) model.tag.tagId: model,
    };
    for (final model in incoming) {
      map[model.tag.tagId] = model;
    }

    // ORDER BY name ASC, tag_id ASC 와 동일
    final merged = map.values.toList()
      ..sort((a, b) {
        final byName = a.tag.name.compareTo(b.tag.name); // ASC
        return byName != 0 ? byName : a.tag.tagId.compareTo(b.tag.tagId); // ASC
      });

    state = state.copyWith(tags: merged);
  }

  // 목표: 다음 페이지를 정확히 가져오기 위한 “커서” 유지: 현재 state.memos가 내림차순(DESC) 이므로 마지막 아이템이 “가장 오래된(하단) 항목
  void _updateCursorFromState() {
    if (state.tags.isEmpty) {
      _cursorLastName = null;
      _cursorLastTagId = null;
    } else {
      final oldest = state.tags.last;
      _cursorLastName = oldest.tag.name;
      _cursorLastTagId = oldest.tag.tagId;
    }
  }
}