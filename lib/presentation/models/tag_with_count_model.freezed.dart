// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tag_with_count_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

TagWithCountModel _$TagWithCountModelFromJson(Map<String, dynamic> json) {
  return _TagWithCountModel.fromJson(json);
}

/// @nodoc
mixin _$TagWithCountModel {
  TagModel get tag => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TagWithCountModelCopyWith<TagWithCountModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TagWithCountModelCopyWith<$Res> {
  factory $TagWithCountModelCopyWith(
          TagWithCountModel value, $Res Function(TagWithCountModel) then) =
      _$TagWithCountModelCopyWithImpl<$Res, TagWithCountModel>;
  @useResult
  $Res call({TagModel tag, int count});

  $TagModelCopyWith<$Res> get tag;
}

/// @nodoc
class _$TagWithCountModelCopyWithImpl<$Res, $Val extends TagWithCountModel>
    implements $TagWithCountModelCopyWith<$Res> {
  _$TagWithCountModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tag = null,
    Object? count = null,
  }) {
    return _then(_value.copyWith(
      tag: null == tag
          ? _value.tag
          : tag // ignore: cast_nullable_to_non_nullable
              as TagModel,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $TagModelCopyWith<$Res> get tag {
    return $TagModelCopyWith<$Res>(_value.tag, (value) {
      return _then(_value.copyWith(tag: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TagWithCountModelImplCopyWith<$Res>
    implements $TagWithCountModelCopyWith<$Res> {
  factory _$$TagWithCountModelImplCopyWith(_$TagWithCountModelImpl value,
          $Res Function(_$TagWithCountModelImpl) then) =
      __$$TagWithCountModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({TagModel tag, int count});

  @override
  $TagModelCopyWith<$Res> get tag;
}

/// @nodoc
class __$$TagWithCountModelImplCopyWithImpl<$Res>
    extends _$TagWithCountModelCopyWithImpl<$Res, _$TagWithCountModelImpl>
    implements _$$TagWithCountModelImplCopyWith<$Res> {
  __$$TagWithCountModelImplCopyWithImpl(_$TagWithCountModelImpl _value,
      $Res Function(_$TagWithCountModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tag = null,
    Object? count = null,
  }) {
    return _then(_$TagWithCountModelImpl(
      tag: null == tag
          ? _value.tag
          : tag // ignore: cast_nullable_to_non_nullable
              as TagModel,
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TagWithCountModelImpl implements _TagWithCountModel {
  const _$TagWithCountModelImpl({required this.tag, required this.count});

  factory _$TagWithCountModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TagWithCountModelImplFromJson(json);

  @override
  final TagModel tag;
  @override
  final int count;

  @override
  String toString() {
    return 'TagWithCountModel(tag: $tag, count: $count)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TagWithCountModelImpl &&
            (identical(other.tag, tag) || other.tag == tag) &&
            (identical(other.count, count) || other.count == count));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, tag, count);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TagWithCountModelImplCopyWith<_$TagWithCountModelImpl> get copyWith =>
      __$$TagWithCountModelImplCopyWithImpl<_$TagWithCountModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TagWithCountModelImplToJson(
      this,
    );
  }
}

abstract class _TagWithCountModel implements TagWithCountModel {
  const factory _TagWithCountModel(
      {required final TagModel tag,
      required final int count}) = _$TagWithCountModelImpl;

  factory _TagWithCountModel.fromJson(Map<String, dynamic> json) =
      _$TagWithCountModelImpl.fromJson;

  @override
  TagModel get tag;
  @override
  int get count;
  @override
  @JsonKey(ignore: true)
  _$$TagWithCountModelImplCopyWith<_$TagWithCountModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
