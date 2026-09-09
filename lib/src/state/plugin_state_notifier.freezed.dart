// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plugin_state_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlayerPluginState {

 String? get primaryPlayerId; Map<String, PlayerStateNotifier> get players;
/// Create a copy of PlayerPluginState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerPluginStateCopyWith<PlayerPluginState> get copyWith => _$PlayerPluginStateCopyWithImpl<PlayerPluginState>(this as PlayerPluginState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlayerPluginState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerPluginState&&(identical(other.primaryPlayerId, _this.primaryPlayerId) || other.primaryPlayerId == _this.primaryPlayerId)&&const DeepCollectionEquality().equals(other.players, _this.players));
}


@override
int get hashCode {
  final _this = this as PlayerPluginState;
  return Object.hash(runtimeType,_this.primaryPlayerId,const DeepCollectionEquality().hash(_this.players));
}

@override
String toString() {
  final _this = this as PlayerPluginState;
  return 'PlayerPluginState(primaryPlayerId: ${_this.primaryPlayerId}, players: ${_this.players})';
}


}

/// @nodoc
abstract mixin class $PlayerPluginStateCopyWith<$Res>  {
  factory $PlayerPluginStateCopyWith(PlayerPluginState value, $Res Function(PlayerPluginState) _then) = _$PlayerPluginStateCopyWithImpl;
@useResult
$Res call({
 String? primaryPlayerId, Map<String, PlayerStateNotifier> players
});




}
/// @nodoc
class _$PlayerPluginStateCopyWithImpl<$Res>
    implements $PlayerPluginStateCopyWith<$Res> {
  _$PlayerPluginStateCopyWithImpl(this._self, this._then);

  final PlayerPluginState _self;
  final $Res Function(PlayerPluginState) _then;

/// Create a copy of PlayerPluginState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? primaryPlayerId = freezed,Object? players = null,}) {
  return _then(PlayerPluginState(
primaryPlayerId: freezed == primaryPlayerId ? _self.primaryPlayerId : primaryPlayerId // ignore: cast_nullable_to_non_nullable
as String?,players: null == players ? _self.players : players // ignore: cast_nullable_to_non_nullable
as Map<String, PlayerStateNotifier>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerPluginState].
extension PlayerPluginStatePatterns on PlayerPluginState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerPluginState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerPluginState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerPluginState value)  $default,){
final _that = this;
switch (_that) {
case _PlayerPluginState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerPluginState value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerPluginState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? primaryPlayerId,  Map<String, PlayerStateNotifier> players)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerPluginState() when $default != null:
return $default(_that.primaryPlayerId,_that.players);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? primaryPlayerId,  Map<String, PlayerStateNotifier> players)  $default,) {final _that = this;
switch (_that) {
case _PlayerPluginState():
return $default(_that.primaryPlayerId,_that.players);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? primaryPlayerId,  Map<String, PlayerStateNotifier> players)?  $default,) {final _that = this;
switch (_that) {
case _PlayerPluginState() when $default != null:
return $default(_that.primaryPlayerId,_that.players);case _:
  return null;

}
}

}

/// @nodoc


class _PlayerPluginState implements PlayerPluginState {
  const _PlayerPluginState({required this.primaryPlayerId, required  Map<String, PlayerStateNotifier> players}): _players = players;
  

@override final  String? primaryPlayerId;
 final  Map<String, PlayerStateNotifier> _players;
@override Map<String, PlayerStateNotifier> get players {
  if (_players is EqualUnmodifiableMapView) return _players;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_players);
}


/// Create a copy of PlayerPluginState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerPluginStateCopyWith<_PlayerPluginState> get copyWith => __$PlayerPluginStateCopyWithImpl<_PlayerPluginState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerPluginState&&(identical(other.primaryPlayerId, primaryPlayerId) || other.primaryPlayerId == primaryPlayerId)&&const DeepCollectionEquality().equals(other.players, _players));
}


@override
int get hashCode {
    return Object.hash(runtimeType,primaryPlayerId,const DeepCollectionEquality().hash(_players));
}

@override
String toString() {
    return 'PlayerPluginState(primaryPlayerId: $primaryPlayerId, players: $players)';
}


}

/// @nodoc
abstract mixin class _$PlayerPluginStateCopyWith<$Res> implements $PlayerPluginStateCopyWith<$Res> {
  factory _$PlayerPluginStateCopyWith(_PlayerPluginState value, $Res Function(_PlayerPluginState) _then) = __$PlayerPluginStateCopyWithImpl;
@override @useResult
$Res call({
 String? primaryPlayerId, Map<String, PlayerStateNotifier> players
});




}
/// @nodoc
class __$PlayerPluginStateCopyWithImpl<$Res>
    implements _$PlayerPluginStateCopyWith<$Res> {
  __$PlayerPluginStateCopyWithImpl(this._self, this._then);

  final _PlayerPluginState _self;
  final $Res Function(_PlayerPluginState) _then;

/// Create a copy of PlayerPluginState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? primaryPlayerId = freezed,Object? players = null,}) {
  return _then(_PlayerPluginState(
primaryPlayerId: freezed == primaryPlayerId ? _self.primaryPlayerId : primaryPlayerId // ignore: cast_nullable_to_non_nullable
as String?,players: null == players ? _self._players : players // ignore: cast_nullable_to_non_nullable
as Map<String, PlayerStateNotifier>,
  ));
}


}

// dart format on
