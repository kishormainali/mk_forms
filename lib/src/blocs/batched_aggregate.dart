import 'package:meta/meta.dart';
import 'control_bloc.dart';

/// Lets a control that aggregates children (group, array) apply a bulk
/// operation to all of them and recompute its own state **once**, instead of
/// once per child emission.
///
/// Without batching, `touch()` / `reset()` / `validate()` on a form with `n`
/// fields recomputes an `O(n)` aggregate `n` times.
mixin MkBatchedAggregate<S> on MkControlBloc<S> {
  int _batchDepth = 0;
  bool _batchDirty = false;

  /// Call from a child listener. Returns `true` if a batch is running, in
  /// which case the change is remembered and the caller must not recompute.
  @protected
  bool deferIfBatching() {
    if (_batchDepth == 0) return false;
    _batchDirty = true;
    return true;
  }

  /// Runs [action], then calls [flush] once if any child changed meanwhile.
  @protected
  void runBatched(void Function() action, void Function() flush) {
    _batchDepth++;
    try {
      action();
    } finally {
      _batchDepth--;
    }
    if (_batchDepth == 0 && _batchDirty) {
      _batchDirty = false;
      flush();
    }
  }
}
