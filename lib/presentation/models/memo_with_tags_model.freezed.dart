// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'memo_with_tags_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

MemoWithTagsModel _$MemoWithTagsModelFromJson(Map<String, dynamic> json) {
  return _MemoWithTagsModel.fromJson(json);
}

/// @nodoc
mixin _$MemoWithTagsModel {
  MemoModel get memo => throw _privateConstructorUsedError;
  List<TagModel> get tags => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MemoWithTagsModelCopyWith<MemoWithTagsModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MemoWithTagsModelCopyWith<$Res> {
  factory $MemoWithTagsModelCopyWith(
          MemoWithTagsModel value, $Res Function(MemoWithTagsModel) then) =
      _$MemoWithTagsModelCopyWithImpl<$Res, MemoWithTagsModel>;
  @useResult
  $Res call({MemoModel memo, List<TagModel> tags});

  $MemoModelCopyWith<$Res> get memo;
}

/// @nodoc
class _$MemoWithTagsModelCopyWithImpl<$Res, $Val extends MemoWithTagsModel>
    implements $MemoWithTagsModelCopyWith<$Res> {
  _$MemoWithTagsModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memo = null,
    Object? tags = null,
  }) {
    return _then(_value.copyWith(
      memo: null == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as MemoModel,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<TagModel>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $MemoModelCopyWith<$Res> get memo {
    return $MemoModelCopyWith<$Res>(_value.memo, (value) {
      return _then(_value.copyWith(memo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MemoWithTagsModelImplCopyWith<$Res>
    implements $MemoWithTagsModelCopyWith<$Res> {
  factory _$$MemoWithTagsModelImplCopyWith(_$MemoWithTagsModelImpl value,
          $Res Function(_$MemoWithTagsModelImpl) then) =
      __$$MemoWithTagsModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({MemoModel memo, List<TagModel> tags});

  @override
  $MemoModelCopyWith<$Res> get memo;
}

/// @nodoc
class __$$MemoWithTagsModelImplCopyWithImpl<$Res>
    extends _$MemoWithTagsModelCopyWithImpl<$Res, _$MemoWithTagsModelImpl>
    implements _$$MemoWithTagsModelImplCopyWith<$Res> {
  __$$MemoWithTagsModelImplCopyWithImpl(_$MemoWithTagsModelImpl _value,
      $Res Function(_$MemoWithTagsModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? memo = null,
    Object? tags = null,
  }) {
    return _then(_$MemoWithTagsModelImpl(
      memo: null == memo
          ? _value.memo
          : memo // ignore: cast_nullable_to_non_nullable
              as MemoModel,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<TagModel>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MemoWithTagsModelImpl implements _MemoWithTagsModel {
  const _$MemoWithTagsModelImpl(
      {required this.memo, required final List<TagModel> tags})
      : _tags = tags;

  factory _$MemoWithTagsModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MemoWithTagsModelImplFromJson(json);

  @override
  final MemoModel memo;
  final List<TagModel> _tags;
  @override
  List<TagModel> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'MemoWithTagsModel(memo: $memo, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MemoWithTagsModelImpl &&
            (identical(other.memo, memo) || other.memo == memo) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, memo, const DeepCollectionEquality().hash(_tags));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MemoWithTagsModelImplCopyWith<_$MemoWithTagsModelImpl> get copyWith =>
      __$$MemoWithTagsModelImplCopyWithImpl<_$MemoWithTagsModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MemoWithTagsModelImplToJson(
      this,
    );
  }
}

abstract class _MemoWithTagsModel implements MemoWithTagsModel {
  const factory _MemoWithTagsModel(
      {required final MemoModel memo,
      required final List<TagModel> tags}) = _$MemoWithTagsModelImpl;

  factory _MemoWithTagsModel.fromJson(Map<String, dynamic> json) =
      _$MemoWithTagsModelImpl.fromJson;

  @override
  MemoModel get memo;
  @override
  List<TagModel> get tags;
  @override
  @JsonKey(ignore: true)
  _$$MemoWithTagsModelImplCopyWith<_$MemoWithTagsModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
