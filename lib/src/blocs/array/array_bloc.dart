import 'dart:async';
import '../control_bloc.dart';
import 'array_state.dart';

export 'array_state.dart';

/// A form control bloc managing a dynamic list/array of [MkControlBloc] children.
class MkArrayBloc<C extends MkControlBloc<dynamic>>
    extends MkControlBloc<MkArrayState<C>> {
  MkArrayBloc([List<C> initialControls = const []])
      : _controls = List<C>.of(initialControls),
        super(
          MkArrayState<C>(
            controls: List.unmodifiable(initialControls),
            values: initialControls.map((c) => c.value).toList(),
            isValid: initialControls.every((c) => c.isValid),
            isValidating: initialControls.any((c) => c.isValidating),
            isDirty: initialControls.any((c) => c.isDirty),
            isTouched: initialControls.any((c) => c.isTouched),
          ),
        ) {
    for (final control in _controls) {
      _listenToControl(control);
    }
  }

  final List<C> _controls;
  final Map<C, void Function()> _listenerCallbacks = {};

  /// Current list of controls (unmodifiable).
  List<C> get controls => List.unmodifiable(_controls);

  @override
  List<dynamic> get value => _controls.map((c) => c.value).toList();

  @override
  bool get isValid => _controls.every((c) => c.isValid);

  @override
  bool get isValidating => _controls.any((c) => c.isValidating);

  @override
  bool get isDirty => _controls.any((c) => c.isDirty);

  @override
  bool get isTouched => _controls.any((c) => c.isTouched);

  int get length => _controls.length;

  C operator [](int index) => _controls[index];

  /// Appends a new control to the array.
  void add(C control) {
    if (isClosed) return;
    _controls.add(control);
    _listenToControl(control);
    _recalculateState();
  }

  /// Inserts a control at [index].
  void insert(int index, C control) {
    if (isClosed) return;
    _controls.insert(index, control);
    _listenToControl(control);
    _recalculateState();
  }

  /// Removes the control at [index].
  C? removeAt(int index) {
    if (isClosed || index < 0 || index >= _controls.length) return null;
    final removed = _controls.removeAt(index);
    final callback = _listenerCallbacks.remove(removed);
    if (callback != null) {
      removed.removeStateListener(callback);
    }
    _recalculateState();
    return removed;
  }

  /// Removes the specified [control].
  bool remove(C control) {
    if (isClosed) return false;
    final removed = _controls.remove(control);
    if (removed) {
      final callback = _listenerCallbacks.remove(control);
      if (callback != null) {
        control.removeStateListener(callback);
      }
      _recalculateState();
    }
    return removed;
  }

  /// Moves a control from [oldIndex] to [newIndex].
  void move(int oldIndex, int newIndex) {
    if (isClosed) return;
    if (oldIndex < 0 || oldIndex >= _controls.length) return;
    if (newIndex < 0 || newIndex >= _controls.length) return;
    final item = _controls.removeAt(oldIndex);
    _controls.insert(newIndex, item);
    _recalculateState();
  }

  /// Clears all controls in this array.
  void clear() {
    if (isClosed) return;
    for (final entry in _listenerCallbacks.entries) {
      entry.key.removeStateListener(entry.value);
    }
    _listenerCallbacks.clear();
    _controls.clear();
    _recalculateState();
  }

  @override
  void touch() {
    for (final control in _controls) {
      control.touch();
    }
    _recalculateState();
  }

  /// Marks that the enclosing form has attempted submission.
  @override
  void markFormSubmitted([bool submitted = true]) {
    for (final control in _controls) {
      control.markFormSubmitted(submitted);
    }
  }

  @override
  void reset() {
    for (final control in _controls) {
      control.reset();
    }
    _recalculateState();
  }

  @override
  Future<bool> validate() async {
    final results = await Future.wait(_controls.map((c) => c.validate()));
    _recalculateState();
    return results.every((v) => v);
  }

  void _listenToControl(C control) {
    void callback() {
      if (!isClosed) {
        _recalculateState();
      }
    }

    _listenerCallbacks[control] = callback;
    control.addStateListener(callback);
  }

  void _recalculateState() {
    emit(
      MkArrayState<C>(
        controls: List.unmodifiable(_controls),
        values: _controls.map((c) => c.value).toList(),
        isValid: _controls.every((c) => c.isValid),
        isValidating: _controls.any((c) => c.isValidating),
        isDirty: _controls.any((c) => c.isDirty),
        isTouched: _controls.any((c) => c.isTouched),
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final entry in _listenerCallbacks.entries) {
      entry.key.removeStateListener(entry.value);
    }
    _listenerCallbacks.clear();
    for (final control in _controls) {
      await control.close();
    }
    return super.close();
  }
}
