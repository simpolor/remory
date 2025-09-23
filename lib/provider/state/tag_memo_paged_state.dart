import 'package:remory/presentation/models/memo_model.dart';

class TagMemoPagedState {
  final List<MemoModel> memos;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int tagId;

  const TagMemoPagedState({
    required this.memos,
    required this.isLoading,
    required this.hasMore,
    required this.tagId,
    this.error,
  });

  TagMemoPagedState copyWith({
    List<MemoModel>? memos,
    bool? isLoading,
    bool? hasMore,
    int? tagId,
    String? error,
  }) {
    return TagMemoPagedState(
      memos: memos ?? this.memos,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      tagId: tagId ?? this.tagId,
      error: error,
    );
  }

  factory TagMemoPagedState.initial(int tagId) =>
      TagMemoPagedState(memos: [], isLoading: false, hasMore: true, tagId: tagId);
}