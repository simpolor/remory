import 'package:remory/repository/dtos/memo_with_tags_dto.dart';
import 'package:remory/repository/dtos/tag_dto.dart';

class BackupDto {
  final String version;
  final DateTime exportedAt;
  final List<MemoWithTagsDto> memos;
  final List<TagDto> tags;

  BackupDto({
    required this.version,
    required this.exportedAt,
    required this.memos,
    required this.tags,
  });
}