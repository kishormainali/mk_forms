import 'dart:async';

import 'package:meta/meta.dart';

import '../batched_aggregate.dart';
import '../control_bloc.dart';
import '../field/field_bloc.dart';
import 'group_state.dart';

export 'group_state.dart';

/// A form control bloc that aggregates a map of named [MkControlBloc] children.
class MkGroupBloc extends MkControlBloc<MkGroupState> with MkBatchedAggregate {
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
      _assignLabelIfField(entry.key, entry.value);
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
  Map<String, dynamic> get snapshotValue => state.values;

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
  ///
  /// If [name] already has a control registered, it is replaced; the
  /// displaced control is closed unless [disposeReplaced] is `false`.
  void addControl(
    String name,
    MkControlBloc<dynamic> control, {
    bool disposeReplaced = true,
  }) {
    if (isClosed) return;
    final replacingSelf = identical(_controls[name], control);
    removeControl(name, dispose: disposeReplaced && !replacingSelf);
    _controls[name] = control;
    _assignLabelIfField(name, control);
    _listenToControl(name, control);
    _recalculateState();
  }

  /// Removes a control from this group dynamically.
  ///
  /// The removed control is closed by default, matching the invariant that
  /// a control never outlives its parent. Pass [dispose] as `false` when
  /// intentionally re-parenting the returned control elsewhere.
  MkControlBloc<dynamic>? removeControl(String name, {bool dispose = true}) {
    if (isClosed) return null;
    final callback = _listenerCallbacks.remove(name);
    final removed = _controls.remove(name);
    if (callback != null && removed != null) {
      removed.removeStateListener(callback);
    }
    if (dispose && removed != null) {
      unawaited(removed.close());
    }
    _recalculateState();
    return removed;
  }

  /// Runs [action] and recomputes this group's aggregate (and notifies
  /// parents) **once** afterwards, instead of once per child change.
  ///
  /// Used by [MkFormBloc] for bulk operations such as populating values or
  /// touching a subset of controls, which would otherwise be O(n²).
  @internal
  void batch(void Function() action) => runBatched(action, _recalculateState);

  @override
  void touch() {
    runBatched(() {
      for (final control in _controls.values) {
        control.touch();
      }
    }, _recalculateState);
  }

  /// Marks that the enclosing form has attempted submission across all child controls.
  @override
  void markFormSubmitted([bool submitted = true]) {
    runBatched(() {
      for (final control in _controls.values) {
        control.markFormSubmitted(submitted);
      }
    }, _recalculateState);
  }

  @override
  void reset() {
    runBatched(() {
      for (final control in _controls.values) {
        control.reset();
      }
    }, _recalculateState);
  }

  @override
  Future<bool> validate() async {
    final pending = <Future<bool>>[];
    // Synchronous validators finish (and emit) inside this loop; batching folds
    // them into a single recalculation. Async ones recalculate as they settle.
    runBatched(() {
      for (final control in List.of(_controls.values)) {
        pending.add(control.validate());
      }
    }, _recalculateState);
    final results = await Future.wait(pending);
    return results.every((valid) => valid);
  }

  void _listenToControl(String name, MkControlBloc<dynamic> control) {
    void callback() {
      if (isClosed || deferIfBatching()) return;
      _recalculateState();
    }

    _listenerCallbacks[name] = callback;
    control.addStateListener(callback);
  }

  /// Auto-derives [control]'s label from [name] if it's an [MkFieldBloc]
  /// (a no-op for groups/arrays, and a no-op if the field already has an
  /// explicit label — see [MkFieldBloc.assignAutoLabel]).
  void _assignLabelIfField(String name, MkControlBloc<dynamic> control) {
    if (control is MkFieldBloc) {
      control.assignAutoLabel(name);
    }
  }

  /// Recomputes the aggregate in a single pass over the children.
  void _recalculateState() {
    if (isClosed) return;
    var isValid = true;
    var isValidating = false;
    var isDirty = false;
    var isTouched = false;
    final values = <String, dynamic>{};
    for (final entry in _controls.entries) {
      final control = entry.value;
      values[entry.key] = control.snapshotValue;
      isValid = isValid && control.isValid;
      isValidating = isValidating || control.isValidating;
      isDirty = isDirty || control.isDirty;
      isTouched = isTouched || control.isTouched;
    }
    emit(
      MkGroupState(
        values: values,
        isValid: isValid,
        isValidating: isValidating,
        isDirty: isDirty,
        isTouched: isTouched,
      ),
    );
  }

  static Map<String, dynamic> _extractValues(
    Map<String, MkControlBloc<dynamic>> controls,
  ) {
    return {for (final entry in controls.entries) entry.key: entry.value.value};
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
