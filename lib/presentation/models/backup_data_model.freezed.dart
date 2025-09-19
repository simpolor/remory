// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backup_data_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

BackupDataModel _$BackupDataModelFromJson(Map<String, dynamic> json) {
  return _BackupDataModel.fromJson(json);
}

/// @nodoc
mixin _$BackupDataModel {
  String get version => throw _privateConstructorUsedError;
  DateTime get exportedAt => throw _privateConstructorUsedError;
  List<MemoWithTagsModel> get memos => throw _privateConstructorUsedError;
  List<TagModel> get tags => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BackupDataModelCopyWith<BackupDataModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BackupDataModelCopyWith<$Res> {
  factory $BackupDataModelCopyWith(
          BackupDataModel value, $Res Function(BackupDataModel) then) =
      _$BackupDataModelCopyWithImpl<$Res, BackupDataModel>;
  @useResult
  $Res call(
      {String version,
      DateTime exportedAt,
      List<MemoWithTagsModel> memos,
      List<TagModel> tags});
}

/// @nodoc
class _$BackupDataModelCopyWithImpl<$Res, $Val extends BackupDataModel>
    implements $BackupDataModelCopyWith<$Res> {
  _$BackupDataModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? exportedAt = null,
    Object? memos = null,
    Object? tags = null,
  }) {
    return _then(_value.copyWith(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      exportedAt: null == exportedAt
          ? _value.exportedAt
          : exportedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      memos: null == memos
          ? _value.memos
          : memos // ignore: cast_nullable_to_non_nullable
              as List<MemoWithTagsModel>,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<TagModel>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BackupDataModelImplCopyWith<$Res>
    implements $BackupDataModelCopyWith<$Res> {
  factory _$$BackupDataModelImplCopyWith(_$BackupDataModelImpl value,
          $Res Function(_$BackupDataModelImpl) then) =
      __$$BackupDataModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String version,
      DateTime exportedAt,
      List<MemoWithTagsModel> memos,
      List<TagModel> tags});
}

/// @nodoc
class __$$BackupDataModelImplCopyWithImpl<$Res>
    extends _$BackupDataModelCopyWithImpl<$Res, _$BackupDataModelImpl>
    implements _$$BackupDataModelImplCopyWith<$Res> {
  __$$BackupDataModelImplCopyWithImpl(
      _$BackupDataModelImpl _value, $Res Function(_$BackupDataModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? exportedAt = null,
    Object? memos = null,
    Object? tags = null,
  }) {
    return _then(_$BackupDataModelImpl(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      exportedAt: null == exportedAt
          ? _value.exportedAt
          : exportedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      memos: null == memos
          ? _value._memos
          : memos // ignore: cast_nullable_to_non_nullable
              as List<MemoWithTagsModel>,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<TagModel>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BackupDataModelImpl implements _BackupDataModel {
  const _$BackupDataModelImpl(
      {required this.version,
      required this.exportedAt,
      required final List<MemoWithTagsModel> memos,
      required final List<TagModel> tags})
      : _memos = memos,
        _tags = tags;

  factory _$BackupDataModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BackupDataModelImplFromJson(json);

  @override
  final String version;
  @override
  final DateTime exportedAt;
  final List<MemoWithTagsModel> _memos;
  @override
  List<MemoWithTagsModel> get memos {
    if (_memos is EqualUnmodifiableListView) return _memos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_memos);
  }

  final List<TagModel> _tags;
  @override
  List<TagModel> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'BackupDataModel(version: $version, exportedAt: $exportedAt, memos: $memos, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BackupDataModelImpl &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.exportedAt, exportedAt) ||
                other.exportedAt == exportedAt) &&
            const DeepCollectionEquality().equals(other._memos, _memos) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      version,
      exportedAt,
      const DeepCollectionEquality().hash(_memos),
      const DeepCollectionEquality().hash(_tags));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BackupDataModelImplCopyWith<_$BackupDataModelImpl> get copyWith =>
      __$$BackupDataModelImplCopyWithImpl<_$BackupDataModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BackupDataModelImplToJson(
      this,
    );
  }
}

abstract class _BackupDataModel implements BackupDataModel {
  const factory _BackupDataModel(
      {required final String version,
      required final DateTime exportedAt,
      required final List<MemoWithTagsModel> memos,
      required final List<TagModel> tags}) = _$BackupDataModelImpl;

  factory _BackupDataModel.fromJson(Map<String, dynamic> json) =
      _$BackupDataModelImpl.fromJson;

  @override
  String get version;
  @override
  DateTime get exportedAt;
  @override
  List<MemoWithTagsModel> get memos;
  @override
  List<TagModel> get tags;
  @override
  @JsonKey(ignore: true)
  _$$BackupDataModelImplCopyWith<_$BackupDataModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
