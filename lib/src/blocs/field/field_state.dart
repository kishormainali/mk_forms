import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
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
    required this.wasFormSubmitted,
    this.error,
    this.errorCode,
    this.errorParams,
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
      AutovalidateMode.onUserInteractionIfError => isTouched || wasFormSubmitted,
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
  String? getLocalizedError([BuildContext? context]) {
    if (errorCode != null) {
      final messages = MkFormLocalizations.of(context);
      final resolved = messages.resolve(errorCode!, errorParams ?? const {});
      if (resolved != null) return resolved;
    }
    return error;
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
    bool? wasFormSubmitted,
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
      wasFormSubmitted: wasFormSubmitted ?? this.wasFormSubmitted,
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
    wasFormSubmitted,
  ];
}
