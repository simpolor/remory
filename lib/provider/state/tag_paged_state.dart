import 'package:remory/presentation/models/tag_with_count_model.dart';

class TagPagedState {
  final List<TagWithCountModel> tags;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const TagPagedState({
    required this.tags,
    required this.isLoading,
    required this.hasMore,
    this.error,
  });

  TagPagedState copyWith({
    List<TagWithCountModel>? tags,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return TagPagedState(
      tags: tags ?? this.tags,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }

  factory TagPagedState.initial() =>
      const TagPagedState(tags: [], isLoading: false, hasMore: true);
}