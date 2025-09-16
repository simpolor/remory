import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:remory/presentation/models/memo_model.dart';
import 'package:remory/presentation/models/tag_model.dart';
import 'package:remory/repository/dtos/memo_with_tags_dto.dart';

part 'memo_with_tags_model.freezed.dart';
part 'memo_with_tags_model.g.dart';

@freezed
class MemoWithTagsModel with _$MemoWithTagsModel {
  const factory MemoWithTagsModel({
    required MemoModel memo,
    required List<TagModel> tags,
  }) = _MemoWithTagsModel;

  factory MemoWithTagsModel.fromJson(Map<String, dynamic> json) =>
      _$MemoWithTagsModelFromJson(json);

  factory MemoWithTagsModel.fromDto(MemoWithTagsDto dto) => MemoWithTagsModel(
    memo: MemoModel.fromDto(dto.memo),
    tags: dto.tags.map((e) => TagModel.fromDto(e)).toList(),
  );
}