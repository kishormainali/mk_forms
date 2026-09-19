import '../../core/status.dart';
import 'form_state.dart';

/// Represents the state of a multi-step / wizard form.
class MkStepFormState extends MkFormState {
  const MkStepFormState({
    required super.submissionStatus,
    required super.isValid,
    required super.isValidating,
    required super.isDirty,
    required super.isTouched,
    required super.wasSubmitted,
    required super.values,
    super.submissionError,
    required this.currentStep,
    required this.totalSteps,
    required this.completedSteps,
    this.isLoadingInitialData = false,
    this.redirectedFromStep,
    this.invalidStepIndex,
  });

  /// The active step index (0-indexed).
  final int currentStep;

  /// The total number of steps configured in the form.
  final int totalSteps;

  /// Set of step indices that have passed validation.
  final Set<int> completedSteps;

  /// Whether draft or initial step data is currently being fetched asynchronously.
  final bool isLoadingInitialData;

  /// If loading initial data redirected away from the server's targeted step due to
  /// validation errors in an earlier step, this holds the original target step.
  final int? redirectedFromStep;

  /// If a redirection occurred due to validation errors, this holds the 0-indexed step
  /// that contained the invalid controls.
  final int? invalidStepIndex;

  /// Whether loading draft/initial data was redirected to an earlier step because of
  /// validation errors in that step.
  bool get wasRedirectedDueToError =>
      redirectedFromStep != null && invalidStepIndex != null;

  /// Whether the active step is the first step.
  bool get isFirstStep => currentStep == 0;

  /// Whether the active step is the final step.
  bool get isLastStep => currentStep >= totalSteps - 1;

  /// Progress fraction from 0.0 to 1.0.
  double get stepProgress =>
      totalSteps > 1 ? (currentStep / (totalSteps - 1)).clamp(0.0, 1.0) : 1.0;

  /// Whether step at [index] is marked as completed.
  bool isStepCompleted(int index) => completedSteps.contains(index);

  @override
  MkStepFormState copyWith({
    MkSubmissionStatus? submissionStatus,
    bool? isValid,
    bool? isValidating,
    bool? isDirty,
    bool? isTouched,
    bool? wasSubmitted,
    Map<String, dynamic>? values,
    Object? Function()? submissionError,
    int? currentStep,
    int? totalSteps,
    Set<int>? completedSteps,
    bool? isLoadingInitialData,
    int? Function()? redirectedFromStep,
    int? Function()? invalidStepIndex,
  }) {
    return MkStepFormState(
      submissionStatus: submissionStatus ?? this.submissionStatus,
      isValid: isValid ?? this.isValid,
      isValidating: isValidating ?? this.isValidating,
      isDirty: isDirty ?? this.isDirty,
      isTouched: isTouched ?? this.isTouched,
      wasSubmitted: wasSubmitted ?? this.wasSubmitted,
      values: values ?? this.values,
      submissionError:
          submissionError != null ? submissionError() : this.submissionError,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      completedSteps: completedSteps ?? this.completedSteps,
      isLoadingInitialData:
          isLoadingInitialData ?? this.isLoadingInitialData,
      redirectedFromStep: redirectedFromStep != null
          ? redirectedFromStep()
          : this.redirectedFromStep,
      invalidStepIndex:
          invalidStepIndex != null ? invalidStepIndex() : this.invalidStepIndex,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    currentStep,
    totalSteps,
    completedSteps,
    isLoadingInitialData,
    redirectedFromStep,
    invalidStepIndex,
  ];
}
