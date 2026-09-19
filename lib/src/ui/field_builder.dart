import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/field_bloc.dart';
import 'form_scope.dart';

/// Function signature for building a widget based on [MkFieldState].
typedef MkFieldWidgetBuilder<T> = Widget Function(
  BuildContext context,
  MkFieldState<T> state,
  MkFieldBloc<T> fieldBloc,
);

/// A widget that rebuilds exclusively when the associated [MkFieldBloc] changes.
///
/// Ensures fine-grained performance: typing in one field will NOT rebuild
/// other fields or the root form.
class MkFieldBuilder<T> extends StatelessWidget {
  const MkFieldBuilder({
    super.key,
    this.fieldBloc,
    this.name,
    this.buildWhen,
    required this.builder,
    this.hideWhenInvisible = true,
  }) : assert(
          fieldBloc != null || name != null,
          'Either fieldBloc or name must be provided to MkFieldBuilder',
        );

  /// The target field bloc.
  final MkFieldBloc<T>? fieldBloc;

  /// The name of the field bloc in the nearest [MkFormScope], if [fieldBloc] is not passed.
  final String? name;

  /// Optional condition determining whether the builder should be called.
  final bool Function(MkFieldState<T> previous, MkFieldState<T> current)?
      buildWhen;

  /// The builder function called when the field state changes.
  final MkFieldWidgetBuilder<T> builder;

  /// Whether to automatically return [SizedBox.shrink] when `state.isVisible == false`.
  final bool hideWhenInvisible;

  @override
  Widget build(BuildContext context) {
    final bloc = fieldBloc ?? (name != null ? context.mkField<T>(name!) : null);

    if (bloc == null) {
      throw StateError(
        'MkFieldBuilder could not find an MkFieldBloc<$T> for name: "$name". '
        'Ensure the field is registered in the MkFormBloc and wrapped in an MkFormScope.',
      );
    }

    return BlocBuilder<MkFieldBloc<T>, MkFieldState<T>>(
      bloc: bloc,
      buildWhen: buildWhen,
      builder: (context, state) {
        if (hideWhenInvisible && !state.isVisible) {
          return const SizedBox.shrink();
        }
        return builder(context, state, bloc);
      },
    );
  }
}
