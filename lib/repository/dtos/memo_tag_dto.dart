import 'package:remory/data/app_database.dart';

class MemoTagDto {
  final int memoId;
  final int tagId;
  final int sortOrder;

  MemoTagDto({
    required this.memoId,
    required this.tagId,
    required this.sortOrder,
  });

  factory MemoTagDto.fromEntity(MemoTag entity) {
    return MemoTagDto(
      memoId: entity.memoId,
      tagId: entity.tagId,
      sortOrder: entity.sortOrder,
    );
  }
}