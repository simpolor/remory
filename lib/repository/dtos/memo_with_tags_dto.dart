import 'package:remory/repository/dtos/memo_dto.dart';
import 'package:remory/repository/dtos/tag_dto.dart';

class MemoWithTagsDto {
  final MemoDto memo;
  final List<TagDto> tags;

  MemoWithTagsDto(this.memo, this.tags);
}