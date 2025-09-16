import 'package:remory/repository/dtos/tag_dto.dart';

class TagWithCountDto {
  final TagDto tag;
  final int count;

  TagWithCountDto({
    required this.tag,
    required this.count
  });
}