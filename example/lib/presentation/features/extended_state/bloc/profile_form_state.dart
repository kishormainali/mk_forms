import 'package:mk_forms/mk_forms.dart';

/// Form state extended with one status per independent API call.
class ProfileFormState extends MkFormState {
  const ProfileFormState({
    required super.submissionStatus,
    required super.isValid,
    required super.isValidating,
    required super.isDirty,
    required super.isTouched,
    required super.wasSubmitted,
    required super.values,
    super.submissionError,
    this.avatarStatus = const MkSubmissionStatus.idle(),
    this.usernameStatus = const MkSubmissionStatus.idle(),
    this.otpStatus = const MkSubmissionStatus.idle(),
  });

  factory ProfileFormState.initial(
    Map<String, MkControlBloc<dynamic>> controls,
  ) {
    return ProfileFormState(
      submissionStatus: const MkSubmissionStatus.idle(),
      isValid: controls.values.every((c) => c.isValid),
      isValidating: controls.values.any((c) => c.isValidating),
      isDirty: controls.values.any((c) => c.isDirty),
      isTouched: controls.values.any((c) => c.isTouched),
      wasSubmitted: false,
      values: {for (final e in controls.entries) e.key: e.value.value},
    );
  }

  /// Avatar upload; the success response is the uploaded URL.
  final MkSubmissionStatus avatarStatus;

  /// Username availability check; the success response is a `bool`.
  final MkSubmissionStatus usernameStatus;

  /// OTP request.
  final MkSubmissionStatus otpStatus;

  /// Submit is blocked while any side call is running.
  @override
  bool get isBusy =>
      super.isBusy ||
      avatarStatus.isSubmitting ||
      usernameStatus.isSubmitting ||
      otpStatus.isSubmitting;

  @override
  ProfileFormState copyWith({
    MkSubmissionStatus? submissionStatus,
    bool? isValid,
    bool? isValidating,
    bool? isDirty,
    bool? isTouched,
    bool? wasSubmitted,
    Map<String, dynamic>? values,
    Object? Function()? submissionError,
    MkSubmissionStatus? avatarStatus,
    MkSubmissionStatus? usernameStatus,
    MkSubmissionStatus? otpStatus,
  }) {
    return ProfileFormState(
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
      usernameStatus: usernameStatus ?? this.usernameStatus,
      otpStatus: otpStatus ?? this.otpStatus,
    );
  }

  @override
  ProfileFormState reset({
    required bool isValid,
    required bool isValidating,
    required Map<String, dynamic> values,
  }) {
    return (super.reset(
              isValid: isValid,
              isValidating: isValidating,
              values: values,
            )
            as ProfileFormState)
        .copyWith(
          avatarStatus: const MkSubmissionStatus.idle(),
          usernameStatus: const MkSubmissionStatus.idle(),
          otpStatus: const MkSubmissionStatus.idle(),
        );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    avatarStatus,
    usernameStatus,
    otpStatus,
  ];
}
