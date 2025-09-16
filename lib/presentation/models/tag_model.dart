import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:remory/repository/dtos/tag_dto.dart';

part 'tag_model.freezed.dart';
part 'tag_model.g.dart';

@freezed
class TagModel with _$TagModel {
  const factory TagModel({
    required int tagId,
    required String name,
    required DateTime createdAt,
  }) = _TagModel;

  factory TagModel.fromJson(Map<String, dynamic> json) =>
      _$TagModelFromJson(json);

  /// DTO → Model 변환
  factory TagModel.fromDto(TagDto dto) => TagModel(
    tagId: dto.tagId,
    name: dto.name,
    createdAt: dto.createdAt,
  );
}