import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:remory/presentation/models/tag_model.dart';
import 'package:remory/repository/dtos/tag_with_count_dto.dart';

part 'tag_with_count_model.freezed.dart';
part 'tag_with_count_model.g.dart';

@freezed
class TagWithCountModel with _$TagWithCountModel {
  const factory TagWithCountModel({
    required TagModel tag,
    required int count,
  }) = _TagWithCountModel;

  factory TagWithCountModel.fromJson(Map<String, dynamic> json) =>
      _$TagWithCountModelFromJson(json);

  factory TagWithCountModel.fromDto(TagWithCountDto dto) => TagWithCountModel(
    tag: TagModel.fromDto(dto.tag),
    count: dto.count,
  );
}