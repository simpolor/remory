import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:remory/presentation/models/memo_model.dart';
import 'package:remory/provider/state/memo_cursor.dart';
import 'package:remory/provider/state/tag_memo_paged_state.dart';
import 'package:remory/service/memo_service.dart';

class TagMemoPagedNotifier extends StateNotifier<TagMemoPagedState> {
  final MemoService service;
  final int tagId;
  static const int pageSize = 20;

  DateTime? _cursorCreatedAt;
  int? _cursorId;
  bool _isLoadingInternal = false;

  TagMemoPagedNotifier(this.service, this.tagId) : super(TagMemoPagedState.initial(tagId)) {
    loadMore();
  }

  Future<void> refresh() async {
    _cursorCreatedAt = null;
    _cursorId = null;
    state = state.copyWith(memos: [], hasMore: true, error: null);
    await loadMore();
  }

  Future<void> loadMore({int? limitOverride}) async {
    debugPrint('[TagMemoPagedNotifier] loadMore enter '
        'tagId=$tagId isLoading=${state.isLoading} hasMore=${state.hasMore} '
        'internal=$_isLoadingInternal cursor=$_cursorCreatedAt/$_cursorId memos=${state.memos.length}');

    if (state.isLoading || !state.hasMore || _isLoadingInternal) return;

    _isLoadingInternal = true;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final MemoCursor? memoCursor = (_cursorCreatedAt != null && _cursorId != null)
          ? MemoCursor(_cursorCreatedAt!, _cursorId!)
          : null;

      final limit = limitOverride ?? pageSize;
      final page = await service.getMemosByTagIdPaged(
        tagId: tagId,
        memoCursor: memoCursor,
        limit: limit,
      );

      debugPrint('[TagMemoPagedNotifier] fetched=${page.length} for tagId=$tagId');

      _upsertMerge(page);
      _updateCursorFromState();

      state = state.copyWith(
        isLoading: false,
        hasMore: page.length == limit,
      );

      debugPrint('[TagMemoPagedNotifier] done memos=${state.memos.length} '
          'cursor=$_cursorCreatedAt/$_cursorId hasMore=${state.hasMore}');
    } catch (e) {
      debugPrint('[TagMemoPagedNotifier] error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _isLoadingInternal = false;
    }
  }

  Future<void> removeMemo(int memoId) async {
    final i = state.memos.indexWhere((m) => m.memoId == memoId);
    if (i < 0) return;

    final list = List<MemoModel>.from(state.memos)..removeAt(i);
    state = state.copyWith(memos: list);
    _updateCursorFromState();

    // 삭제 후 한 개 더 로드해서 목록 보충
    if (state.hasMore && !_isLoadingInternal) {
      await loadMore(limitOverride: 1);
    }
  }

  void _upsertMerge(List<MemoModel> incoming) {
    final map = {for (final m in state.memos) m.memoId: m};
    for (final m in incoming) {
      map[m.memoId] = m;
    }
    final merged = map.values.toList()
      ..sort((a, b) {
        final c = b.createdAt.compareTo(a.createdAt); // DESC
        return c != 0 ? c : b.memoId.compareTo(a.memoId);
      });
    state = state.copyWith(memos: merged);
  }

  void _updateCursorFromState() {
    if (state.memos.isEmpty) {
      _cursorCreatedAt = null;
      _cursorId = null;
    } else {
      final oldest = state.memos.last;
      _cursorCreatedAt = oldest.createdAt;
      _cursorId = oldest.memoId;
    }
  }
}