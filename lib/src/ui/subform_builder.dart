import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/group_bloc.dart';
import 'form_scope.dart';

/// Function signature for building a widget based on [MkGroupState].
typedef MkSubformWidgetBuilder = Widget Function(
  BuildContext context,
  MkGroupState state,
  MkGroupBloc groupBloc,
);

/// A widget that rebuilds exclusively when a specific [MkGroupBloc] (subform) changes.
///
/// Optimizes performance for large forms with multiple sections:
/// changes or validation in one subform will NOT rebuild sibling subforms
/// or the root form page UI.
class MkSubformBuilder extends StatelessWidget {
  const MkSubformBuilder({
    super.key,
    this.groupBloc,
    this.name,
    this.buildWhen,
    required this.builder,
  }) : assert(
          groupBloc != null || name != null,
          'Either groupBloc or name must be provided to MkSubformBuilder',
        );

  /// The target group bloc.
  final MkGroupBloc? groupBloc;

  /// The name of the group bloc in the nearest [MkFormScope], if [groupBloc] is not passed.
  final String? name;

  /// Optional condition determining whether the builder should be called.
  final bool Function(MkGroupState previous, MkGroupState current)? buildWhen;

  /// The builder function called when the subform state changes.
  final MkSubformWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final bloc = groupBloc ?? (name != null ? context.mkGroup(name!) : null);

    if (bloc == null) {
      throw StateError(
        'MkSubformBuilder could not find an MkGroupBloc for name: "$name". '
        'Ensure the group is registered in the MkFormBloc and wrapped in an MkFormScope.',
      );
    }

    return BlocBuilder<MkGroupBloc, MkGroupState>(
      bloc: bloc,
      buildWhen: buildWhen,
      builder: (context, state) {
        return builder(context, state, bloc);
      },
    );
  }
}
