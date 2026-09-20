import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/field_bloc.dart';
import '../blocs/form_bloc.dart';
import '../blocs/group_bloc.dart';

/// Provides an [MkFormBloc] to descendant widgets down the widget tree.
///
/// Built on top of [BlocProvider], so the form bloc is also reachable with
/// plain `context.read<MkFormBloc>()` / `BlocProvider.of<MkFormBloc>()`.
///
/// Like [BlocProvider], there are two ways to supply the bloc:
///
/// ```dart
/// // The scope creates the bloc and closes it when removed from the tree.
/// MkFormScope(
///   create: (context) => LoginFormBloc(),
///   child: const LoginForm(),
/// )
///
/// // The scope exposes an existing bloc and does NOT close it.
/// MkFormScope.value(
///   value: existingFormBloc,
///   child: const LoginForm(),
/// )
/// ```
class MkFormScope extends StatelessWidget {
  /// Creates the [MkFormBloc] with [create] and closes it automatically when
  /// this scope is removed from the widget tree.
  ///
  /// When [lazy] is true (the default) the bloc is created the first time it
  /// is looked up.
  const MkFormScope({
    super.key,
    required MkFormBloc Function(BuildContext context) create,
    this.lazy = true,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    required this.child,
  }) : _create = create,
       _value = null;

  /// Exposes an existing [value] without taking ownership of it: the scope
  /// never closes it.
  const MkFormScope.value({
    super.key,
    required MkFormBloc value,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    required this.child,
  }) : _value = value,
       _create = null,
       lazy = true;

  final MkFormBloc Function(BuildContext context)? _create;
  final MkFormBloc? _value;

  /// Whether the bloc is created lazily. Only applies to the [create] constructor.
  final bool lazy;

  /// The default [AutovalidateMode] for fields enclosed within this scope.
  final AutovalidateMode autovalidateMode;

  /// The widget below this scope.
  final Widget child;

  /// Retrieves the nearest [MkFormBloc] from [context].
  ///
  /// Does not subscribe [context] to form state changes; use [MkFormBuilder]
  /// for that.
  static MkFormBloc of(BuildContext context) =>
      BlocProvider.of<MkFormBloc>(context);

  /// Retrieves the nearest [MkFormBloc] from [context], or null if not found.
  static MkFormBloc? maybeOf(BuildContext context) =>
      context.read<MkFormBloc?>();

  /// Retrieves the [AutovalidateMode] from the nearest [MkFormScope],
  /// defaulting to [AutovalidateMode.onUserInteraction] if none is found.
  static AutovalidateMode autovalidateModeOf(BuildContext context) =>
      maybeAutovalidateModeOf(context) ?? AutovalidateMode.onUserInteraction;

  /// Retrieves the [AutovalidateMode] from the nearest [MkFormScope], or null if none.
  ///
  /// Subscribes [context] so it rebuilds when the scope's mode changes.
  static AutovalidateMode? maybeAutovalidateModeOf(BuildContext context) =>
      context.watch<AutovalidateMode?>();

  @override
  Widget build(BuildContext context) {
    final value = _value;
    final inner = RepositoryProvider<AutovalidateMode>.value(
      value: autovalidateMode,
      child: child,
    );
    return value != null
        ? BlocProvider<MkFormBloc>.value(value: value, child: inner)
        : BlocProvider<MkFormBloc>(create: _create!, lazy: lazy, child: inner);
  }
}

/// Convenience extensions on [BuildContext] for easy form and field lookup.
extension MkFormContextX on BuildContext {
  /// Shorthand to access the nearest [MkFormBloc].
  MkFormBloc get mkForm => MkFormScope.of(this);

  /// Shorthand to access the active [AutovalidateMode] from the nearest [MkFormScope].
  AutovalidateMode get mkAutovalidateMode =>
      MkFormScope.autovalidateModeOf(this);

  /// Shorthand to access an [MkFieldBloc<T>] by [name] from the nearest [MkFormBloc].
  MkFieldBloc<T>? mkField<T>(String name) => mkForm.field<T>(name);

  /// Shorthand to access an [MkGroupBloc] by [name] from the nearest [MkFormBloc].
  MkGroupBloc? mkGroup(String name) => mkForm.root.group(name);
}
