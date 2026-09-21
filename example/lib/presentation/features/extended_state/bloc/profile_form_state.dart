import 'package:mk_forms/mk_forms.dart';

/// Form state extended with one status per independent API call, plus typed
/// extra fields holding the data those calls produce.
///
/// Statuses answer "how did the call go?" (idle / submitting / success /
/// failure); the extra fields hold "what did it give us?" so the UI reads
/// plain values instead of unpacking a status `response`.
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
    this.avatarUrl,
    this.checkedUsername,
    this.usernameAvailable,
    this.otpSentTo,
    this.submitStage,
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

  /// Avatar upload.
  final MkSubmissionStatus avatarStatus;

  /// Username availability check.
  final MkSubmissionStatus usernameStatus;

  /// OTP request.
  final MkSubmissionStatus otpStatus;

  /// URL of the uploaded avatar; null until an upload succeeds.
  final String? avatarUrl;

  /// The username the last finished availability check was run for.
  final String? checkedUsername;

  /// The result of that check (`true` = available).
  final bool? usernameAvailable;

  /// The phone number the one-time code was sent to.
  final String? otpSentTo;

  /// Human-readable step of the multi-call submit that is running now.
  final String? submitStage;

  /// Availability of the username currently typed in the form: `null` unless a
  /// check finished for exactly this value, so a verdict never outlives an edit
  /// and a check that returns late for an older username is ignored.
  bool? get usernameVerdict {
    final current = (values['username'] as String?)?.trim();
    return checkedUsername != null && checkedUsername == current
        ? usernameAvailable
        : null;
  }

  /// [usernameStatus] as it should be shown: a finished check that no longer
  /// matches the typed username is shown as idle.
  MkSubmissionStatus get shownUsernameStatus =>
      usernameStatus.isSuccess && usernameVerdict == null
      ? const MkSubmissionStatus.idle()
      : usernameStatus;

  /// Submit is blocked while any side call is running.
  @override
  bool get isBusy =>
      super.isBusy ||
      avatarStatus.isSubmitting ||
      usernameStatus.isSubmitting ||
      otpStatus.isSubmitting;

  /// The nullable extras take `T? Function()` so a caller can set them back to
  /// null (`avatarUrl: () => null`), as `submissionError` does in the base.
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
    String? Function()? avatarUrl,
    String? Function()? checkedUsername,
    bool? Function()? usernameAvailable,
    String? Function()? otpSentTo,
    String? Function()? submitStage,
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
      avatarUrl: avatarUrl != null ? avatarUrl() : this.avatarUrl,
      checkedUsername: checkedUsername != null
          ? checkedUsername()
          : this.checkedUsername,
      usernameAvailable: usernameAvailable != null
          ? usernameAvailable()
          : this.usernameAvailable,
      otpSentTo: otpSentTo != null ? otpSentTo() : this.otpSentTo,
      submitStage: submitStage != null ? submitStage() : this.submitStage,
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
          avatarUrl: () => null,
          checkedUsername: () => null,
          usernameAvailable: () => null,
          otpSentTo: () => null,
          submitStage: () => null,
        );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    avatarStatus,
    usernameStatus,
    otpStatus,
    avatarUrl,
    checkedUsername,
    usernameAvailable,
    otpSentTo,
    submitStage,
  ];
}
