import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:remory/presentation/models/memo_model.dart';
import 'package:remory/provider/state/memo_cursor.dart';
import 'package:remory/provider/state/memo_paged_state.dart';
import 'package:remory/service/memo_service.dart';

class MemoPagedNotifier extends StateNotifier<MemoPagedState> {
  final MemoService service;
  static const int pageSize = 20;

  DateTime? _cursorCreatedAt;
  int? _cursorId;
  bool _isLoadingInternal = false;

  MemoPagedNotifier(this.service) : super(MemoPagedState.initial()) {
    loadMore();
  }

  Future<void> refresh() async {
    _cursorCreatedAt = null;
    _cursorId = null;
    state = state.copyWith(memos: [], hasMore: true, error: null);
    await loadMore();
  }

  Future<void> refreshHead({int headSize = 20}) async {
    if (_isLoadingInternal) return;
    _isLoadingInternal = true;
    try {
      final head = await service.getMemosAfter(memoCursor: null, limit: headSize);
      _upsertMerge(head);
      _updateCursorFromState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      _isLoadingInternal = false;
    }
  }

  Future<void> loadMore({int? limitOverride}) async {
    debugPrint('[loadMore] enter '
        'isLoading=${state.isLoading} hasMore=${state.hasMore} internal=$_isLoadingInternal '
        'cursor=$_cursorCreatedAt/$_cursorId memos=${state.memos.length}');
    if (state.isLoading || !state.hasMore || _isLoadingInternal) return;

    _isLoadingInternal = true;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final MemoCursor? memoCursor = (_cursorCreatedAt != null && _cursorId != null)
          ? MemoCursor(_cursorCreatedAt!, _cursorId!)
          : null;

      final limit = limitOverride ?? pageSize;
      final page = await service.getMemosAfter(memoCursor: memoCursor, limit: limit);
      debugPrint('[loadMore] fetched=${page.length}');

      _upsertMerge(page);
      _updateCursorFromState();

      state = state.copyWith(
        isLoading: false,
        hasMore: page.length == limit,
      );
      debugPrint('[loadMore] done memos=${state.memos.length} '
          'cursor=$_cursorCreatedAt/$_cursorId hasMore=${state.hasMore}');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _isLoadingInternal = false;
    }
  }

  Future<void> removeMemo(int memoId) async {
    /*final next = state.memos.where((m) => m.memoId != memoId).toList();
    state = state.copyWith(memos: next);
    _updateCursorFromState();*/

    final i = state.memos.indexWhere((m) => m.memoId == memoId);
    if (i < 0) return;

    final list = List<MemoModel>.from(state.memos)..removeAt(i);
    state = state.copyWith(memos: list);
    _updateCursorFromState();

    if (state.hasMore && !_isLoadingInternal) {
      await loadMore(limitOverride: 1); // 🔹 한 개만 보충
    }
  }

  // 목표: “중복 없이, 항상 올바른 정렬로” 상태를 유지: 같은 memoId가 여러 번 들어와도 한 번만 남도록 보장
  void _upsertMerge(List<MemoModel> incoming) {
    final map = {for (final m in state.memos) m.memoId: m};
    for (final m in incoming) {
      map[m.memoId] = m; // 새로 오면 insert, 있으면 replace
    }
    final merged = map.values.toList()
      ..sort((a, b) {
        final c = b.createdAt.compareTo(a.createdAt); // DESC
        return c != 0 ? c : b.memoId.compareTo(a.memoId);
      });
    state = state.copyWith(memos: merged);
  }

  // 목표: 다음 페이지를 정확히 가져오기 위한 “커서” 유지: 현재 state.memos가 내림차순(DESC) 이므로 마지막 아이템이 “가장 오래된(하단) 항목
  void _updateCursorFromState() {
    if (state.memos.isEmpty) {
      _cursorCreatedAt = null;
      _cursorId = null;
    } else {
      final oldest = state.memos.last; // 정렬이 DESC이므로 마지막이 가장 오래된 항목
      _cursorCreatedAt = oldest.createdAt;
      _cursorId = oldest.memoId;
    }
  }
}