// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_state_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlayerState implements DiagnosticableTreeMixin {

 String get playerId; MediaItem? get currentMediaItem; VideoSize? get videoSize; int? get playbackPositionMs; double get playbackSpeed; bool get isNativeFullscreen; PlaybackState get playbackState; bool get isBuffering; bool get isInPipMode; bool get isInitialized; int? get textureId; double? get volume; PlayerError? get error;
/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerStateCopyWith<PlayerState> get copyWith => _$PlayerStateCopyWithImpl<PlayerState>(this as PlayerState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  final _this = this as PlayerState;
  properties
    ..add(DiagnosticsProperty('type', 'PlayerState'))
    ..add(DiagnosticsProperty('playerId', _this.playerId))..add(DiagnosticsProperty('currentMediaItem', _this.currentMediaItem))..add(DiagnosticsProperty('videoSize', _this.videoSize))..add(DiagnosticsProperty('playbackPositionMs', _this.playbackPositionMs))..add(DiagnosticsProperty('playbackSpeed', _this.playbackSpeed))..add(DiagnosticsProperty('isNativeFullscreen', _this.isNativeFullscreen))..add(DiagnosticsProperty('playbackState', _this.playbackState))..add(DiagnosticsProperty('isBuffering', _this.isBuffering))..add(DiagnosticsProperty('isInPipMode', _this.isInPipMode))..add(DiagnosticsProperty('isInitialized', _this.isInitialized))..add(DiagnosticsProperty('textureId', _this.textureId))..add(DiagnosticsProperty('volume', _this.volume))..add(DiagnosticsProperty('error', _this.error));
}

@override
bool operator ==(Object other) {
  final _this = this as PlayerState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerState&&(identical(other.playerId, _this.playerId) || other.playerId == _this.playerId)&&(identical(other.currentMediaItem, _this.currentMediaItem) || other.currentMediaItem == _this.currentMediaItem)&&(identical(other.videoSize, _this.videoSize) || other.videoSize == _this.videoSize)&&(identical(other.playbackPositionMs, _this.playbackPositionMs) || other.playbackPositionMs == _this.playbackPositionMs)&&(identical(other.playbackSpeed, _this.playbackSpeed) || other.playbackSpeed == _this.playbackSpeed)&&(identical(other.isNativeFullscreen, _this.isNativeFullscreen) || other.isNativeFullscreen == _this.isNativeFullscreen)&&(identical(other.playbackState, _this.playbackState) || other.playbackState == _this.playbackState)&&(identical(other.isBuffering, _this.isBuffering) || other.isBuffering == _this.isBuffering)&&(identical(other.isInPipMode, _this.isInPipMode) || other.isInPipMode == _this.isInPipMode)&&(identical(other.isInitialized, _this.isInitialized) || other.isInitialized == _this.isInitialized)&&(identical(other.textureId, _this.textureId) || other.textureId == _this.textureId)&&(identical(other.volume, _this.volume) || other.volume == _this.volume)&&(identical(other.error, _this.error) || other.error == _this.error));
}


@override
int get hashCode {
  final _this = this as PlayerState;
  return Object.hash(runtimeType,_this.playerId,_this.currentMediaItem,_this.videoSize,_this.playbackPositionMs,_this.playbackSpeed,_this.isNativeFullscreen,_this.playbackState,_this.isBuffering,_this.isInPipMode,_this.isInitialized,_this.textureId,_this.volume,_this.error);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  final _this = this as PlayerState;
  return 'PlayerState(playerId: ${_this.playerId}, currentMediaItem: ${_this.currentMediaItem}, videoSize: ${_this.videoSize}, playbackPositionMs: ${_this.playbackPositionMs}, playbackSpeed: ${_this.playbackSpeed}, isNativeFullscreen: ${_this.isNativeFullscreen}, playbackState: ${_this.playbackState}, isBuffering: ${_this.isBuffering}, isInPipMode: ${_this.isInPipMode}, isInitialized: ${_this.isInitialized}, textureId: ${_this.textureId}, volume: ${_this.volume}, error: ${_this.error})';
}


}

/// @nodoc
abstract mixin class $PlayerStateCopyWith<$Res>  {
  factory $PlayerStateCopyWith(PlayerState value, $Res Function(PlayerState) _then) = _$PlayerStateCopyWithImpl;
@useResult
$Res call({
 String playerId, MediaItem? currentMediaItem, VideoSize? videoSize, int? playbackPositionMs, double playbackSpeed, bool isNativeFullscreen, PlaybackState playbackState, bool isBuffering, bool isInPipMode, bool isInitialized, int? textureId, double? volume, PlayerError? error
});




}
/// @nodoc
class _$PlayerStateCopyWithImpl<$Res>
    implements $PlayerStateCopyWith<$Res> {
  _$PlayerStateCopyWithImpl(this._self, this._then);

  final PlayerState _self;
  final $Res Function(PlayerState) _then;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerId = null,Object? currentMediaItem = freezed,Object? videoSize = freezed,Object? playbackPositionMs = freezed,Object? playbackSpeed = null,Object? isNativeFullscreen = null,Object? playbackState = null,Object? isBuffering = null,Object? isInPipMode = null,Object? isInitialized = null,Object? textureId = freezed,Object? volume = freezed,Object? error = freezed,}) {
  return _then(PlayerState(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,currentMediaItem: freezed == currentMediaItem ? _self.currentMediaItem : currentMediaItem // ignore: cast_nullable_to_non_nullable
as MediaItem?,videoSize: freezed == videoSize ? _self.videoSize : videoSize // ignore: cast_nullable_to_non_nullable
as VideoSize?,playbackPositionMs: freezed == playbackPositionMs ? _self.playbackPositionMs : playbackPositionMs // ignore: cast_nullable_to_non_nullable
as int?,playbackSpeed: null == playbackSpeed ? _self.playbackSpeed : playbackSpeed // ignore: cast_nullable_to_non_nullable
as double,isNativeFullscreen: null == isNativeFullscreen ? _self.isNativeFullscreen : isNativeFullscreen // ignore: cast_nullable_to_non_nullable
as bool,playbackState: null == playbackState ? _self.playbackState : playbackState // ignore: cast_nullable_to_non_nullable
as PlaybackState,isBuffering: null == isBuffering ? _self.isBuffering : isBuffering // ignore: cast_nullable_to_non_nullable
as bool,isInPipMode: null == isInPipMode ? _self.isInPipMode : isInPipMode // ignore: cast_nullable_to_non_nullable
as bool,isInitialized: null == isInitialized ? _self.isInitialized : isInitialized // ignore: cast_nullable_to_non_nullable
as bool,textureId: freezed == textureId ? _self.textureId : textureId // ignore: cast_nullable_to_non_nullable
as int?,volume: freezed == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as PlayerError?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerState].
extension PlayerStatePatterns on PlayerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerState value)  $default,){
final _that = this;
switch (_that) {
case _PlayerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerState value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String playerId,  MediaItem? currentMediaItem,  VideoSize? videoSize,  int? playbackPositionMs,  double playbackSpeed,  bool isNativeFullscreen,  PlaybackState playbackState,  bool isBuffering,  bool isInPipMode,  bool isInitialized,  int? textureId,  double? volume,  PlayerError? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
return $default(_that.playerId,_that.currentMediaItem,_that.videoSize,_that.playbackPositionMs,_that.playbackSpeed,_that.isNativeFullscreen,_that.playbackState,_that.isBuffering,_that.isInPipMode,_that.isInitialized,_that.textureId,_that.volume,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String playerId,  MediaItem? currentMediaItem,  VideoSize? videoSize,  int? playbackPositionMs,  double playbackSpeed,  bool isNativeFullscreen,  PlaybackState playbackState,  bool isBuffering,  bool isInPipMode,  bool isInitialized,  int? textureId,  double? volume,  PlayerError? error)  $default,) {final _that = this;
switch (_that) {
case _PlayerState():
return $default(_that.playerId,_that.currentMediaItem,_that.videoSize,_that.playbackPositionMs,_that.playbackSpeed,_that.isNativeFullscreen,_that.playbackState,_that.isBuffering,_that.isInPipMode,_that.isInitialized,_that.textureId,_that.volume,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String playerId,  MediaItem? currentMediaItem,  VideoSize? videoSize,  int? playbackPositionMs,  double playbackSpeed,  bool isNativeFullscreen,  PlaybackState playbackState,  bool isBuffering,  bool isInPipMode,  bool isInitialized,  int? textureId,  double? volume,  PlayerError? error)?  $default,) {final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
return $default(_that.playerId,_that.currentMediaItem,_that.videoSize,_that.playbackPositionMs,_that.playbackSpeed,_that.isNativeFullscreen,_that.playbackState,_that.isBuffering,_that.isInPipMode,_that.isInitialized,_that.textureId,_that.volume,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _PlayerState extends PlayerState with DiagnosticableTreeMixin {
  const _PlayerState({required this.playerId, this.currentMediaItem, this.videoSize, this.playbackPositionMs, this.playbackSpeed = 1.0, this.isNativeFullscreen = false, this.playbackState = PlaybackState.stopped, this.isBuffering = false, this.isInPipMode = false, this.isInitialized = false, this.textureId, this.volume, this.error}): super._();
  

@override final  String playerId;
@override final  MediaItem? currentMediaItem;
@override final  VideoSize? videoSize;
@override final  int? playbackPositionMs;
@override@JsonKey() final  double playbackSpeed;
@override@JsonKey() final  bool isNativeFullscreen;
@override@JsonKey() final  PlaybackState playbackState;
@override@JsonKey() final  bool isBuffering;
@override@JsonKey() final  bool isInPipMode;
@override@JsonKey() final  bool isInitialized;
@override final  int? textureId;
@override final  double? volume;
@override final  PlayerError? error;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerStateCopyWith<_PlayerState> get copyWith => __$PlayerStateCopyWithImpl<_PlayerState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
    ..add(DiagnosticsProperty('type', 'PlayerState'))
    ..add(DiagnosticsProperty('playerId', playerId))..add(DiagnosticsProperty('currentMediaItem', currentMediaItem))..add(DiagnosticsProperty('videoSize', videoSize))..add(DiagnosticsProperty('playbackPositionMs', playbackPositionMs))..add(DiagnosticsProperty('playbackSpeed', playbackSpeed))..add(DiagnosticsProperty('isNativeFullscreen', isNativeFullscreen))..add(DiagnosticsProperty('playbackState', playbackState))..add(DiagnosticsProperty('isBuffering', isBuffering))..add(DiagnosticsProperty('isInPipMode', isInPipMode))..add(DiagnosticsProperty('isInitialized', isInitialized))..add(DiagnosticsProperty('textureId', textureId))..add(DiagnosticsProperty('volume', volume))..add(DiagnosticsProperty('error', error));
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerState&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.currentMediaItem, currentMediaItem) || other.currentMediaItem == currentMediaItem)&&(identical(other.videoSize, videoSize) || other.videoSize == videoSize)&&(identical(other.playbackPositionMs, playbackPositionMs) || other.playbackPositionMs == playbackPositionMs)&&(identical(other.playbackSpeed, playbackSpeed) || other.playbackSpeed == playbackSpeed)&&(identical(other.isNativeFullscreen, isNativeFullscreen) || other.isNativeFullscreen == isNativeFullscreen)&&(identical(other.playbackState, playbackState) || other.playbackState == playbackState)&&(identical(other.isBuffering, isBuffering) || other.isBuffering == isBuffering)&&(identical(other.isInPipMode, isInPipMode) || other.isInPipMode == isInPipMode)&&(identical(other.isInitialized, isInitialized) || other.isInitialized == isInitialized)&&(identical(other.textureId, textureId) || other.textureId == textureId)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode {
    return Object.hash(runtimeType,playerId,currentMediaItem,videoSize,playbackPositionMs,playbackSpeed,isNativeFullscreen,playbackState,isBuffering,isInPipMode,isInitialized,textureId,volume,error);
}

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
    return 'PlayerState(playerId: $playerId, currentMediaItem: $currentMediaItem, videoSize: $videoSize, playbackPositionMs: $playbackPositionMs, playbackSpeed: $playbackSpeed, isNativeFullscreen: $isNativeFullscreen, playbackState: $playbackState, isBuffering: $isBuffering, isInPipMode: $isInPipMode, isInitialized: $isInitialized, textureId: $textureId, volume: $volume, error: $error)';
}


}

/// @nodoc
abstract mixin class _$PlayerStateCopyWith<$Res> implements $PlayerStateCopyWith<$Res> {
  factory _$PlayerStateCopyWith(_PlayerState value, $Res Function(_PlayerState) _then) = __$PlayerStateCopyWithImpl;
@override @useResult
$Res call({
 String playerId, MediaItem? currentMediaItem, VideoSize? videoSize, int? playbackPositionMs, double playbackSpeed, bool isNativeFullscreen, PlaybackState playbackState, bool isBuffering, bool isInPipMode, bool isInitialized, int? textureId, double? volume, PlayerError? error
});




}
/// @nodoc
class __$PlayerStateCopyWithImpl<$Res>
    implements _$PlayerStateCopyWith<$Res> {
  __$PlayerStateCopyWithImpl(this._self, this._then);

  final _PlayerState _self;
  final $Res Function(_PlayerState) _then;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerId = null,Object? currentMediaItem = freezed,Object? videoSize = freezed,Object? playbackPositionMs = freezed,Object? playbackSpeed = null,Object? isNativeFullscreen = null,Object? playbackState = null,Object? isBuffering = null,Object? isInPipMode = null,Object? isInitialized = null,Object? textureId = freezed,Object? volume = freezed,Object? error = freezed,}) {
  return _then(_PlayerState(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,currentMediaItem: freezed == currentMediaItem ? _self.currentMediaItem : currentMediaItem // ignore: cast_nullable_to_non_nullable
as MediaItem?,videoSize: freezed == videoSize ? _self.videoSize : videoSize // ignore: cast_nullable_to_non_nullable
as VideoSize?,playbackPositionMs: freezed == playbackPositionMs ? _self.playbackPositionMs : playbackPositionMs // ignore: cast_nullable_to_non_nullable
as int?,playbackSpeed: null == playbackSpeed ? _self.playbackSpeed : playbackSpeed // ignore: cast_nullable_to_non_nullable
as double,isNativeFullscreen: null == isNativeFullscreen ? _self.isNativeFullscreen : isNativeFullscreen // ignore: cast_nullable_to_non_nullable
as bool,playbackState: null == playbackState ? _self.playbackState : playbackState // ignore: cast_nullable_to_non_nullable
as PlaybackState,isBuffering: null == isBuffering ? _self.isBuffering : isBuffering // ignore: cast_nullable_to_non_nullable
as bool,isInPipMode: null == isInPipMode ? _self.isInPipMode : isInPipMode // ignore: cast_nullable_to_non_nullable
as bool,isInitialized: null == isInitialized ? _self.isInitialized : isInitialized // ignore: cast_nullable_to_non_nullable
as bool,textureId: freezed == textureId ? _self.textureId : textureId // ignore: cast_nullable_to_non_nullable
as int?,volume: freezed == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as PlayerError?,
  ));
}


}

// dart format on
