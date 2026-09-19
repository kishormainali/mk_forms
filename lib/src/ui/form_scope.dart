import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/field_bloc.dart';
import '../blocs/form_bloc.dart';
import '../blocs/group_bloc.dart';

/// Provides an [MkFormBloc] to descendant widgets down the widget tree.
class MkFormScope extends InheritedWidget {
  const MkFormScope({
    super.key,
    required this.formBloc,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    required super.child,
  });

  final MkFormBloc formBloc;

  /// The default [AutovalidateMode] for fields enclosed within this scope.
  final AutovalidateMode autovalidateMode;

  /// Retrieves the nearest [MkFormBloc] from [context].
  static MkFormBloc of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MkFormScope>();
    if (scope != null) return scope.formBloc;
    return context.read<MkFormBloc>();
  }

  /// Retrieves the nearest [MkFormBloc] from [context], or null if not found.
  static MkFormBloc? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MkFormScope>();
    if (scope != null) return scope.formBloc;
    try {
      return context.read<MkFormBloc>();
    } catch (_) {
      return null;
    }
  }

  /// Retrieves the [AutovalidateMode] from the nearest [MkFormScope],
  /// defaulting to [AutovalidateMode.onUserInteraction] if none is found.
  static AutovalidateMode autovalidateModeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MkFormScope>();
    return scope?.autovalidateMode ?? AutovalidateMode.onUserInteraction;
  }

  /// Retrieves the [AutovalidateMode] from the nearest [MkFormScope], or null if none.
  static AutovalidateMode? maybeAutovalidateModeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MkFormScope>();
    return scope?.autovalidateMode;
  }

  @override
  bool updateShouldNotify(MkFormScope oldWidget) =>
      formBloc != oldWidget.formBloc ||
      autovalidateMode != oldWidget.autovalidateMode;
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
