import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:remory/presentation/models/memo_with_tags_model.dart';
import 'package:remory/presentation/models/tag_model.dart';

part 'backup_data_model.freezed.dart';
part 'backup_data_model.g.dart';

@freezed
class BackupDataModel with _$BackupDataModel {
  const factory BackupDataModel({
    required String version,
    required DateTime exportedAt,
    required List<MemoWithTagsModel> memos,
    required List<TagModel> tags,
  }) = _BackupDataModel;

  factory BackupDataModel.fromJson(Map<String, dynamic> json) =>
      _$BackupDataModelFromJson(json);
}
