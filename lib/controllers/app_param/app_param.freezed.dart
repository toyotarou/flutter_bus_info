// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_param.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppParamState {

 double get currentZoom; int get currentPaddingIndex;
/// Create a copy of AppParamState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppParamStateCopyWith<AppParamState> get copyWith => _$AppParamStateCopyWithImpl<AppParamState>(this as AppParamState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppParamState&&(identical(other.currentZoom, currentZoom) || other.currentZoom == currentZoom)&&(identical(other.currentPaddingIndex, currentPaddingIndex) || other.currentPaddingIndex == currentPaddingIndex));
}


@override
int get hashCode => Object.hash(runtimeType,currentZoom,currentPaddingIndex);

@override
String toString() {
  return 'AppParamState(currentZoom: $currentZoom, currentPaddingIndex: $currentPaddingIndex)';
}


}

/// @nodoc
abstract mixin class $AppParamStateCopyWith<$Res>  {
  factory $AppParamStateCopyWith(AppParamState value, $Res Function(AppParamState) _then) = _$AppParamStateCopyWithImpl;
@useResult
$Res call({
 double currentZoom, int currentPaddingIndex
});




}
/// @nodoc
class _$AppParamStateCopyWithImpl<$Res>
    implements $AppParamStateCopyWith<$Res> {
  _$AppParamStateCopyWithImpl(this._self, this._then);

  final AppParamState _self;
  final $Res Function(AppParamState) _then;

/// Create a copy of AppParamState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentZoom = null,Object? currentPaddingIndex = null,}) {
  return _then(_self.copyWith(
currentZoom: null == currentZoom ? _self.currentZoom : currentZoom // ignore: cast_nullable_to_non_nullable
as double,currentPaddingIndex: null == currentPaddingIndex ? _self.currentPaddingIndex : currentPaddingIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AppParamState].
extension AppParamStatePatterns on AppParamState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppParamState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppParamState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppParamState value)  $default,){
final _that = this;
switch (_that) {
case _AppParamState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppParamState value)?  $default,){
final _that = this;
switch (_that) {
case _AppParamState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double currentZoom,  int currentPaddingIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppParamState() when $default != null:
return $default(_that.currentZoom,_that.currentPaddingIndex);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double currentZoom,  int currentPaddingIndex)  $default,) {final _that = this;
switch (_that) {
case _AppParamState():
return $default(_that.currentZoom,_that.currentPaddingIndex);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double currentZoom,  int currentPaddingIndex)?  $default,) {final _that = this;
switch (_that) {
case _AppParamState() when $default != null:
return $default(_that.currentZoom,_that.currentPaddingIndex);case _:
  return null;

}
}

}

/// @nodoc


class _AppParamState implements AppParamState {
  const _AppParamState({this.currentZoom = 0, this.currentPaddingIndex = 5});
  

@override@JsonKey() final  double currentZoom;
@override@JsonKey() final  int currentPaddingIndex;

/// Create a copy of AppParamState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppParamStateCopyWith<_AppParamState> get copyWith => __$AppParamStateCopyWithImpl<_AppParamState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppParamState&&(identical(other.currentZoom, currentZoom) || other.currentZoom == currentZoom)&&(identical(other.currentPaddingIndex, currentPaddingIndex) || other.currentPaddingIndex == currentPaddingIndex));
}


@override
int get hashCode => Object.hash(runtimeType,currentZoom,currentPaddingIndex);

@override
String toString() {
  return 'AppParamState(currentZoom: $currentZoom, currentPaddingIndex: $currentPaddingIndex)';
}


}

/// @nodoc
abstract mixin class _$AppParamStateCopyWith<$Res> implements $AppParamStateCopyWith<$Res> {
  factory _$AppParamStateCopyWith(_AppParamState value, $Res Function(_AppParamState) _then) = __$AppParamStateCopyWithImpl;
@override @useResult
$Res call({
 double currentZoom, int currentPaddingIndex
});




}
/// @nodoc
class __$AppParamStateCopyWithImpl<$Res>
    implements _$AppParamStateCopyWith<$Res> {
  __$AppParamStateCopyWithImpl(this._self, this._then);

  final _AppParamState _self;
  final $Res Function(_AppParamState) _then;

/// Create a copy of AppParamState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentZoom = null,Object? currentPaddingIndex = null,}) {
  return _then(_AppParamState(
currentZoom: null == currentZoom ? _self.currentZoom : currentZoom // ignore: cast_nullable_to_non_nullable
as double,currentPaddingIndex: null == currentPaddingIndex ? _self.currentPaddingIndex : currentPaddingIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
