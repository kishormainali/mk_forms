import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/deep_equals.dart';
import '../../core/status.dart';
import '../control_bloc.dart';
import '../field/field_bloc.dart';
import '../group/group_bloc.dart';
import 'form_state.dart';

/// Abstract or standalone coordinator bloc managing the form lifecycle.
///
/// Handles:
/// - Aggregated validation across all controls.
/// - Submission flow with automatic validation gating.
/// - Clear submission error lifecycle (automatically clears submission error
///   when the user modifies any field, preventing repeated error banners).
/// - Server error mapping to field controls via [setFieldErrors].
abstract class MkFormBloc extends Cubit<MkFormState> {
  MkFormBloc({
    Map<String, MkControlBloc<dynamic>>? controls,
    MkFormState? initialState,
  }) : _rootGroup = MkGroupBloc(controls ?? {}),
       super(
         initialState ??
             MkFormState(
               submissionStatus: const MkSubmissionStatus.idle(),
               isValid: controls?.values.every((c) => c.isValid) ?? true,
               isValidating:
                   controls?.values.any((c) => c.isValidating) ?? false,
               isDirty: controls?.values.any((c) => c.isDirty) ?? false,
               isTouched: controls?.values.any((c) => c.isTouched) ?? false,
               wasSubmitted: false,
               values: {
                 for (final entry in (controls ?? const {}).entries)
                   entry.key: entry.value.value,
               },
             ),
       ) {
    _initControlListeners();
  }

  final MkGroupBloc _rootGroup;
  bool _isSubmitInFlight = false;

  /// The root control group containing all registered controls.
  MkGroupBloc get root => _rootGroup;

  /// Map of all controls in the form.
  Map<String, MkControlBloc<dynamic>> get controls => _rootGroup.controls;

  /// Aggregated map of form values.
  Map<String, dynamic> get values => _rootGroup.value;

  /// Retrieves a registered control by [name].
  C? control<C extends MkControlBloc<dynamic>>(String name) =>
      _rootGroup.control<C>(name);

  /// Retrieves a registered [MkFieldBloc<T>] by [name].
  MkFieldBloc<T>? field<T>(String name) => _rootGroup.field<T>(name);

  /// Registers a control dynamically.
  void registerControl(String name, MkControlBloc<dynamic> control) {
    _rootGroup.addControl(name, control);
  }

  /// Removes a registered control.
  void unregisterControl(String name) {
    _rootGroup.removeControl(name);
  }

  /// Emitting after [close] is a silent no-op, so submissions or validations
  /// that finish after the form was disposed cannot throw.
  @protected
  @override
  void emit(MkFormState state) {
    if (isClosed) return;
    super.emit(state);
  }

  void _initControlListeners() {
    _rootGroup.addStateListener(_onRootGroupChanged);
  }

  void _onRootGroupChanged() {
    if (isClosed) return;
    final groupState = _rootGroup.state;

    // When the user edits any field after a failed submission, clear the
    // submission error so the user doesn't see persistent/repeated error
    // banners. Only actual value changes count: touching a field, or mapping
    // server errors onto fields via [setFieldErrors], must keep the failure.
    final shouldClearSubmissionError =
        state.isFailure && !mkDeepEquals(state.values, groupState.values);

    emit(
      onUpdateFormState(
        state,
        isValid: groupState.isValid,
        isValidating: groupState.isValidating,
        isDirty: groupState.isDirty,
        isTouched: groupState.isTouched,
        values: groupState.values,
        submissionStatus: shouldClearSubmissionError
            ? const MkSubmissionStatus.idle()
            : state.submissionStatus,
        submissionError: shouldClearSubmissionError ? () => null : null,
      ),
    );
  }

  /// Hook for subclasses (such as [MkStepFormBloc]) to preserve subtype state properties.
  @protected
  MkFormState onUpdateFormState(
    MkFormState currentState, {
    required bool isValid,
    required bool isValidating,
    required bool isDirty,
    required bool isTouched,
    required Map<String, dynamic> values,
    required MkSubmissionStatus submissionStatus,
    required Object? Function()? submissionError,
  }) {
    return currentState.copyWith(
      isValid: isValid,
      isValidating: isValidating,
      isDirty: isDirty,
      isTouched: isTouched,
      values: values,
      submissionStatus: submissionStatus,
      submissionError: submissionError,
    );
  }

  /// Manually clears any active submission error.
  void clearSubmissionError() {
    if (isClosed || state.submissionError == null) return;
    emit(
      state.copyWith(
        submissionStatus: const MkSubmissionStatus.idle(),
        submissionError: () => null,
      ),
    );
  }

  /// Sets errors returned from a backend/server response onto individual fields.
  ///
  /// For example: `setFieldErrors({'email': 'Email is already taken'})`.
  void setFieldErrors(Map<String, String> fieldErrors) {
    for (final entry in fieldErrors.entries) {
      final f = field<dynamic>(entry.key);
      if (f != null) {
        f.setError(entry.value);
        f.touch();
      }
    }
  }

  /// Submits the form.
  ///
  /// 1. Prevents duplicate submissions if already submitting.
  /// 2. Touches all fields and marks [wasSubmitted] = true.
  /// 3. Validates all synchronous and asynchronous controls.
  /// 4. If invalid, halts submission.
  /// 5. If valid, invokes [onSubmit] and handles success/failure.
  Future<void> submit() async {
    // `state.isSubmitting` only flips once validation has finished, so a
    // dedicated flag is needed to reject calls made while validating.
    // `state.isBusy` also covers subclass-defined in-flight work.
    if (isClosed || _isSubmitInFlight || state.isBusy) return;
    _isSubmitInFlight = true;
    try {
      await _submit();
    } finally {
      _isSubmitInFlight = false;
    }
  }

  Future<void> _submit() async {
    // Mark submitted across all fields so errors become visible to user
    emit(state.copyWith(wasSubmitted: true));
    _rootGroup.markFormSubmitted();
    _rootGroup.touch();

    // Validate all controls
    final isValid = await _rootGroup.validate();
    if (!isValid || isClosed) {
      return;
    }

    emit(
      state.copyWith(
        submissionStatus: const MkSubmissionStatus.submitting(),
        submissionError: () => null,
      ),
    );

    try {
      final response = await onSubmit(values);
      if (!isClosed) {
        emit(
          state.copyWith(
            submissionStatus: MkSubmissionStatus.success(response),
            submissionError: () => null,
          ),
        );
        onSubmitSuccess(response);
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            submissionStatus: MkSubmissionStatus.failure(error),
            submissionError: () => error,
          ),
        );
        onSubmitFailure(error);
      }
    }
  }

  /// Method to be overridden by subclasses or custom implementations
  /// containing the async submit logic (API call, database write, etc.).
  Future<dynamic> onSubmit(Map<String, dynamic> values);

  /// Callback hook invoked when submission succeeds.
  void onSubmitSuccess(dynamic response) {}

  /// Callback hook invoked when submission fails.
  void onSubmitFailure(Object error) {}

  /// Populates the form controls with [data] (e.g. from an API response or draft).
  ///
  /// If [markPristine] is `true`, values are applied as new initial values,
  /// keeping controls pure and resetting dirty/touched states so no premature errors appear.
  /// If [markPristine] is `false`, values are applied via `changeValue`.
  void populateValues(Map<String, dynamic> data, {bool markPristine = true}) {
    for (final entry in data.entries) {
      final ctrl = control<MkControlBloc<dynamic>>(entry.key);
      if (ctrl is MkFieldBloc) {
        if (markPristine) {
          ctrl.reset(entry.value);
        } else {
          ctrl.changeValue(entry.value);
        }
      } else if (ctrl is MkGroupBloc && entry.value is Map<String, dynamic>) {
        for (final subEntry in (entry.value as Map<String, dynamic>).entries) {
          final subCtrl = ctrl.control<MkControlBloc<dynamic>>(subEntry.key);
          if (subCtrl is MkFieldBloc) {
            if (markPristine) {
              subCtrl.reset(subEntry.value);
            } else {
              subCtrl.changeValue(subEntry.value);
            }
          }
        }
      }
    }
  }

  /// Touches and validates only the specified [groupName] (subform).
  ///
  /// Useful for multi-section forms (e.g. shipping address before billing address)
  /// without triggering validation errors on unrelated controls.
  Future<bool> validateGroup(String groupName) async {
    final grp = control<MkGroupBloc>(groupName);
    if (grp == null) return true;
    grp.touch();
    grp.markFormSubmitted();
    return grp.validate();
  }

  /// Touches and validates only a specific subset of [controlNames].
  Future<bool> validateControls(Iterable<String> controlNames) async {
    final targets = <MkControlBloc<dynamic>>[];
    for (final name in controlNames) {
      final c = control<MkControlBloc<dynamic>>(name);
      if (c != null) {
        targets.add(c);
        c.touch();
        c.markFormSubmitted();
      }
    }
    final results = await Future.wait(targets.map((c) => c.validate()));
    return results.every((valid) => valid);
  }

  /// Resets the form and all its controls to their initial states.
  ///
  /// Subclass state is preserved through [MkFormState.reset].
  void reset() {
    _rootGroup.reset();
    emit(
      state.reset(
        isValid: _rootGroup.isValid,
        isValidating: _rootGroup.isValidating,
        values: _rootGroup.value,
      ),
    );
  }

  @override
  Future<void> close() async {
    _rootGroup.removeStateListener(_onRootGroupChanged);
    await _rootGroup.close();
    return super.close();
  }
}
