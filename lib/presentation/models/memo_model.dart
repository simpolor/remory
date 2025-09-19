import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:remory/repository/dtos/memo_dto.dart';

part 'memo_model.freezed.dart';
part 'memo_model.g.dart';

@freezed
class MemoModel with _$MemoModel {
  const factory MemoModel({
    required int memoId,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MemoModel;

  factory MemoModel.fromJson(Map<String, dynamic> json) => _$MemoModelFromJson(json);

  factory MemoModel.fromDto(MemoDto dto) => MemoModel(
    memoId: dto.memoId,
    title: dto.title,
    createdAt: dto.createdAt,
    updatedAt: dto.updatedAt,
  );
}

/// MemoModel Extension for DTO conversion
extension MemoModelExtension on MemoModel {
  MemoDto toDto() => MemoDto(
    memoId: memoId,
    title: title,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}