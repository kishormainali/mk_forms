import 'dart:async';
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
    _initialValidate();

    // Setup dependencies
    for (final dependency in dependsOn) {
      addDependency(dependency);
    }
  }

  final List<Validator<T>> _validators;
  final List<AsyncValidator<T>> _asyncValidators;
  final Duration _debounceTime;

  final List<(MkControlBloc<dynamic>, void Function())> _dependencyCallbacks = [];
  final List<MkFieldBloc<dynamic>> _dependents = [];
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

  bool _isValidatingInternal = false;

  /// Adds a dependency on [otherControl]. When [otherControl] changes value,
  /// this field will automatically revalidate.
  void addDependency(MkControlBloc<dynamic> otherControl) {
    if (otherControl is MkFieldBloc) {
      otherControl._dependents.add(this);
    }
    dynamic previousValue = otherControl.value;

    void callback() {
      if (isClosed) return;
      final currentValue = otherControl.value;
      if (currentValue != previousValue) {
        previousValue = currentValue;
        if (!_isValidatingInternal) {
          _isValidatingInternal = true;
          try {
            unawaited(validate(cascadeDependents: false));
          } finally {
            _isValidatingInternal = false;
          }
        }
      }
    }

    _dependencyCallbacks.add((otherControl, callback));
    otherControl.addStateListener(callback);

    // Initial validation against current state of dependency
    if (!_isValidatingInternal) {
      _isValidatingInternal = true;
      try {
        unawaited(validate(cascadeDependents: false));
      } finally {
        _isValidatingInternal = false;
      }
    }
  }

  /// Changes the value of this field.
  ///
  /// Recomputes [isDirty], runs synchronous validation, and triggers
  /// debounced async validation if synchronous validation passes.
  void changeValue(T? newValue) {
    if (isClosed) return;

    _debounceTimer?.cancel();
    _latestAsyncToken++;

    final isDirty = newValue != state.initialValue;
    final (syncError, syncCode, syncParams) = _runSyncValidation(newValue);

    if (syncError != null || _asyncValidators.isEmpty) {
      emit(
        state.copyWith(
          value: () => newValue,
          isDirty: isDirty,
          error: () => syncError,
          errorCode: () => syncCode,
          errorParams: () => syncParams,
          isValidating: false,
        ),
      );
      _notifyDependents();
    } else {
      // Sync passed, start async debounced validation
      emit(
        state.copyWith(
          value: () => newValue,
          isDirty: isDirty,
          error: () => null,
          errorCode: () => null,
          errorParams: () => null,
          isValidating: true,
        ),
      );
      _notifyDependents();

      final currentToken = _latestAsyncToken;
      _debounceTimer = Timer(_debounceTime, () {
        unawaited(_runAsyncValidation(newValue, currentToken));
      });
    }
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

    _debounceTimer?.cancel();
    _latestAsyncToken++;

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
    _notifyDependents();
  }

  /// Runs all validations on the current field value.
  ///
  /// Set [cascadeDependents] to false when called from a dependency update
  /// to prevent circular cascade loops.
  @override
  Future<bool> validate({bool cascadeDependents = true}) async {
    if (isClosed) return isValid;

    _debounceTimer?.cancel();
    _latestAsyncToken++;

    final (syncError, syncCode, syncParams) =
        _runSyncValidation(state.value);

    if (syncError != null) {
      emit(
        state.copyWith(
          error: () => syncError,
          errorCode: () => syncCode,
          errorParams: () => syncParams,
          isValidating: false,
        ),
      );
      if (cascadeDependents) _notifyDependents();
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
      if (cascadeDependents) _notifyDependents();
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
      return isValid;
    }

    emit(
      state.copyWith(
        error: () => asyncError,
        errorCode: () => asyncCode,
        errorParams: () => asyncParams,
        isValidating: false,
      ),
    );
    if (cascadeDependents) _notifyDependents();
    return asyncError == null;
  }

  void _initialValidate() {
    final (syncError, syncCode, syncParams) =
        _runSyncValidation(state.value);
    if (syncError != null) {
      emit(
        state.copyWith(
          error: () => syncError,
          errorCode: () => syncCode,
          errorParams: () => syncParams,
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
      } catch (e) {
        return (e.toString(), null, null);
      }
    }
    return (null, null, null);
  }

  void _notifyDependents() {
    for (final dependent in _dependents) {
      unawaited(dependent.validate(cascadeDependents: false));
    }
  }

  @override
  Future<void> close() async {
    _debounceTimer?.cancel();
    for (final pair in _dependencyCallbacks) {
      pair.$1.removeStateListener(pair.$2);
    }
    _dependencyCallbacks.clear();
    _dependents.clear();
    return super.close();
  }
}
