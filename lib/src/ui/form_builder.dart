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

/// A reactive widget that rebuilds when the state of an [MkFormBloc] changes.
///
/// Useful for things like submit buttons that depend on form validity or
/// submission status. Prefer [MkFieldBuilder] / [MkSubformBuilder] for
/// per-field or per-section UI so typing does not rebuild the whole form.
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
    final bloc = formBloc ?? MkFormScope.of(context);

    return BlocBuilder<MkFormBloc, MkFormState>(
      bloc: bloc,
      buildWhen: buildWhen,
      builder: (context, state) => builder(context, state, bloc),
    );
  }
}
