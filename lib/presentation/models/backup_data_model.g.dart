// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BackupDataModelImpl _$$BackupDataModelImplFromJson(
        Map<String, dynamic> json) =>
    _$BackupDataModelImpl(
      version: json['version'] as String,
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      memos: (json['memos'] as List<dynamic>)
          .map((e) => MemoWithTagsModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List<dynamic>)
          .map((e) => TagModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$BackupDataModelImplToJson(
        _$BackupDataModelImpl instance) =>
    <String, dynamic>{
      'version': instance.version,
      'exportedAt': instance.exportedAt.toIso8601String(),
      'memos': instance.memos,
      'tags': instance.tags,
    };
