import 'dart:async';
import '../../core/deep_equals.dart';
import '../../core/localization.dart';
import '../../core/validation.dart';
import '../control_bloc.dart';
import 'field_state.dart';

export 'field_state.dart';

/// A reactive form control bloc managing a single field of type [T].
class MkFieldBloc<T> extends MkControlBloc<MkFieldState<T>> {
  MkFieldBloc({
    T? initialValue,
    List<Validator<T>> validators = const [],
    List<AsyncValidator<T>> asyncValidators = const [],
    List<MkControlBloc<dynamic>> dependsOn = const [],
    Duration debounceTime = const Duration(milliseconds: 300),
    bool isEnabled = true,
    bool isVisible = true,
  })  : _validators = List.unmodifiable(validators),
        _asyncValidators = List.unmodifiable(asyncValidators),
        _debounceTime = debounceTime,
        super(
          MkFieldState<T>(
            value: initialValue,
            initialValue: initialValue,
            isDirty: false,
            isTouched: false,
            isValidating: false,
            isEnabled: isEnabled,
            isVisible: isVisible,
            wasFormSubmitted: false,
          ),
        ) {
    // Initial validation check to establish validity status without displaying error
    _syncRevalidate();

    // Setup dependencies
    for (final dependency in dependsOn) {
      addDependency(dependency);
    }
  }

  final List<Validator<T>> _validators;
  final List<AsyncValidator<T>> _asyncValidators;
  final Duration _debounceTime;

  final List<(MkControlBloc<dynamic>, void Function())> _dependencyCallbacks =
      [];
  Timer? _debounceTimer;
  int _latestAsyncToken = 0;

  @override
  T? get value => state.value;

  @override
  bool get isValid => state.isValid;

  @override
  bool get isValidating => state.isValidating;

  @override
  bool get isDirty => state.isDirty;

  @override
  bool get isTouched => state.isTouched;

  /// The current error message or null if valid.
  String? get error => state.error;

  /// Whether this field is enabled.
  bool get isEnabled => state.isEnabled;

  /// Whether this field is visible.
  bool get isVisible => state.isVisible;

  /// Adds a dependency on [otherControl]. When the *value* of [otherControl]
  /// changes, this field is automatically revalidated (async validators are
  /// debounced, exactly like after [changeValue]).
  ///
  /// Adding a dependency only re-runs synchronous validation, so it never
  /// triggers an async validator (a network call) by itself.
  void addDependency(MkControlBloc<dynamic> otherControl) {
    if (isClosed) return;
    dynamic previousValue = otherControl.snapshotValue;

    void callback() {
      if (isClosed) return;
      final currentValue = otherControl.snapshotValue;
      if (mkDeepEquals(currentValue, previousValue)) return;
      previousValue = currentValue;
      _revalidate();
    }

    _dependencyCallbacks.add((otherControl, callback));
    otherControl.addStateListener(callback);

    _syncRevalidate();
  }

  /// Changes the value of this field.
  ///
  /// Recomputes [isDirty], runs synchronous validation, and triggers
  /// debounced async validation if synchronous validation passes.
  ///
  /// Pass [markTouched] to also mark the field as touched in the same state
  /// emission (one rebuild instead of two), e.g. for taps on checkboxes,
  /// radios and dropdowns.
  void changeValue(T? newValue, {bool markTouched = false}) {
    if (isClosed) return;

    _cancelPendingValidation();
    _validateAndEmit(
      state.copyWith(
        value: () => newValue,
        isDirty: !mkDeepEquals(newValue, state.initialValue),
        isTouched: markTouched ? true : null,
      ),
    );
  }

  /// Revalidates the current value after a dependency changed.
  void _revalidate() {
    if (isClosed) return;
    _cancelPendingValidation();
    _validateAndEmit(state);
  }

  /// Runs sync validation on [next]'s value and emits it. If sync validation
  /// passes and async validators exist, starts the debounced async run.
  void _validateAndEmit(MkFieldState<T> next) {
    final value = next.value;
    final (syncError, syncCode, syncParams) = _runSyncValidation(value);

    if (syncError != null || _asyncValidators.isEmpty) {
      emit(
        next.copyWith(
          error: () => syncError,
          errorCode: () => syncCode,
          errorParams: () => syncParams,
          isValidating: false,
        ),
      );
      return;
    }

    // Sync passed, start async debounced validation
    emit(
      next.copyWith(
        error: () => null,
        errorCode: () => null,
        errorParams: () => null,
        isValidating: true,
      ),
    );
    final token = _latestAsyncToken;
    _debounceTimer = Timer(_debounceTime, () {
      unawaited(_runAsyncValidation(value, token));
    });
  }

  /// Cancels the debounce timer and invalidates any in-flight async run.
  void _cancelPendingValidation() {
    _debounceTimer?.cancel();
    _latestAsyncToken++;
  }

  /// Marks this field as touched (e.g. on blur or focus lost).
  @override
  void touch() {
    if (isClosed || state.isTouched) return;
    emit(state.copyWith(isTouched: true));
  }

  /// Marks that the enclosing form has attempted submission.
  @override
  void markFormSubmitted([bool submitted = true]) {
    if (isClosed || state.wasFormSubmitted == submitted) return;
    emit(state.copyWith(wasFormSubmitted: submitted));
  }

  /// Explicitly sets an external error message (e.g. server validation error).
  void setError(
    String? error, {
    String? code,
    Map<String, dynamic>? params,
  }) {
    if (isClosed) return;
    emit(
      state.copyWith(
        error: () => error,
        errorCode: () => code,
        errorParams: () => params,
        isValidating: false,
      ),
    );
  }

  /// Clears any current error on this field.
  void clearError() {
    if (isClosed || state.error == null) return;
    emit(
      state.copyWith(
        error: () => null,
        errorCode: () => null,
        errorParams: () => null,
      ),
    );
  }

  /// Enables or disables this field.
  void setEnabled(bool enabled) {
    if (isClosed || state.isEnabled == enabled) return;
    emit(state.copyWith(isEnabled: enabled));
  }

  /// Sets field visibility.
  void setVisible(bool visible) {
    if (isClosed || state.isVisible == visible) return;
    emit(state.copyWith(isVisible: visible));
  }

  /// Resets this field to its initial value (or a provided new initial value).
  /// Resets `isDirty`, `isTouched`, and `wasFormSubmitted` to false.
  @override
  void reset([T? newInitialValue]) {
    if (isClosed) return;

    _cancelPendingValidation();

    final resetValue = newInitialValue ?? state.initialValue;
    final (initialError, initialCode, initialParams) =
        _runSyncValidation(resetValue);

    emit(
      MkFieldState<T>(
        value: resetValue,
        initialValue: resetValue,
        isDirty: false,
        isTouched: false,
        isValidating: false,
        isEnabled: state.isEnabled,
        isVisible: state.isVisible,
        wasFormSubmitted: false,
        error: initialError,
        errorCode: initialCode,
        errorParams: initialParams,
      ),
    );
  }

  /// Runs all validations on the current field value.
  ///
  /// [cascadeDependents] is ignored: dependents are revalidated whenever this
  /// field's *value* changes, not whenever it validates.
  @override
  Future<bool> validate({
    @Deprecated('No longer needed; it has no effect.')
    bool cascadeDependents = true,
  }) async {
    if (isClosed) return isValid;

    _cancelPendingValidation();

    final (syncError, syncCode, syncParams) = _runSyncValidation(state.value);

    if (syncError != null) {
      emit(
        state.copyWith(
          error: () => syncError,
          errorCode: () => syncCode,
          errorParams: () => syncParams,
          isValidating: false,
        ),
      );
      return false;
    }

    if (_asyncValidators.isEmpty) {
      emit(
        state.copyWith(
          error: () => null,
          errorCode: () => null,
          errorParams: () => null,
          isValidating: false,
        ),
      );
      return true;
    }

    emit(
      state.copyWith(
        error: () => null,
        errorCode: () => null,
        errorParams: () => null,
        isValidating: true,
      ),
    );
    final token = _latestAsyncToken;
    final (asyncError, asyncCode, asyncParams) =
        await _executeAsyncValidators(state.value);

    if (token != _latestAsyncToken || isClosed) {
      // Superseded by a newer value or validation run. Report the outcome of
      // that run instead of the in-flight (and therefore "invalid") state.
      return _settledValidity();
    }

    emit(
      state.copyWith(
        error: () => asyncError,
        errorCode: () => asyncCode,
        errorParams: () => asyncParams,
        isValidating: false,
      ),
    );
    return asyncError == null;
  }

  /// Waits for any in-flight validation to finish, then returns [isValid].
  Future<bool> _settledValidity() async {
    if (!isClosed && state.isValidating) {
      await stream.firstWhere((s) => !s.isValidating, orElse: () => state);
    }
    return isValid;
  }

  /// Re-runs synchronous validation only, without touching async state.
  ///
  /// Used to establish the initial validity (errors stay hidden until the
  /// field is touched) and when a dependency is added.
  void _syncRevalidate() {
    final (syncError, syncCode, syncParams) = _runSyncValidation(state.value);
    if (syncError != null) {
      emit(
        state.copyWith(
          error: () => syncError,
          errorCode: () => syncCode,
          errorParams: () => syncParams,
        ),
      );
    } else if (_asyncValidators.isEmpty && state.error != null) {
      emit(
        state.copyWith(
          error: () => null,
          errorCode: () => null,
          errorParams: () => null,
        ),
      );
    }
  }

  (String?, String?, Map<String, dynamic>?) _runSyncValidation(T? val) {
    for (final validator in _validators) {
      final error = validator(val);
      if (error != null) {
        final meta = getValidatorMetadata(validator);
        return (error, meta?.errorCode, meta?.params);
      }
    }
    return (null, null, null);
  }

  Future<void> _runAsyncValidation(T? val, int token) async {
    if (token != _latestAsyncToken || isClosed) return;
    final (asyncError, asyncCode, asyncParams) =
        await _executeAsyncValidators(val);
    if (token != _latestAsyncToken || isClosed) return;

    emit(
      state.copyWith(
        error: () => asyncError,
        errorCode: () => asyncCode,
        errorParams: () => asyncParams,
        isValidating: false,
      ),
    );
  }

  Future<(String?, String?, Map<String, dynamic>?)> _executeAsyncValidators(
    T? val,
  ) async {
    for (final validator in _asyncValidators) {
      try {
        final error = await validator(val);
        if (error != null) {
          return (error, null, null);
        }
      } catch (error, stackTrace) {
        // Never surface raw exception text (hostnames, stack details) to the
        // user. Report it to the bloc observer and show a generic message.
        addError(error, stackTrace);
        return (
          MkFormLocalizations.current.asyncValidationFailed(),
          MkErrorCodes.asyncValidationFailed,
          null,
        );
      }
    }
    return (null, null, null);
  }

  @override
  Future<void> close() async {
    _debounceTimer?.cancel();
    for (final pair in _dependencyCallbacks) {
      pair.$1.removeStateListener(pair.$2);
    }
    _dependencyCallbacks.clear();
    return super.close();
  }
}
