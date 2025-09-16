import 'package:remory/repository/dtos/memo_dto.dart';
import 'package:remory/repository/dtos/memo_tag_dto.dart';
import 'package:remory/repository/dtos/tag_dto.dart';

class SeedBundle {
  final List<MemoDto> memos;
  final List<TagDto> tags;
  final List<MemoTagDto> memoTags;

  const SeedBundle({
    required this.memos,
    required this.tags,
    required this.memoTags,
  });

  bool get isEmpty => memos.isEmpty && tags.isEmpty && memoTags.isEmpty;
}