import 'package:remory/data/app_database.dart';

class MemoDto {
  final int memoId;
  final String title;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  MemoDto({
    required this.memoId,
    required this.title,
    required this.viewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MemoDto.fromEntity(Memo memo) {
    return MemoDto(
      memoId: memo.memoId,
      title: memo.title,
      viewCount: memo.viewCount,
      createdAt: memo.createdAt,
      updatedAt: memo.updatedAt,
    );
  }
}