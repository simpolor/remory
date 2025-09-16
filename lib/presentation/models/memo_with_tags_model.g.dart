// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_with_tags_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MemoWithTagsModelImpl _$$MemoWithTagsModelImplFromJson(
        Map<String, dynamic> json) =>
    _$MemoWithTagsModelImpl(
      memo: MemoModel.fromJson(json['memo'] as Map<String, dynamic>),
      tags: (json['tags'] as List<dynamic>)
          .map((e) => TagModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$MemoWithTagsModelImplToJson(
        _$MemoWithTagsModelImpl instance) =>
    <String, dynamic>{
      'memo': instance.memo,
      'tags': instance.tags,
    };
