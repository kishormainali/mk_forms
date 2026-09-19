import 'package:flutter/material.dart';
import '../../../blocs/field_bloc.dart';
import '../../field_builder.dart';
import '../../form_scope.dart';

/// A Material [CheckboxListTile] wrapper for [MkFieldBloc<bool>].
class MkCheckboxField extends StatelessWidget {
  const MkCheckboxField({
    super.key,
    this.fieldBloc,
    this.name,
    required this.title,
    this.subtitle,
    this.secondary,
    this.activeColor,
    this.checkColor,
    this.contentPadding,
    this.dense,
    this.autovalidateMode,
  }) : assert(
          fieldBloc != null || name != null,
          'Either fieldBloc or name must be provided',
        );

  final MkFieldBloc<bool>? fieldBloc;
  final String? name;
  final Widget title;
  final Widget? subtitle;
  final Widget? secondary;
  final Color? activeColor;
  final Color? checkColor;
  final EdgeInsetsGeometry? contentPadding;
  final bool? dense;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MkFieldBuilder<bool>(
      fieldBloc: fieldBloc,
      name: name,
      builder: (context, state, bloc) {
        final effectiveMode = autovalidateMode ??
            MkFormScope.maybeAutovalidateModeOf(context) ??
            AutovalidateMode.onUserInteraction;
        final isErrorVisible = state.shouldShowError(effectiveMode);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              value: state.value ?? false,
              onChanged: state.isEnabled
                  ? (value) {
                      bloc.touch();
                      bloc.changeValue(value);
                    }
                  : null,
              title: title,
              subtitle: subtitle,
              secondary: secondary,
              activeColor: activeColor,
              checkColor: checkColor,
              contentPadding: contentPadding,
              dense: dense,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (isErrorVisible && state.error != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text(
                  state.getLocalizedError(context) ?? state.error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
