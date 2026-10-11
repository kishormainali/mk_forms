import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/array_bloc.dart';
import '../blocs/control_bloc.dart';
import '../core/deep_equals.dart';
import 'form_scope.dart';

/// Function signature for building a widget based on [MkArrayState].
typedef MkArrayWidgetBuilder<C extends MkControlBloc<dynamic>> =
    Widget Function(
      BuildContext context,
      MkArrayState<C> state,
      MkArrayBloc<C> arrayBloc,
    );

/// A widget that rebuilds when the *structure* of an [MkArrayBloc] changes
/// (a control is added, inserted, removed or moved), not on every edit of a
/// row.
///
/// [MkArrayState] also carries the aggregated `values`, so a plain
/// `BlocBuilder` on the array rebuilds **every row** each time the user types
/// in **one** row. This builder defaults [buildWhen] to "the list of controls
/// changed", so each row — itself a field widget that listens to its own
/// bloc — keeps updating independently while the list is rebuilt only when it
/// must be.
///
/// The `state` handed to [builder] is a snapshot from the last rebuild, so its
/// `values` can be stale while a row is being edited. Read live values from
/// the bloc (`arrayBloc.state.values` / `arrayBloc.value`), or set
/// [rebuildOnValueChange] to rebuild whenever any row's value changes (use it
/// for UI that *displays* the values, such as a summary line).
///
/// Pass [buildWhen] to also react to aggregate flags, e.g. to disable an
/// "add" button while the array is invalid:
///
/// ```dart
/// MkArrayBuilder<MkFieldBloc<String>>(
///   arrayBloc: phones,
///   buildWhen: (p, c) => p.controls != c.controls || p.isValid != c.isValid,
///   builder: (context, state, array) => ...,
/// )
/// ```
class MkArrayBuilder<C extends MkControlBloc<dynamic>> extends StatelessWidget {
  const MkArrayBuilder({
    super.key,
    this.arrayBloc,
    this.name,
    this.buildWhen,
    this.rebuildOnValueChange = false,
    required this.builder,
  }) : assert(
         arrayBloc != null || name != null,
         'Either arrayBloc or name must be provided to MkArrayBuilder',
       );

  /// The target array bloc.
  final MkArrayBloc<C>? arrayBloc;

  /// The name of the array bloc in the nearest [MkFormScope], if [arrayBloc]
  /// is not passed.
  final String? name;

  /// Optional condition determining whether the builder should be called.
  ///
  /// Defaults to rebuilding only when the list of controls changes.
  final bool Function(MkArrayState<C> previous, MkArrayState<C> current)?
  buildWhen;

  /// Whether to also rebuild when any row's value changes (default `false`).
  ///
  /// Ignored when [buildWhen] is given.
  final bool rebuildOnValueChange;

  /// The builder function called when the array state changes.
  final MkArrayWidgetBuilder<C> builder;

  static bool _structureChanged<C extends MkControlBloc<dynamic>>(
    MkArrayState<C> previous,
    MkArrayState<C> current,
  ) {
    final a = previous.controls;
    final b = current.controls;
    if (identical(a, b)) return false;
    if (a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bloc =
        arrayBloc ??
        (name != null ? context.mkForm.control<MkArrayBloc<C>>(name!) : null);

    if (bloc == null) {
      throw StateError(
        'MkArrayBuilder could not find an MkArrayBloc<$C> for name: "$name". '
        'Ensure the array is registered in the MkFormBloc and wrapped in an MkFormScope.',
      );
    }

    return BlocBuilder<MkArrayBloc<C>, MkArrayState<C>>(
      bloc: bloc,
      buildWhen:
          buildWhen ??
          (rebuildOnValueChange
              ? (p, c) =>
                    _structureChanged(p, c) || !mkDeepEquals(p.values, c.values)
              : _structureChanged),
      builder: (context, state) => builder(context, state, bloc),
    );
  }
}
