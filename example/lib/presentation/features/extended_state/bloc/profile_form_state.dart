import 'package:mk_forms/mk_forms.dart';
import 'profile_extras.dart';

/// Profile form state: the base [MkFormState] plus one [ProfileExtras] holding
/// every status and extra field of this form.
///
/// Only the base fields are written out here. New form-specific fields go in
/// [ProfileExtras] (freezed), so this class does not grow with them.
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
    this.extras = const ProfileExtras(),
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

  /// The form's own statuses and extra fields.
  final ProfileExtras extras;

  /// Returns a copy with [update] applied to [extras].
  ProfileFormState updateExtras(
    ProfileExtras Function(ProfileExtras e) update,
  ) => copyWith(extras: update(extras));

  /// Availability of the username currently typed in the form: `null` unless a
  /// check finished for exactly this value, so a verdict never outlives an edit
  /// and a check that returns late for an older username is ignored.
  bool? get usernameVerdict {
    final current = (values['username'] as String?)?.trim();
    return extras.checkedUsername != null && extras.checkedUsername == current
        ? extras.usernameAvailable
        : null;
  }

  /// [ProfileExtras.usernameStatus] as it should be shown: a finished check
  /// that no longer matches the typed username is shown as idle.
  MkSubmissionStatus get shownUsernameStatus =>
      extras.usernameStatus.isSuccess && usernameVerdict == null
      ? const MkSubmissionStatus.idle()
      : extras.usernameStatus;

  /// Submit is blocked while any side call is running.
  @override
  bool get isBusy => super.isBusy || extras.isBusy;

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
    ProfileExtras? extras,
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
      extras: extras ?? this.extras,
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
        .copyWith(extras: const ProfileExtras());
  }

  @override
  List<Object?> get props => [...super.props, extras];
}
