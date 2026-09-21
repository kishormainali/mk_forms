import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/form_bloc.dart';
import 'form_scope.dart';

/// Function signature for building a widget based on [MkFormState].
typedef MkFormWidgetBuilder =
    Widget Function(
      BuildContext context,
      MkFormState state,
      MkFormBloc formBloc,
    );

/// Function signature for building a widget based on a custom form state [S].
typedef MkFormStateWidgetBuilder<S extends MkFormState> =
    Widget Function(BuildContext context, S state, MkFormBloc formBloc);

/// A reactive widget that rebuilds when the state of an [MkFormBloc] changes.
///
/// Useful for things like submit buttons that depend on form validity or
/// submission status. Prefer [MkFieldBuilder] / [MkSubformBuilder] for
/// per-field or per-section UI so typing does not rebuild the whole form.
///
/// When the form bloc uses a custom [MkFormState] subclass, use
/// [MkFormStateBuilder] to receive it without casts.
class MkFormBuilder extends StatelessWidget {
  const MkFormBuilder({
    super.key,
    this.formBloc,
    this.buildWhen,
    required this.builder,
  });

  /// The form bloc to build from. If null, it will be looked up via [MkFormScope] or [BlocProvider].
  final MkFormBloc? formBloc;

  /// Optional condition determining whether the builder should be called.
  final bool Function(MkFormState previous, MkFormState current)? buildWhen;

  /// The builder function called when the form state changes.
  final MkFormWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return MkFormStateBuilder<MkFormState>(
      formBloc: formBloc,
      buildWhen: buildWhen,
      builder: builder,
    );
  }
}

/// Like [MkFormBuilder], but hands the builder a custom [MkFormState] subclass
/// [S] instead of the base type.
///
/// The type argument must be written explicitly (Dart cannot infer it from an
/// unannotated builder closure):
///
/// ```dart
/// MkFormStateBuilder<ProfileFormState>(
///   buildWhen: (prev, curr) => prev.avatarStatus != curr.avatarStatus,
///   builder: (context, state, bloc) => Text('${state.avatarStatus}'),
/// )
/// ```
///
/// A [StateError] is thrown if the bloc's state is not an [S].
class MkFormStateBuilder<S extends MkFormState> extends StatelessWidget {
  const MkFormStateBuilder({
    super.key,
    this.formBloc,
    this.buildWhen,
    required this.builder,
  });

  /// The form bloc to build from. If null, it will be looked up via [MkFormScope] or [BlocProvider].
  final MkFormBloc? formBloc;

  /// Optional condition determining whether the builder should be called.
  final bool Function(S previous, S current)? buildWhen;

  /// The builder function called when the form state changes.
  final MkFormStateWidgetBuilder<S> builder;

  static S _typed<S extends MkFormState>(MkFormState state) {
    if (state is S) return state;
    throw StateError(
      'MkFormStateBuilder<$S> expected the form bloc state to be $S, '
      'but it is ${state.runtimeType}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = formBloc ?? MkFormScope.of(context);
    final condition = buildWhen;

    return BlocBuilder<MkFormBloc, MkFormState>(
      bloc: bloc,
      buildWhen: condition == null
          ? null
          : (previous, current) =>
                condition(_typed<S>(previous), _typed<S>(current)),
      builder: (context, state) => builder(context, _typed<S>(state), bloc),
    );
  }
}
