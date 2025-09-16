// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_with_count_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TagWithCountModelImpl _$$TagWithCountModelImplFromJson(
        Map<String, dynamic> json) =>
    _$TagWithCountModelImpl(
      tag: TagModel.fromJson(json['tag'] as Map<String, dynamic>),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$$TagWithCountModelImplToJson(
        _$TagWithCountModelImpl instance) =>
    <String, dynamic>{
      'tag': instance.tag,
      'count': instance.count,
    };
