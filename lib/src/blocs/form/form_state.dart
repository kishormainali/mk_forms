import 'package:equatable/equatable.dart';
import '../../core/status.dart';

/// Represents the overall state of an [MkFormBloc].
class MkFormState extends Equatable {
  const MkFormState({
    required this.submissionStatus,
    required this.isValid,
    required this.isValidating,
    required this.isDirty,
    required this.isTouched,
    required this.wasSubmitted,
    required this.values,
    this.submissionError,
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

  /// Whether the form can currently be submitted.
  bool get canSubmit =>
      isValid && !isValidating && !submissionStatus.isSubmitting;

  /// Shorthand getters for submission states.
  bool get isSubmitting => submissionStatus.isSubmitting;
  bool get isSuccess => submissionStatus.isSuccess;
  bool get isFailure => submissionStatus.isFailure;

  MkFormState copyWith({
    MkSubmissionStatus? submissionStatus,
    bool? isValid,
    bool? isValidating,
    bool? isDirty,
    bool? isTouched,
    bool? wasSubmitted,
    Map<String, dynamic>? values,
    Object? Function()? submissionError,
  }) {
    return MkFormState(
      submissionStatus: submissionStatus ?? this.submissionStatus,
      isValid: isValid ?? this.isValid,
      isValidating: isValidating ?? this.isValidating,
      isDirty: isDirty ?? this.isDirty,
      isTouched: isTouched ?? this.isTouched,
      wasSubmitted: wasSubmitted ?? this.wasSubmitted,
      values: values ?? this.values,
      submissionError:
          submissionError != null ? submissionError() : this.submissionError,
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
  ];
}
