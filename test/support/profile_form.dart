import 'dart:async';
import 'package:mk_forms/mk_forms.dart';

/// A form state extended with two independent API-call statuses.
class ProfileState extends MkFormState {
  const ProfileState({
    required super.submissionStatus,
    required super.isValid,
    required super.isValidating,
    required super.isDirty,
    required super.isTouched,
    required super.wasSubmitted,
    required super.values,
    super.submissionError,
    this.avatarStatus = const MkSubmissionStatus.idle(),
    this.otpStatus = const MkSubmissionStatus.idle(),
  });

  factory ProfileState.initial(Map<String, MkControlBloc<dynamic>> controls) {
    return ProfileState(
      submissionStatus: const MkSubmissionStatus.idle(),
      isValid: controls.values.every((c) => c.isValid),
      isValidating: controls.values.any((c) => c.isValidating),
      isDirty: controls.values.any((c) => c.isDirty),
      isTouched: controls.values.any((c) => c.isTouched),
      wasSubmitted: false,
      values: {
        for (final entry in controls.entries) entry.key: entry.value.value,
      },
    );
  }

  final MkSubmissionStatus avatarStatus;
  final MkSubmissionStatus otpStatus;

  @override
  bool get isBusy =>
      super.isBusy || avatarStatus.isSubmitting || otpStatus.isSubmitting;

  @override
  ProfileState copyWith({
    MkSubmissionStatus? submissionStatus,
    bool? isValid,
    bool? isValidating,
    bool? isDirty,
    bool? isTouched,
    bool? wasSubmitted,
    Map<String, dynamic>? values,
    Object? Function()? submissionError,
    MkSubmissionStatus? avatarStatus,
    MkSubmissionStatus? otpStatus,
  }) {
    return ProfileState(
      submissionStatus: submissionStatus ?? this.submissionStatus,
      isValid: isValid ?? this.isValid,
      isValidating: isValidating ?? this.isValidating,
      isDirty: isDirty ?? this.isDirty,
      isTouched: isTouched ?? this.isTouched,
      wasSubmitted: wasSubmitted ?? this.wasSubmitted,
      values: values ?? this.values,
      submissionError: submissionError != null
          ? submissionError()
          : this.submissionError,
      avatarStatus: avatarStatus ?? this.avatarStatus,
      otpStatus: otpStatus ?? this.otpStatus,
    );
  }

  @override
  ProfileState reset({
    required bool isValid,
    required bool isValidating,
    required Map<String, dynamic> values,
  }) {
    return (super.reset(
              isValid: isValid,
              isValidating: isValidating,
              values: values,
            )
            as ProfileState)
        .copyWith(
          avatarStatus: const MkSubmissionStatus.idle(),
          otpStatus: const MkSubmissionStatus.idle(),
        );
  }

  @override
  List<Object?> get props => [...super.props, avatarStatus, otpStatus];
}

/// A form bloc whose two side calls are driven by test-controlled completers.
class ProfileBloc extends MkFormBloc {
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
  ) : super(controls: controls, initialState: ProfileState.initial(controls));

  final Completer<void>? _avatarUpload;
  final Completer<void>? _otpSend;
  int submitCalls = 0;

  @override
  ProfileState get state => super.state as ProfileState;

  Future<void> uploadAvatar() =>
      _track(_avatarUpload!, (s) => state.copyWith(avatarStatus: s));

  Future<void> sendOtp() =>
      _track(_otpSend!, (s) => state.copyWith(otpStatus: s));

  Future<void> _track(
    Completer<void> call,
    ProfileState Function(MkSubmissionStatus status) apply,
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
