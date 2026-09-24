import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import '../../core/status.dart';

/// Represents the overall state of an [MkFormBloc].
///
/// [T] is the type of [extra]: a single slot for whatever a form needs
/// beyond the base fields (independent statuses, extra data). Most forms
/// never need it and can ignore the type parameter entirely — plain
/// `MkFormState` (no type argument) resolves to `MkFormState<Object?>` with
/// `extra` left `null`.
class MkFormState<T extends Object?> extends Equatable {
  const MkFormState({
    required this.submissionStatus,
    required this.isValid,
    required this.isValidating,
    required this.isDirty,
    required this.isTouched,
    required this.wasSubmitted,
    required this.values,
    this.submissionError,
    required this.extra,
    this.extraReset,
    this.isExtraBusy,
  });

  /// Current submission lifecycle status (idle, submitting, success, failure).
  final MkSubmissionStatus submissionStatus;

  /// Whether all fields in the form are valid.
  final bool isValid;

  /// Whether any field in the form is performing asynchronous validation.
  final bool isValidating;

  /// Whether any field has been modified from its initial value.
  final bool isDirty;

  /// Whether any field has been touched.
  final bool isTouched;

  /// Whether the user has attempted to submit the form at least once.
  final bool wasSubmitted;

  /// Aggregated values of all controls in the form.
  final Map<String, dynamic> values;

  /// The error object if the last submission failed, or null.
  final Object? submissionError;

  /// App-defined payload: statuses and extra fields beyond the base ones.
  ///
  /// Field edits never touch this: [MkFormBloc] only calls [copyWith] with
  /// the base fields, so the same [extra] instance carries through every
  /// edit untouched. Update it explicitly with [updateExtra] or `copyWith`.
  final T extra;

  /// Regenerates a pristine [extra] on [reset]. If omitted, [reset] leaves
  /// [extra] unchanged.
  ///
  /// Marked `@protected`: part of the constructor's public surface (an app
  /// sets it once when building its bloc's initial state) but not meant to
  /// be read outside a state's own `copyWith`/`reset` chain. It is a plain
  /// (non-underscore) field rather than Dart-private, because
  /// `MkStepFormState` (a different file/library) must read it from its own
  /// `copyWith`/`reset` overrides — Dart privacy is per-library.
  @protected
  final T Function()? extraReset;

  /// Feeds [isBusy]. If omitted, [extra] never contributes to [isBusy].
  /// Same visibility rationale as [extraReset].
  @protected
  final bool Function(T extra)? isExtraBusy;

  /// Whether the form can currently be submitted.
  bool get canSubmit => isValid && !isValidating && !isBusy;

  /// Whether the form is busy and must not accept another submission.
  ///
  /// Defaults to [isSubmitting] plus whatever [isExtraBusy] reports for
  /// [extra].
  bool get isBusy => isSubmitting || (isExtraBusy?.call(extra) ?? false);

  /// Shorthand getters for submission states.
  bool get isSubmitting => submissionStatus.isSubmitting;
  bool get isSuccess => submissionStatus.isSuccess;
  bool get isFailure => submissionStatus.isFailure;

  /// Returns a copy with [update] applied to [extra].
  MkFormState<T> updateExtra(T Function(T extra) update) =>
      copyWith(extra: () => update(extra));

  /// [extra] is wrapped in a zero-arg function, like [submissionError], so a
  /// nullable [T] can be explicitly set back to `null` — `extra: () => null`
  /// clears it, while omitting [extra] entirely leaves it unchanged. Passing
  /// a plain nullable value here (`T?`) could not tell those two cases apart.
  MkFormState<T> copyWith({
    MkSubmissionStatus? submissionStatus,
    bool? isValid,
    bool? isValidating,
    bool? isDirty,
    bool? isTouched,
    bool? wasSubmitted,
    Map<String, dynamic>? values,
    Object? Function()? submissionError,
    T Function()? extra,
  }) {
    return MkFormState<T>(
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
      extra: extra != null ? extra() : this.extra,
      extraReset: extraReset,
      isExtraBusy: isExtraBusy,
    );
  }

  /// Returns an idle, pristine copy of this state.
  ///
  /// Used by [MkFormBloc.reset]. [extra] is regenerated via [extraReset], or
  /// left unchanged if none was given.
  MkFormState<T> reset({
    required bool isValid,
    required bool isValidating,
    required Map<String, dynamic> values,
  }) {
    return copyWith(
      submissionStatus: const MkSubmissionStatus.idle(),
      isValid: isValid,
      isValidating: isValidating,
      isDirty: false,
      isTouched: false,
      wasSubmitted: false,
      values: values,
      submissionError: () => null,
      extra: extraReset,
    );
  }

  @override
  List<Object?> get props => [
    submissionStatus,
    isValid,
    isValidating,
    isDirty,
    isTouched,
    wasSubmitted,
    values,
    submissionError,
    extra,
  ];
}
