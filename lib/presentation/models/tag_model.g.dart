// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TagModelImpl _$$TagModelImplFromJson(Map<String, dynamic> json) =>
    _$TagModelImpl(
      tagId: (json['tagId'] as num).toInt(),
      name: json['name'] as String,
      usageCount: (json['usageCount'] as num).toInt(),
      lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$TagModelImplToJson(_$TagModelImpl instance) =>
    <String, dynamic>{
      'tagId': instance.tagId,
      'name': instance.name,
      'usageCount': instance.usageCount,
      'lastUsedAt': instance.lastUsedAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
