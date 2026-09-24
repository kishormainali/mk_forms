// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_extras.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProfileExtras {

/// Avatar upload.
 MkSubmissionStatus get avatarStatus;/// Username availability check.
 MkSubmissionStatus get usernameStatus;/// OTP request.
 MkSubmissionStatus get otpStatus;/// URL of the uploaded avatar; null until an upload succeeds.
 String? get avatarUrl;/// The username the last finished availability check was run for.
 String? get checkedUsername;/// The result of that check (`true` = available).
 bool? get usernameAvailable;/// The phone number the one-time code was sent to.
 String? get otpSentTo;/// Human-readable step of the multi-call submit that is running now.
 String? get submitStage;
/// Create a copy of ProfileExtras
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileExtrasCopyWith<ProfileExtras> get copyWith => _$ProfileExtrasCopyWithImpl<ProfileExtras>(this as ProfileExtras, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProfileExtras;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileExtras&&(identical(other.avatarStatus, _this.avatarStatus) || other.avatarStatus == _this.avatarStatus)&&(identical(other.usernameStatus, _this.usernameStatus) || other.usernameStatus == _this.usernameStatus)&&(identical(other.otpStatus, _this.otpStatus) || other.otpStatus == _this.otpStatus)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl)&&(identical(other.checkedUsername, _this.checkedUsername) || other.checkedUsername == _this.checkedUsername)&&(identical(other.usernameAvailable, _this.usernameAvailable) || other.usernameAvailable == _this.usernameAvailable)&&(identical(other.otpSentTo, _this.otpSentTo) || other.otpSentTo == _this.otpSentTo)&&(identical(other.submitStage, _this.submitStage) || other.submitStage == _this.submitStage));
}


@override
int get hashCode {
  final _this = this as ProfileExtras;
  return Object.hash(runtimeType,_this.avatarStatus,_this.usernameStatus,_this.otpStatus,_this.avatarUrl,_this.checkedUsername,_this.usernameAvailable,_this.otpSentTo,_this.submitStage);
}

@override
String toString() {
  final _this = this as ProfileExtras;
  return 'ProfileExtras(avatarStatus: ${_this.avatarStatus}, usernameStatus: ${_this.usernameStatus}, otpStatus: ${_this.otpStatus}, avatarUrl: ${_this.avatarUrl}, checkedUsername: ${_this.checkedUsername}, usernameAvailable: ${_this.usernameAvailable}, otpSentTo: ${_this.otpSentTo}, submitStage: ${_this.submitStage})';
}


}

/// @nodoc
abstract mixin class $ProfileExtrasCopyWith<$Res>  {
  factory $ProfileExtrasCopyWith(ProfileExtras value, $Res Function(ProfileExtras) _then) = _$ProfileExtrasCopyWithImpl;
@useResult
$Res call({
 MkSubmissionStatus avatarStatus, MkSubmissionStatus usernameStatus, MkSubmissionStatus otpStatus, String? avatarUrl, String? checkedUsername, bool? usernameAvailable, String? otpSentTo, String? submitStage
});




}
/// @nodoc
class _$ProfileExtrasCopyWithImpl<$Res>
    implements $ProfileExtrasCopyWith<$Res> {
  _$ProfileExtrasCopyWithImpl(this._self, this._then);

  final ProfileExtras _self;
  final $Res Function(ProfileExtras) _then;

/// Create a copy of ProfileExtras
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? avatarStatus = null,Object? usernameStatus = null,Object? otpStatus = null,Object? avatarUrl = freezed,Object? checkedUsername = freezed,Object? usernameAvailable = freezed,Object? otpSentTo = freezed,Object? submitStage = freezed,}) {
  return _then(ProfileExtras(
avatarStatus: null == avatarStatus ? _self.avatarStatus : avatarStatus // ignore: cast_nullable_to_non_nullable
as MkSubmissionStatus,usernameStatus: null == usernameStatus ? _self.usernameStatus : usernameStatus // ignore: cast_nullable_to_non_nullable
as MkSubmissionStatus,otpStatus: null == otpStatus ? _self.otpStatus : otpStatus // ignore: cast_nullable_to_non_nullable
as MkSubmissionStatus,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,checkedUsername: freezed == checkedUsername ? _self.checkedUsername : checkedUsername // ignore: cast_nullable_to_non_nullable
as String?,usernameAvailable: freezed == usernameAvailable ? _self.usernameAvailable : usernameAvailable // ignore: cast_nullable_to_non_nullable
as bool?,otpSentTo: freezed == otpSentTo ? _self.otpSentTo : otpSentTo // ignore: cast_nullable_to_non_nullable
as String?,submitStage: freezed == submitStage ? _self.submitStage : submitStage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileExtras].
extension ProfileExtrasPatterns on ProfileExtras {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileExtras value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileExtras() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileExtras value)  $default,){
final _that = this;
switch (_that) {
case _ProfileExtras():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileExtras value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileExtras() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MkSubmissionStatus avatarStatus,  MkSubmissionStatus usernameStatus,  MkSubmissionStatus otpStatus,  String? avatarUrl,  String? checkedUsername,  bool? usernameAvailable,  String? otpSentTo,  String? submitStage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileExtras() when $default != null:
return $default(_that.avatarStatus,_that.usernameStatus,_that.otpStatus,_that.avatarUrl,_that.checkedUsername,_that.usernameAvailable,_that.otpSentTo,_that.submitStage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MkSubmissionStatus avatarStatus,  MkSubmissionStatus usernameStatus,  MkSubmissionStatus otpStatus,  String? avatarUrl,  String? checkedUsername,  bool? usernameAvailable,  String? otpSentTo,  String? submitStage)  $default,) {final _that = this;
switch (_that) {
case _ProfileExtras():
return $default(_that.avatarStatus,_that.usernameStatus,_that.otpStatus,_that.avatarUrl,_that.checkedUsername,_that.usernameAvailable,_that.otpSentTo,_that.submitStage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MkSubmissionStatus avatarStatus,  MkSubmissionStatus usernameStatus,  MkSubmissionStatus otpStatus,  String? avatarUrl,  String? checkedUsername,  bool? usernameAvailable,  String? otpSentTo,  String? submitStage)?  $default,) {final _that = this;
switch (_that) {
case _ProfileExtras() when $default != null:
return $default(_that.avatarStatus,_that.usernameStatus,_that.otpStatus,_that.avatarUrl,_that.checkedUsername,_that.usernameAvailable,_that.otpSentTo,_that.submitStage);case _:
  return null;

}
}

}

/// @nodoc


class _ProfileExtras extends ProfileExtras {
  const _ProfileExtras({this.avatarStatus = const MkSubmissionStatus.idle(), this.usernameStatus = const MkSubmissionStatus.idle(), this.otpStatus = const MkSubmissionStatus.idle(), this.avatarUrl, this.checkedUsername, this.usernameAvailable, this.otpSentTo, this.submitStage}): super._();
  

/// Avatar upload.
@override@JsonKey() final  MkSubmissionStatus avatarStatus;
/// Username availability check.
@override@JsonKey() final  MkSubmissionStatus usernameStatus;
/// OTP request.
@override@JsonKey() final  MkSubmissionStatus otpStatus;
/// URL of the uploaded avatar; null until an upload succeeds.
@override final  String? avatarUrl;
/// The username the last finished availability check was run for.
@override final  String? checkedUsername;
/// The result of that check (`true` = available).
@override final  bool? usernameAvailable;
/// The phone number the one-time code was sent to.
@override final  String? otpSentTo;
/// Human-readable step of the multi-call submit that is running now.
@override final  String? submitStage;

/// Create a copy of ProfileExtras
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileExtrasCopyWith<_ProfileExtras> get copyWith => __$ProfileExtrasCopyWithImpl<_ProfileExtras>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileExtras&&(identical(other.avatarStatus, avatarStatus) || other.avatarStatus == avatarStatus)&&(identical(other.usernameStatus, usernameStatus) || other.usernameStatus == usernameStatus)&&(identical(other.otpStatus, otpStatus) || other.otpStatus == otpStatus)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.checkedUsername, checkedUsername) || other.checkedUsername == checkedUsername)&&(identical(other.usernameAvailable, usernameAvailable) || other.usernameAvailable == usernameAvailable)&&(identical(other.otpSentTo, otpSentTo) || other.otpSentTo == otpSentTo)&&(identical(other.submitStage, submitStage) || other.submitStage == submitStage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,avatarStatus,usernameStatus,otpStatus,avatarUrl,checkedUsername,usernameAvailable,otpSentTo,submitStage);
}

@override
String toString() {
    return 'ProfileExtras(avatarStatus: $avatarStatus, usernameStatus: $usernameStatus, otpStatus: $otpStatus, avatarUrl: $avatarUrl, checkedUsername: $checkedUsername, usernameAvailable: $usernameAvailable, otpSentTo: $otpSentTo, submitStage: $submitStage)';
}


}

/// @nodoc
abstract mixin class _$ProfileExtrasCopyWith<$Res> implements $ProfileExtrasCopyWith<$Res> {
  factory _$ProfileExtrasCopyWith(_ProfileExtras value, $Res Function(_ProfileExtras) _then) = __$ProfileExtrasCopyWithImpl;
@override @useResult
$Res call({
 MkSubmissionStatus avatarStatus, MkSubmissionStatus usernameStatus, MkSubmissionStatus otpStatus, String? avatarUrl, String? checkedUsername, bool? usernameAvailable, String? otpSentTo, String? submitStage
});




}
/// @nodoc
class __$ProfileExtrasCopyWithImpl<$Res>
    implements _$ProfileExtrasCopyWith<$Res> {
  __$ProfileExtrasCopyWithImpl(this._self, this._then);

  final _ProfileExtras _self;
  final $Res Function(_ProfileExtras) _then;

/// Create a copy of ProfileExtras
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? avatarStatus = null,Object? usernameStatus = null,Object? otpStatus = null,Object? avatarUrl = freezed,Object? checkedUsername = freezed,Object? usernameAvailable = freezed,Object? otpSentTo = freezed,Object? submitStage = freezed,}) {
  return _then(_ProfileExtras(
avatarStatus: null == avatarStatus ? _self.avatarStatus : avatarStatus // ignore: cast_nullable_to_non_nullable
as MkSubmissionStatus,usernameStatus: null == usernameStatus ? _self.usernameStatus : usernameStatus // ignore: cast_nullable_to_non_nullable
as MkSubmissionStatus,otpStatus: null == otpStatus ? _self.otpStatus : otpStatus // ignore: cast_nullable_to_non_nullable
as MkSubmissionStatus,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,checkedUsername: freezed == checkedUsername ? _self.checkedUsername : checkedUsername // ignore: cast_nullable_to_non_nullable
as String?,usernameAvailable: freezed == usernameAvailable ? _self.usernameAvailable : usernameAvailable // ignore: cast_nullable_to_non_nullable
as bool?,otpSentTo: freezed == otpSentTo ? _self.otpSentTo : otpSentTo // ignore: cast_nullable_to_non_nullable
as String?,submitStage: freezed == submitStage ? _self.submitStage : submitStage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
