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
    _view = state.controls;
  }

  final List<C> _controls;
  final Map<C, void Function()> _listenerCallbacks = {};

  // Unmodifiable snapshot of [_controls], rebuilt only when the structure
  // changes. Row edits reuse it, so `state.controls` stays the same instance.
  List<C>? _view;

  /// Current list of controls (unmodifiable).
  List<C> get controls => _view ??= List.unmodifiable(_controls);

  @override
  List<dynamic> get value => _controls.map((c) => c.value).toList();

  @override
  List<dynamic> get snapshotValue => state.values;

  // Kept up to date by a full recompute over direct children on every child
  // change (see `_recalculateState`); reads of these flags/`snapshotValue`
  // are themselves O(1) against the cached state, with no subtree walk.
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

  /// Runs [action] and recomputes this array's aggregate (and notifies
  /// parents and listeners) **once** afterwards, instead of once per change.
  ///
  /// Use it to apply several structural changes (`add`, `removeAt`, ...) or
  /// edits to rows as one update.
  void batch(void Function() action) => runBatched(action, _recalculateState);

  /// Appends [controls] to the array with a single state update.
  void addAll(Iterable<C> controls) {
    if (isClosed) return;
    batch(() {
      for (final control in controls) {
        add(control);
      }
    });
  }

  /// Replaces every control in the array with [controls] using a single state
  /// update, and returns the controls that were removed.
  ///
  /// Controls present in both the old and the new list stay and are never
  /// closed. The removed ones are closed by default; pass [dispose] as `false`
  /// when intentionally re-parenting them elsewhere.
  List<C> replaceAll(Iterable<C> controls, {bool dispose = true}) {
    if (isClosed) return <C>[];
    final next = List<C>.of(controls);
    final keep = next.toSet();
    final removed = [
      for (final control in _controls)
        if (!keep.contains(control)) control,
    ];
    batch(() {
      for (final entry in _listenerCallbacks.entries) {
        entry.key.removeStateListener(entry.value);
      }
      _listenerCallbacks.clear();
      _controls
        ..clear()
        ..addAll(next);
      next.forEach(_listenToControl);
      _structureChanged();
    });
    if (dispose) {
      for (final control in removed) {
        unawaited(control.close());
      }
    }
    return removed;
  }

  /// Appends a new control to the array.
  void add(C control) {
    if (isClosed) return;
    _controls.add(control);
    _listenToControl(control);
    _structureChanged();
  }

  /// Inserts a control at [index].
  void insert(int index, C control) {
    if (isClosed) return;
    _controls.insert(index, control);
    _listenToControl(control);
    _structureChanged();
  }

  /// Removes the control at [index].
  ///
  /// The removed control is closed by default, matching the invariant that
  /// a control never outlives its parent. Pass [dispose] as `false` when
  /// intentionally re-parenting the returned control elsewhere.
  C? removeAt(int index, {bool dispose = true}) {
    if (isClosed || index < 0 || index >= _controls.length) return null;
    final removed = _controls.removeAt(index);
    final callback = _listenerCallbacks.remove(removed);
    if (callback != null) {
      removed.removeStateListener(callback);
    }
    if (dispose) {
      unawaited(removed.close());
    }
    _structureChanged();
    return removed;
  }

  /// Removes the specified [control].
  ///
  /// The removed control is closed by default; pass [dispose] as `false`
  /// when intentionally re-parenting it elsewhere.
  bool remove(C control, {bool dispose = true}) {
    if (isClosed) return false;
    final removed = _controls.remove(control);
    if (removed) {
      final callback = _listenerCallbacks.remove(control);
      if (callback != null) {
        control.removeStateListener(callback);
      }
      if (dispose) {
        unawaited(control.close());
      }
      _structureChanged();
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
    _structureChanged();
  }

  /// Clears all controls in this array, returning the controls that were
  /// removed.
  ///
  /// Every removed control is closed by default; pass [dispose] as `false`
  /// when intentionally re-parenting some or all of them elsewhere.
  List<C> clear({bool dispose = true}) {
    if (isClosed) return <C>[];
    for (final entry in _listenerCallbacks.entries) {
      entry.key.removeStateListener(entry.value);
    }
    _listenerCallbacks.clear();
    final removed = List<C>.of(_controls);
    _controls.clear();
    if (dispose) {
      for (final control in removed) {
        unawaited(control.close());
      }
    }
    _structureChanged();
    return removed;
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

  /// The list of controls changed: drop the cached view and recompute.
  void _structureChanged() {
    _view = null;
    if (deferIfBatching()) return;
    _recalculateState();
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
        controls: controls,
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
    // Children are independent, so close them concurrently.
    await Future.wait([for (final control in _controls) control.close()]);
    return super.close();
  }
}
