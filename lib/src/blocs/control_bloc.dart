import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

/// Base abstract class for all form controls in mk_forms.
abstract class MkControlBloc<State> extends Cubit<State> {
  MkControlBloc(super.initialState);

  final List<void Function()> _stateListeners = [];

  /// Registers a synchronous listener invoked immediately when state changes.
  void addStateListener(void Function() listener) {
    _stateListeners.add(listener);
  }

  /// Removes a registered synchronous listener.
  void removeStateListener(void Function() listener) {
    _stateListeners.remove(listener);
  }

  /// Emits [state] and notifies state listeners, but only if it actually
  /// changed. Emitting after [close] is a silent no-op, so in-flight async work
  /// finishing late cannot throw.
  @protected
  @override
  void emit(State state) {
    if (isClosed) return;
    final changed = state != this.state;
    super.emit(state);
    if (!changed || _stateListeners.isEmpty) return;
    for (final listener in List.of(_stateListeners)) {
      listener();
    }
  }

  /// This control's value as last aggregated, without recomputing children.
  ///
  /// Aggregating controls override it to return their cached state so parents
  /// do not walk the whole subtree on every change.
  @internal
  dynamic get snapshotValue => value;

  /// Whether the control and all its children are valid.
  bool get isValid;

  /// Whether the control or any of its children are currently validating asynchronously.
  bool get isValidating;

  /// Whether the control's value has been modified from its initial value.
  bool get isDirty;

  /// Whether the control has been touched/interacted with by the user.
  bool get isTouched;

  /// The current value of this control.
  dynamic get value;

  /// Marks this control (and any children) as touched.
  void touch();

  /// Marks that the enclosing form has attempted submission.
  void markFormSubmitted([bool submitted = true]);

  /// Resets this control back to its initial value (or a provided new value)
  /// and marks it as pristine/untouched.
  void reset();

  /// Runs all synchronous and asynchronous validations for this control.
  /// Returns `true` if valid, `false` otherwise.
  Future<bool> validate();

  /// Closes any streams and resources.
  @override
  Future<void> close();
}
