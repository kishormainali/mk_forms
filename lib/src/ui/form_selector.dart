import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/form_bloc.dart';
import 'form_scope.dart';

/// Function signature for deriving a selected value [R] from [MkFormState].
typedef MkFormStateSelector<R> = R Function(MkFormState state);

/// Function signature for building a widget from a selected value.
typedef MkFormSelectorWidgetBuilder<R> =
    Widget Function(BuildContext context, R selected, MkFormBloc formBloc);

/// A widget that rebuilds only when a value derived from [MkFormState]
/// actually changes.
///
/// [MkFormState.values] changes on every keystroke, so an [MkFormBuilder]
/// without a `buildWhen` rebuilds on every keystroke. When a widget only needs
/// one flag, select just that — analogous to `flutter_bloc`'s `BlocSelector`:
///
/// ```dart
/// MkFormSelector<bool>(
///   selector: (s) => s.canSubmit,
///   builder: (context, canSubmit, form) => FilledButton(
///     onPressed: canSubmit ? form.submit : null,
///     child: const Text('Save'),
///   ),
/// )
/// ```
///
/// The selected value must be immutable/comparable with `==`; use a record to
/// select several values at once, e.g. `(s.isValid, s.isSubmitting)`.
class MkFormSelector<R> extends StatelessWidget {
  const MkFormSelector({
    super.key,
    this.formBloc,
    required this.selector,
    required this.builder,
  });

  /// The form bloc to select from. If null, it is looked up via [MkFormScope].
  final MkFormBloc? formBloc;

  /// Derives the value this widget rebuilds on.
  final MkFormStateSelector<R> selector;

  /// The builder function called with the selected value.
  final MkFormSelectorWidgetBuilder<R> builder;

  @override
  Widget build(BuildContext context) {
    final bloc = formBloc ?? MkFormScope.of(context);
    return BlocSelector<MkFormBloc, MkFormState, R>(
      bloc: bloc,
      selector: selector,
      builder: (context, selected) => builder(context, selected, bloc),
    );
  }
}
