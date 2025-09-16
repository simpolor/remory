import 'package:remory/presentation/models/memo_model.dart';

class MemoPagedState {
  final List<MemoModel> memos;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const MemoPagedState({
    required this.memos,
    required this.isLoading,
    required this.hasMore,
    this.error,
  });

  MemoPagedState copyWith({
    List<MemoModel>? memos,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return MemoPagedState(
      memos: memos ?? this.memos,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }

  factory MemoPagedState.initial() =>
      const MemoPagedState(memos: [], isLoading: false, hasMore: true);
}