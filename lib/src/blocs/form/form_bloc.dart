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
/// [T] is the type of [MkFormState.extra]; most forms never need it and can
/// extend `MkFormBloc` (no type argument) exactly as before. A form that
/// wants typed extra fields extends `MkFormBloc<MyExtras>` and either passes
/// `initialExtra`/`extraReset`/`isExtraBusy` (the common case — the base
/// fields are still built for you), or a fully custom
/// `initialState: MkFormState<MyExtras>(...)` when more control is needed.
///
/// Handles:
/// - Aggregated validation across all controls.
/// - Submission flow with automatic validation gating.
/// - Clear submission error lifecycle (automatically clears submission error
///   when the user modifies any field, preventing repeated error banners).
/// - Server error mapping to field controls via [setFieldErrors].
abstract class MkFormBloc<T extends Object?> extends Cubit<MkFormState<T>> {
  MkFormBloc({
    Map<String, MkControlBloc<dynamic>>? controls,
    MkFormState<T>? initialState,
    T Function()? initialExtra,
    T Function()? extraReset,
    bool Function(T extra)? isExtraBusy,
  }) : _rootGroup = MkGroupBloc(controls ?? {}),
       super(
         initialState ??
             MkFormState<T>(
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
               // Only reached without a mismatch when T is Object? (no
               // extras) or initialExtra is supplied; a bloc with a real,
               // non-nullable extras type that supplies neither throws here
               // — the same fail-fast behavior MkFormStateBuilder uses for a
               // type mismatch. See the "Residual casts" section of the
               // design spec.
               extra: initialExtra != null ? initialExtra() : null as T,
               extraReset: extraReset,
               isExtraBusy: isExtraBusy,
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

  /// Retrieves a registered [MkFieldBloc<F>] by [name].
  MkFieldBloc<F>? field<F>(String name) => _rootGroup.field<F>(name);

  /// Registers a control dynamically.
  ///
  /// If [name] already has a control registered, it is replaced; the
  /// displaced control is closed unless [disposeReplaced] is `false`.
  void registerControl(
    String name,
    MkControlBloc<dynamic> control, {
    bool disposeReplaced = true,
  }) {
    _rootGroup.addControl(name, control, disposeReplaced: disposeReplaced);
  }

  /// Removes a registered control.
  ///
  /// The removed control is closed by default; pass [dispose] as `false`
  /// when intentionally re-registering it later (e.g. toggling a
  /// conditional field off and back on).
  MkControlBloc<dynamic>? unregisterControl(
    String name, {
    bool dispose = true,
  }) {
    return _rootGroup.removeControl(name, dispose: dispose);
  }

  /// Emitting after [close] is a silent no-op, so submissions or validations
  /// that finish after the form was disposed cannot throw.
  @protected
  @override
  void emit(MkFormState<T> state) {
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

  /// Hook for subclasses to customize how control changes update the state.
  ///
  /// The base implementation calls [MkFormState.copyWith], which dispatches
  /// virtually to the runtime type's `copyWith` override — so a state
  /// subclass such as [MkStepFormState] never needs to override this to
  /// preserve its own fields. `extra` is never passed here, so it is always
  /// preserved untouched across control edits.
  @protected
  MkFormState<T> onUpdateFormState(
    MkFormState<T> currentState, {
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
    _rootGroup.batch(() {
      for (final entry in fieldErrors.entries) {
        final f = field<dynamic>(entry.key);
        if (f != null) {
          f.setError(entry.value);
          f.touch();
        }
      }
    });
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
    // `state.isBusy` also covers extra-defined in-flight work.
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
    // One aggregate recompute (and one form emission) for the whole payload,
    // instead of one per field.
    _rootGroup.batch(() {
      for (final entry in data.entries) {
        final ctrl = control<MkControlBloc<dynamic>>(entry.key);
        if (ctrl is MkFieldBloc) {
          _applyValue(ctrl, entry.value, markPristine);
        } else if (ctrl is MkGroupBloc && entry.value is Map<String, dynamic>) {
          ctrl.batch(() {
            for (final sub in (entry.value as Map<String, dynamic>).entries) {
              final subCtrl = ctrl.control<MkControlBloc<dynamic>>(sub.key);
              if (subCtrl is MkFieldBloc) {
                _applyValue(subCtrl, sub.value, markPristine);
              }
            }
          });
        }
      }
    });
  }

  void _applyValue(MkFieldBloc<dynamic> field, dynamic value, bool pristine) {
    if (pristine) {
      field.reset(value);
    } else {
      field.changeValue(value);
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
    final pending = <Future<bool>>[];
    // Synchronous work (touch, submitted flag, sync validators) completes
    // inside the batch, so the aggregate is recomputed once, not per control.
    _rootGroup.batch(() {
      for (final name in controlNames) {
        final c = control<MkControlBloc<dynamic>>(name);
        if (c != null) {
          c.touch();
          c.markFormSubmitted();
          pending.add(c.validate());
        }
      }
    });
    final results = await Future.wait(pending);
    return results.every((valid) => valid);
  }

  /// Resets the form and all its controls to their initial states.
  ///
  /// `extra` is preserved (or regenerated via `extraReset`) through
  /// [MkFormState.reset].
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
