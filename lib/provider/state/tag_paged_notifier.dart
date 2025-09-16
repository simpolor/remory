import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:remory/presentation/models/tag_with_count_model.dart';
import 'package:remory/provider/state/tag_cursor.dart';
import 'package:remory/provider/state/tag_paged_state.dart';
import 'package:remory/service/tag_service.dart';

class TagPagedNotifier extends StateNotifier<TagPagedState> {
  final TagService service;
  static const int pageSize = 20;

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
      debugPrint('[loadMore] fetched=${page.length}');

      _upsertMerge(page);
      _updateCursorFromState();

      state = state.copyWith(
        isLoading: false,
        hasMore: page.length == limit,
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