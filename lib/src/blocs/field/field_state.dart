import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import '../../core/localization.dart';

/// Represents the state of a single form field [MkFieldBloc<T>].
class MkFieldState<T> extends Equatable {
  const MkFieldState({
    required this.value,
    required this.initialValue,
    required this.isDirty,
    required this.isTouched,
    required this.isValidating,
    required this.isEnabled,
    required this.isVisible,
    required this.isReadOnly,
    required this.wasFormSubmitted,
    this.error,
    this.errorCode,
    this.errorParams,
    this.label,
  });

  /// The current value of the field.
  final T? value;

  /// The initial value when the field was created or reset.
  final T? initialValue;

  /// The current validation error message, or null if valid.
  final String? error;

  /// The error code (e.g. from [MkErrorCodes]) for i18n resolution.
  final String? errorCode;

  /// Parameters associated with the error (e.g. min, max) for localization formatting.
  final Map<String, dynamic>? errorParams;

  /// This field's display label, used by [getLocalizedError] to produce
  /// field-aware messages (e.g. `"Email is required."`). `null` if the
  /// field was never given an explicit `label` and was never registered in
  /// an [MkGroupBloc] (which auto-derives one from its registration key).
  final String? label;

  /// Whether the field's value has changed from its [initialValue].
  final bool isDirty;

  /// Whether the user has interacted with/blurred this field.
  final bool isTouched;

  /// Whether asynchronous validation is currently running.
  final bool isValidating;

  /// Whether this field is enabled for input.
  final bool isEnabled;

  /// Whether this field is visible in the UI.
  final bool isVisible;

  /// Whether this field is read-only.
  ///
  /// A read-only field is excluded from validation entirely: it always
  /// reports [isValid] as `true`, regardless of any configured validators,
  /// so it never blocks the enclosing group/form from being valid.
  final bool isReadOnly;

  /// Whether the enclosing form has attempted submission.
  final bool wasFormSubmitted;

  /// Whether the field has no validation errors and is not actively validating.
  bool get isValid => error == null && !isValidating;

  /// Whether the field currently has a validation error.
  bool get isInvalid => error != null;

  /// Whether the field is pristine (not modified from its initial value).
  bool get isPure => !isDirty;

  /// Whether the UI should display the validation error to the user based on [mode].
  ///
  /// - [AutovalidateMode.always]: Displays errors immediately, even when pristine/untouched.
  /// - [AutovalidateMode.onUserInteraction]: Displays errors after user interaction
  ///   ([isTouched]) or after form submission has been attempted ([wasFormSubmitted]).
  /// - [AutovalidateMode.onUnfocus]: Displays errors when the field loses focus
  ///   ([isTouched]) or after form submission has been attempted ([wasFormSubmitted]).
  /// - [AutovalidateMode.disabled]: Does not display errors automatically on user interaction;
  ///   only displays errors once form submission has been attempted ([wasFormSubmitted]).
  bool shouldShowError([
    AutovalidateMode mode = AutovalidateMode.onUserInteraction,
  ]) {
    if (error == null) return false;
    return switch (mode) {
      AutovalidateMode.always => true,
      AutovalidateMode.onUserInteraction ||
      AutovalidateMode.onUnfocus ||
      AutovalidateMode.onUserInteractionIfError =>
        isTouched || wasFormSubmitted,
      AutovalidateMode.disabled => wasFormSubmitted,
    };
  }

  /// Whether the UI should display the validation error to the user.
  ///
  /// Equivalent to calling [shouldShowError] with [AutovalidateMode.onUserInteraction].
  /// Guarantees that errors are NEVER shown on initial screen load
  /// until the user touches the field or submits the form.
  bool get showError => shouldShowError();

  /// Resolves the localized error message using [context]'s [MkFormLocalizations],
  /// or falls back to [error].
  ///
  /// When [label] is set, tries a field-aware message first (e.g. `"Email is
  /// required."` via [MkFormMessages.resolveField]) before falling back to
  /// the non-field-aware [MkFormMessages.resolve], then to [error].
  String? getLocalizedError([BuildContext? context]) {
    if (errorCode != null) {
      final messages = MkFormLocalizations.of(context);
      final resolvedForField = label != null
          ? messages.resolveField(errorCode!, label!, errorParams ?? const {})
          : null;
      if (resolvedForField != null) return resolvedForField;
      final resolved = messages.resolve(errorCode!, errorParams ?? const {});
      if (resolved != null) return resolved;
    }
    return error;
  }

  /// Returns a copy with [value] and the validation outcome replaced in one
  /// allocation, for the validation hot path.
  ///
  /// Equivalent to [copyWith] with `value`, `error`, `errorCode`, `errorParams`
  /// and `isValidating` set (and optionally [isDirty] / [isTouched]), but
  /// without the closure allocations `copyWith` needs to tell "unchanged" from
  /// "set to null".
  @internal
  MkFieldState<T> withValidation({
    required T? value,
    required String? error,
    required String? errorCode,
    required Map<String, dynamic>? errorParams,
    required bool isValidating,
    bool? isDirty,
    bool? isTouched,
  }) {
    return MkFieldState<T>(
      value: value,
      initialValue: initialValue,
      error: error,
      errorCode: errorCode,
      errorParams: errorParams,
      isDirty: isDirty ?? this.isDirty,
      isTouched: isTouched ?? this.isTouched,
      isValidating: isValidating,
      isEnabled: isEnabled,
      isVisible: isVisible,
      isReadOnly: isReadOnly,
      wasFormSubmitted: wasFormSubmitted,
      label: label,
    );
  }

  MkFieldState<T> copyWith({
    T? Function()? value,
    T? Function()? initialValue,
    String? Function()? error,
    String? Function()? errorCode,
    Map<String, dynamic>? Function()? errorParams,
    bool? isDirty,
    bool? isTouched,
    bool? isValidating,
    bool? isEnabled,
    bool? isVisible,
    bool? isReadOnly,
    bool? wasFormSubmitted,
    String? label,
  }) {
    return MkFieldState<T>(
      value: value != null ? value() : this.value,
      initialValue: initialValue != null ? initialValue() : this.initialValue,
      error: error != null ? error() : this.error,
      errorCode: errorCode != null ? errorCode() : this.errorCode,
      errorParams: errorParams != null ? errorParams() : this.errorParams,
      isDirty: isDirty ?? this.isDirty,
      isTouched: isTouched ?? this.isTouched,
      isValidating: isValidating ?? this.isValidating,
      isEnabled: isEnabled ?? this.isEnabled,
      isVisible: isVisible ?? this.isVisible,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      wasFormSubmitted: wasFormSubmitted ?? this.wasFormSubmitted,
      label: label ?? this.label,
    );
  }

  @override
  List<Object?> get props => [
    value,
    initialValue,
    error,
    errorCode,
    errorParams,
    isDirty,
    isTouched,
    isValidating,
    isEnabled,
    isVisible,
    isReadOnly,
    wasFormSubmitted,
    label,
  ];
}
