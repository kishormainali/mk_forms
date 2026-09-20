import 'dart:async';
import '../batched_aggregate.dart';
import '../control_bloc.dart';
import 'array_state.dart';

export 'array_state.dart';

/// A form control bloc managing a dynamic list/array of [MkControlBloc] children.
class MkArrayBloc<C extends MkControlBloc<dynamic>>
    extends MkControlBloc<MkArrayState<C>>
    with MkBatchedAggregate {
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
  List<dynamic> get snapshotValue => state.values;

  // Kept up to date by the child listeners; O(1) instead of walking children.
  @override
  bool get isValid => state.isValid;

  @override
  bool get isValidating => state.isValidating;

  @override
  bool get isDirty => state.isDirty;

  @override
  bool get isTouched => state.isTouched;

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
    runBatched(() {
      for (final control in _controls) {
        control.touch();
      }
    }, _recalculateState);
  }

  /// Marks that the enclosing form has attempted submission.
  @override
  void markFormSubmitted([bool submitted = true]) {
    runBatched(() {
      for (final control in _controls) {
        control.markFormSubmitted(submitted);
      }
    }, _recalculateState);
  }

  @override
  void reset() {
    runBatched(() {
      for (final control in _controls) {
        control.reset();
      }
    }, _recalculateState);
  }

  @override
  Future<bool> validate() async {
    final pending = <Future<bool>>[];
    runBatched(() {
      for (final control in List.of(_controls)) {
        pending.add(control.validate());
      }
    }, _recalculateState);
    final results = await Future.wait(pending);
    return results.every((v) => v);
  }

  void _listenToControl(C control) {
    void callback() {
      if (isClosed || deferIfBatching()) return;
      _recalculateState();
    }

    _listenerCallbacks[control] = callback;
    control.addStateListener(callback);
  }

  /// Recomputes the aggregate in a single pass over the children.
  void _recalculateState() {
    if (isClosed) return;
    var isValid = true;
    var isValidating = false;
    var isDirty = false;
    var isTouched = false;
    final values = <dynamic>[];
    for (final control in _controls) {
      values.add(control.snapshotValue);
      isValid = isValid && control.isValid;
      isValidating = isValidating || control.isValidating;
      isDirty = isDirty || control.isDirty;
      isTouched = isTouched || control.isTouched;
    }
    emit(
      MkArrayState<C>(
        controls: List.unmodifiable(_controls),
        values: values,
        isValid: isValid,
        isValidating: isValidating,
        isDirty: isDirty,
        isTouched: isTouched,
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
