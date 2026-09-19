import 'package:flutter/material.dart';
import '../../../blocs/field_bloc.dart';
import '../../field_builder.dart';
import '../../form_scope.dart';

/// A Material [DropdownButtonFormField] wrapper for [MkFieldBloc<T>].
class MkDropdownField<T> extends StatelessWidget {
  const MkDropdownField({
    super.key,
    this.fieldBloc,
    this.name,
    required this.items,
    this.decoration = const InputDecoration(),
    this.hint,
    this.disabledHint,
    this.onChanged,
    this.autovalidateMode,
  }) : assert(
          fieldBloc != null || name != null,
          'Either fieldBloc or name must be provided',
        );

  final MkFieldBloc<T>? fieldBloc;
  final String? name;
  final List<DropdownMenuItem<T>> items;
  final InputDecoration decoration;
  final Widget? hint;
  final Widget? disabledHint;
  final ValueChanged<T?>? onChanged;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return MkFieldBuilder<T>(
      fieldBloc: fieldBloc,
      name: name,
      builder: (context, state, bloc) {
        final effectiveMode = autovalidateMode ??
            MkFormScope.maybeAutovalidateModeOf(context) ??
            AutovalidateMode.onUserInteraction;
        final isErrorVisible = state.shouldShowError(effectiveMode);

        final effectiveDecoration = decoration.copyWith(
          errorText: isErrorVisible ? state.getLocalizedError(context) : null,
          enabled: state.isEnabled,
        );

        return DropdownButtonFormField<T>(
          initialValue: state.value,
          items: items,
          decoration: effectiveDecoration,
          hint: hint,
          disabledHint: disabledHint,
          onChanged: state.isEnabled
              ? (value) {
                  bloc.touch();
                  bloc.changeValue(value);
                  onChanged?.call(value);
                }
              : null,
        );
      },
    );
  }
}
