import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:mk_forms/mk_forms.dart';

/// Extra fields held in [ProfileBloc]'s [MkFormState.extra]: two independent
/// API-call statuses.
///
/// Extends [Equatable] because `extra` feeds `MkFormState`'s own equality
/// directly — an extra type without value equality would make state
/// equality (and `buildWhen` dedup) fall back to identity.
class ProfileExtra extends Equatable {
  const ProfileExtra({
    this.avatarStatus = const MkSubmissionStatus.idle(),
    this.otpStatus = const MkSubmissionStatus.idle(),
  });

  final MkSubmissionStatus avatarStatus;
  final MkSubmissionStatus otpStatus;

  bool get isBusy => avatarStatus.isSubmitting || otpStatus.isSubmitting;

  ProfileExtra copyWith({
    MkSubmissionStatus? avatarStatus,
    MkSubmissionStatus? otpStatus,
  }) {
    return ProfileExtra(
      avatarStatus: avatarStatus ?? this.avatarStatus,
      otpStatus: otpStatus ?? this.otpStatus,
    );
  }

  @override
  List<Object?> get props => [avatarStatus, otpStatus];
}

/// A form bloc whose two side calls are driven by test-controlled completers.
class ProfileBloc extends MkFormBloc<ProfileExtra> {
  ProfileBloc({Completer<void>? avatarUpload, Completer<void>? otpSend})
    : this._(avatarUpload, otpSend, {
        'name': MkFieldBloc<String>(
          initialValue: '',
          validators: [MkValidators.required()],
        ),
      });

  ProfileBloc._(
    this._avatarUpload,
    this._otpSend,
    Map<String, MkControlBloc<dynamic>> controls,
  ) : super(
        controls: controls,
        initialState: MkFormState<ProfileExtra>(
          submissionStatus: const MkSubmissionStatus.idle(),
          isValid: controls.values.every((c) => c.isValid),
          isValidating: controls.values.any((c) => c.isValidating),
          isDirty: controls.values.any((c) => c.isDirty),
          isTouched: controls.values.any((c) => c.isTouched),
          wasSubmitted: false,
          values: {
            for (final entry in controls.entries)
              entry.key: entry.value.value,
          },
          extra: const ProfileExtra(),
          extraReset: () => const ProfileExtra(),
          isExtraBusy: (e) => e.isBusy,
        ),
      );

  final Completer<void>? _avatarUpload;
  final Completer<void>? _otpSend;
  int submitCalls = 0;

  Future<void> uploadAvatar() => _track(
    _avatarUpload!,
    (status) => state.updateExtra((e) => e.copyWith(avatarStatus: status)),
  );

  Future<void> sendOtp() => _track(
    _otpSend!,
    (status) => state.updateExtra((e) => e.copyWith(otpStatus: status)),
  );

  Future<void> _track(
    Completer<void> call,
    MkFormState<ProfileExtra> Function(MkSubmissionStatus status) apply,
  ) async {
    emit(apply(const MkSubmissionStatus.submitting()));
    try {
      await call.future;
      emit(apply(const MkSubmissionStatus.success()));
    } catch (error) {
      emit(apply(MkSubmissionStatus.failure(error)));
    }
  }

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async {
    submitCalls++;
    return 'ok';
  }
}
