import '../control_bloc.dart';
import '../field/field_bloc.dart';
import 'group_state.dart';

export 'group_state.dart';

/// A form control bloc that aggregates a map of named [MkControlBloc] children.
class MkGroupBloc extends MkControlBloc<MkGroupState> {
  MkGroupBloc(Map<String, MkControlBloc<dynamic>> controls)
      : _controls = Map.of(controls),
        super(
          MkGroupState(
            values: _extractValues(controls),
            isValid: controls.values.every((c) => c.isValid),
            isValidating: controls.values.any((c) => c.isValidating),
            isDirty: controls.values.any((c) => c.isDirty),
            isTouched: controls.values.any((c) => c.isTouched),
          ),
        ) {
    for (final entry in _controls.entries) {
      _listenToControl(entry.key, entry.value);
    }
  }

  final Map<String, MkControlBloc<dynamic>> _controls;
  final Map<String, void Function()> _listenerCallbacks = {};

  /// Returns an unmodifiable map of the child controls.
  Map<String, MkControlBloc<dynamic>> get controls =>
      Map.unmodifiable(_controls);

  @override
  Map<String, dynamic> get value => _extractValues(_controls);

  @override
  bool get isValid => _controls.values.every((c) => c.isValid);

  @override
  bool get isValidating => _controls.values.any((c) => c.isValidating);

  @override
  bool get isDirty => _controls.values.any((c) => c.isDirty);

  @override
  bool get isTouched => _controls.values.any((c) => c.isTouched);

  /// Retrieves a child control of type [C] by [name].
  C? control<C extends MkControlBloc<dynamic>>(String name) {
    final ctrl = _controls[name];
    return ctrl is C ? ctrl : null;
  }

  /// Shorthand to retrieve a child [MkFieldBloc<T>] by [name].
  MkFieldBloc<T>? field<T>(String name) {
    return control<MkFieldBloc<T>>(name);
  }

  /// Shorthand to retrieve a child [MkGroupBloc] by [name].
  MkGroupBloc? group(String name) {
    return control<MkGroupBloc>(name);
  }

  /// Adds a new control to this group dynamically.
  void addControl(String name, MkControlBloc<dynamic> control) {
    if (isClosed) return;
    removeControl(name);
    _controls[name] = control;
    _listenToControl(name, control);
    _recalculateState();
  }

  /// Removes a control from this group dynamically.
  void removeControl(String name) {
    if (isClosed) return;
    final callback = _listenerCallbacks.remove(name);
    if (callback != null) {
      _controls[name]?.removeStateListener(callback);
    }
    _controls.remove(name);
    _recalculateState();
  }

  @override
  void touch() {
    for (final control in _controls.values) {
      control.touch();
    }
    _recalculateState();
  }

  /// Marks that the enclosing form has attempted submission across all child controls.
  @override
  void markFormSubmitted([bool submitted = true]) {
    for (final control in _controls.values) {
      control.markFormSubmitted(submitted);
    }
  }

  @override
  void reset() {
    for (final control in _controls.values) {
      control.reset();
    }
    _recalculateState();
  }

  @override
  Future<bool> validate() async {
    final results = await Future.wait(
      _controls.values.map((c) => c.validate()),
    );
    _recalculateState();
    return results.every((valid) => valid);
  }

  void _listenToControl(String name, MkControlBloc<dynamic> control) {
    void callback() {
      if (!isClosed) {
        _recalculateState();
      }
    }

    _listenerCallbacks[name] = callback;
    control.addStateListener(callback);
  }

  void _recalculateState() {
    emit(
      MkGroupState(
        values: _extractValues(_controls),
        isValid: _controls.values.every((c) => c.isValid),
        isValidating: _controls.values.any((c) => c.isValidating),
        isDirty: _controls.values.any((c) => c.isDirty),
        isTouched: _controls.values.any((c) => c.isTouched),
      ),
    );
  }

  static Map<String, dynamic> _extractValues(
    Map<String, MkControlBloc<dynamic>> controls,
  ) {
    return {
      for (final entry in controls.entries) entry.key: entry.value.value,
    };
  }

  @override
  Future<void> close() async {
    for (final entry in _listenerCallbacks.entries) {
      _controls[entry.key]?.removeStateListener(entry.value);
    }
    _listenerCallbacks.clear();
    for (final control in _controls.values) {
      await control.close();
    }
    return super.close();
  }
}
