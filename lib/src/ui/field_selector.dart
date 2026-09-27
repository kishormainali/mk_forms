import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/field_bloc.dart';
import 'form_scope.dart';

/// Function signature for deriving a selected value [R] from [MkFieldState].
typedef MkFieldStateSelector<T, R> = R Function(MkFieldState<T> state);

/// Function signature for building a widget from a selected value.
typedef MkFieldSelectorWidgetBuilder<T, R> =
    Widget Function(BuildContext context, R selected, MkFieldBloc<T> fieldBloc);

/// A widget that rebuilds only when a value derived from [MkFieldState]
/// actually changes, ignoring every other field-state change.
///
/// Where [MkFieldBuilder] rebuilds on every field-state emission,
/// [MkFieldSelector] is analogous to `flutter_bloc`'s `BlocSelector`: pick
/// out exactly the slice of state a widget cares about (e.g. just `error`)
/// and it will not rebuild when unrelated parts of the state change (e.g.
/// `value` on every keystroke).
///
/// The selected value must be immutable/comparable with `==` for this to
/// accurately detect "did it change".
class MkFieldSelector<T, R> extends StatelessWidget {
  const MkFieldSelector({
    super.key,
    this.fieldBloc,
    this.name,
    required this.selector,
    required this.builder,
    this.hideWhenInvisible = true,
  }) : assert(
         fieldBloc != null || name != null,
         'Either fieldBloc or name must be provided to MkFieldSelector',
       );

  /// The target field bloc.
  final MkFieldBloc<T>? fieldBloc;

  /// The name of the field bloc in the nearest [MkFormScope], if [fieldBloc] is not passed.
  final String? name;

  /// Derives the value this widget rebuilds on.
  final MkFieldStateSelector<T, R> selector;

  /// The builder function called with the selected value.
  final MkFieldSelectorWidgetBuilder<T, R> builder;

  /// Whether to automatically return [SizedBox.shrink] when `state.isVisible == false`.
  final bool hideWhenInvisible;

  @override
  Widget build(BuildContext context) {
    final bloc = fieldBloc ?? (name != null ? context.mkField<T>(name!) : null);

    if (bloc == null) {
      throw StateError(
        'MkFieldSelector could not find an MkFieldBloc<$T> for name: "$name". '
        'Ensure the field is registered in the MkFormBloc and wrapped in an MkFormScope.',
      );
    }

    return BlocSelector<MkFieldBloc<T>, MkFieldState<T>, (R, bool)>(
      bloc: bloc,
      selector: (state) =>
          (selector(state), hideWhenInvisible ? state.isVisible : true),
      builder: (context, selected) {
        final (value, visible) = selected;
        if (!visible) {
          return const SizedBox.shrink();
        }
        return builder(context, value, bloc);
      },
    );
  }
}
