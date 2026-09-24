import 'dart:async';
import '../../core/status.dart';
import '../control_bloc.dart';
import 'form_bloc.dart';
import 'step_form_state.dart';

export 'step_form_state.dart';

/// Configuration for a single step in an [MkStepFormBloc].
class MkFormStep {
  const MkFormStep({required this.controlNames, this.title, this.subtitle});

  /// Names of the controls that belong to this step.
  final List<String> controlNames;

  /// Optional title for this step (e.g. for stepper UI).
  final String? title;

  /// Optional subtitle or description.
  final String? subtitle;
}

/// A specialized [MkFormBloc] that manages multi-step forms, wizards,
/// and multi-route onboarding workflows.
///
/// [T] is the type of [MkFormState.extra]; most step forms never need it and
/// can extend `MkStepFormBloc` (no type argument) exactly as before. A step
/// form that wants typed extras extends `MkStepFormBloc<MyExtras>` and
/// passes `initialExtra`/`extraReset`/`isExtraBusy` to the constructor.
///
/// Features:
/// - Granular step validation: validating Step 1 never marks Step 2 or 3 as dirty/touched.
/// - Step progression gating: [nextStep] only advances if current step controls are valid.
/// - Initial step configuration: can start at any step (e.g. resuming an onboarding flow).
/// - Remote data hydration: [loadInitialData] fetches drafts from an API, marks fields
///   pristine without false errors, and jumps to the server-designated step.
/// - Safe route transitions: retains full form state across Navigator push and pop.
abstract class MkStepFormBloc<T extends Object?> extends MkFormBloc<T> {
  MkStepFormBloc({
    required Map<String, MkControlBloc<dynamic>> controls,
    required List<MkFormStep> steps,
    int initialStep = 0,
    T Function()? initialExtra,
    T Function()? extraReset,
    bool Function(T extra)? isExtraBusy,
  }) : _steps = List.unmodifiable(steps),
       super(
         controls: controls,
         initialState: MkStepFormState<T>(
           submissionStatus: const MkSubmissionStatus.idle(),
           isValid: controls.values.every((c) => c.isValid),
           isValidating: controls.values.any((c) => c.isValidating),
           isDirty: controls.values.any((c) => c.isDirty),
           isTouched: controls.values.any((c) => c.isTouched),
           wasSubmitted: false,
           values: {
             for (final entry in controls.entries) entry.key: entry.value.value,
           },
           // Only reached without a mismatch when T is Object? (no extras)
           // or initialExtra is supplied; a step form with a real, non-
           // nullable extras type that supplies neither throws here, exactly
           // as `MkFormBloc` does for the same reason.
           extra: initialExtra != null ? initialExtra() : null as T,
           extraReset: extraReset,
           isExtraBusy: isExtraBusy,
           currentStep: steps.isEmpty
               ? 0
               : initialStep.clamp(0, steps.length - 1),
           totalSteps: steps.length,
           completedSteps: const {},
         ),
       );

  final List<MkFormStep> _steps;

  /// Unmodifiable list of configured steps.
  List<MkFormStep> get steps => _steps;

  @override
  MkStepFormState<T> get state => super.state as MkStepFormState<T>;

  /// The active step index.
  int get currentStep => state.currentStep;

  /// Total number of steps.
  int get totalSteps => state.totalSteps;

  /// Validates only the controls belonging to [step] (defaults to [currentStep]).
  ///
  /// Crucially, this does NOT touch or mark future steps as submitted,
  /// preserving pristine form state across multi-route wizards.
  Future<bool> validateStep([int? step]) async {
    final stepIndex = step ?? currentStep;
    if (stepIndex < 0 || stepIndex >= _steps.length) return true;

    final stepConfig = _steps[stepIndex];
    final isValid = await validateControls(stepConfig.controlNames);
    if (isClosed) return false;

    final updatedCompleted = Set<int>.from(state.completedSteps);
    if (isValid) {
      updatedCompleted.add(stepIndex);
    } else {
      updatedCompleted.remove(stepIndex);
    }

    emit(state.copyWith(completedSteps: updatedCompleted));

    return isValid;
  }

  /// Validates the current step and, if valid, advances to the next step.
  ///
  /// Returns `true` if validation passed and the step advanced (or is on the last step).
  Future<bool> nextStep() async {
    if (isClosed) return false;

    final isStepValid = await validateStep(currentStep);
    if (!isStepValid) return false;

    if (state.currentStep < totalSteps - 1) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
      return true;
    }

    return true;
  }

  /// Navigates to the previous step if not already on the first step.
  void previousStep() {
    if (isClosed || state.currentStep <= 0) return;
    emit(state.copyWith(currentStep: state.currentStep - 1));
  }

  /// Navigates directly to a target step.
  ///
  /// If navigating backwards, navigation is immediate.
  /// If navigating forward past incomplete steps, validates preceding steps first.
  Future<bool> goToStep(int targetStep) async {
    if (isClosed || targetStep < 0 || targetStep >= totalSteps) return false;

    if (targetStep <= currentStep) {
      emit(state.copyWith(currentStep: targetStep));
      return true;
    }

    // Navigating forward: validate all steps between current and target
    for (int i = currentStep; i < targetStep; i++) {
      final valid = await validateStep(i);
      if (!valid || isClosed) return false;
    }

    emit(state.copyWith(currentStep: targetStep));
    return true;
  }

  /// Asynchronously loads initial/draft data from an API and hydrates form fields.
  ///
  /// - Automatically sets [MkStepFormState.isLoadingInitialData] = true while loading.
  /// - Hydrates fields via [populateValues] with `markPristine: true` so no premature errors appear.
  /// - Resolves the server-designated starting step using [resolveInitialStep].
  Future<void> loadInitialData(
    Future<Map<String, dynamic>> Function() loader, {
    int? Function(Map<String, dynamic> data)? resolveInitialStep,
  }) async {
    if (isClosed) return;

    emit(state.copyWith(isLoadingInitialData: true));

    try {
      final data = await loader();
      if (isClosed) return;

      populateValues(data);

      int targetStep = currentStep;
      if (resolveInitialStep != null) {
        final resolved = resolveInitialStep(data);
        if (resolved != null) {
          targetStep = resolved.clamp(0, totalSteps - 1);
        }
      }

      // Check preceding steps up to targetStep for validation issues.
      // All field values from data have been populated and preserved.
      int? firstInvalidStep;
      final completed = <int>{};

      for (int i = 0; i < targetStep; i++) {
        final stepControls = _steps[i].controlNames;
        final allValid = stepControls.every((name) {
          final c = control<MkControlBloc<dynamic>>(name);
          return c != null && c.isValid;
        });

        if (allValid) {
          completed.add(i);
        } else {
          firstInvalidStep ??= i;
        }
      }

      if (firstInvalidStep != null) {
        // Preceding step has validation issues!
        // Touch/validate the invalid step's controls so errors are immediately visible.
        await validateControls(_steps[firstInvalidStep].controlNames);
        if (isClosed) return;

        emit(
          state.copyWith(
            isLoadingInitialData: false,
            currentStep: firstInvalidStep,
            completedSteps: completed,
            redirectedFromStep: () => targetStep,
            invalidStepIndex: () => firstInvalidStep,
          ),
        );
      } else {
        // All preceding steps are valid; proceed to designated target step
        emit(
          state.copyWith(
            isLoadingInitialData: false,
            currentStep: targetStep,
            completedSteps: completed,
            redirectedFromStep: () => null,
            invalidStepIndex: () => null,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(isLoadingInitialData: false));
      }
      rethrow;
    }
  }
}

/// A lightweight [MkStepFormBloc] implementation that allows passing
/// an [onSubmit] closure directly.
class MkSimpleStepFormBloc<T extends Object?> extends MkStepFormBloc<T> {
  MkSimpleStepFormBloc({
    required super.controls,
    required super.steps,
    super.initialStep,
    super.initialExtra,
    super.extraReset,
    super.isExtraBusy,
    required Future<dynamic> Function(Map<String, dynamic> values) onSubmit,
    void Function(dynamic response)? onSubmitSuccess,
    void Function(Object error)? onSubmitFailure,
  }) : _submitHandler = onSubmit,
       _successHandler = onSubmitSuccess,
       _failureHandler = onSubmitFailure;

  final Future<dynamic> Function(Map<String, dynamic> values) _submitHandler;
  final void Function(dynamic response)? _successHandler;
  final void Function(Object error)? _failureHandler;

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) {
    return _submitHandler(values);
  }

  @override
  void onSubmitSuccess(dynamic response) {
    _successHandler?.call(response);
  }

  @override
  void onSubmitFailure(Object error) {
    _failureHandler?.call(error);
  }
}
