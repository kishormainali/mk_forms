import 'package:flutter/material.dart';
import '../../../blocs/field_bloc.dart';
import '../../field_builder.dart';
import '../../form_scope.dart';

/// A Material [CheckboxListTile] wrapper for [MkFieldBloc<bool>].
///
/// Every [CheckboxListTile] parameter is available here and forwarded as-is,
/// except:
/// - `value` and `onChanged`: driven by the bloc. [onChanged] is called
///   *after* the bloc has been updated.
/// - `enabled`: combined with the bloc's enabled state (both must allow input).
/// - `isError`: defaults to whether a validation error is currently shown.
/// - `statesController`: not supported (requires a newer Flutter than this
///   package targets).
class MkCheckboxField extends StatelessWidget {
  const MkCheckboxField({
    super.key,
    this.fieldBloc,
    this.name,
    required this.title,
    this.subtitle,
    this.secondary,
    this.onChanged,
    this.mouseCursor,
    this.activeColor,
    this.fillColor,
    this.checkColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.visualDensity,
    this.focusNode,
    this.autofocus = false,
    this.shape,
    this.side,
    this.isError,
    this.enabled,
    this.tileColor,
    this.isThreeLine,
    this.dense,
    this.selected = false,
    this.controlAffinity = ListTileControlAffinity.leading,
    this.contentPadding,
    this.tristate = false,
    this.checkboxShape,
    this.selectedTileColor,
    this.onFocusChange,
    this.enableFeedback,
    this.horizontalTitleGap,
    this.minVerticalPadding,
    this.minLeadingWidth,
    this.minTileHeight,
    this.checkboxSemanticLabel,
    this.checkboxScaleFactor = 1.0,
    this.titleAlignment,
    this.errorStyle,
    this.errorPadding = const EdgeInsets.only(left: 16, top: 2),
    this.autovalidateMode,
  }) : assert(
         fieldBloc != null || name != null,
         'Either fieldBloc or name must be provided',
       );

  /// The field bloc to bind to. If null, [name] is looked up in the nearest [MkFormScope].
  final MkFieldBloc<bool>? fieldBloc;

  /// Name of the field in the nearest [MkFormScope], used when [fieldBloc] is null.
  final String? name;

  /// Overrides the [AutovalidateMode] of the enclosing [MkFormScope].
  final AutovalidateMode? autovalidateMode;

  /// Style of the validation error shown below the tile.
  /// Defaults to `bodySmall` in the theme's error color.
  final TextStyle? errorStyle;

  /// Padding around the validation error shown below the tile.
  final EdgeInsetsGeometry errorPadding;

  /// Called with the new value after the bloc has been updated.
  final ValueChanged<bool?>? onChanged;

  /// See [CheckboxListTile.title].
  final Widget title;

  /// See [CheckboxListTile.subtitle].
  final Widget? subtitle;

  /// See [CheckboxListTile.secondary].
  final Widget? secondary;

  /// See [CheckboxListTile.mouseCursor].
  final MouseCursor? mouseCursor;

  /// See [CheckboxListTile.activeColor].
  final Color? activeColor;

  /// See [CheckboxListTile.fillColor].
  final WidgetStateProperty<Color?>? fillColor;

  /// See [CheckboxListTile.checkColor].
  final Color? checkColor;

  /// See [CheckboxListTile.hoverColor].
  final Color? hoverColor;

  /// See [CheckboxListTile.overlayColor].
  final WidgetStateProperty<Color?>? overlayColor;

  /// See [CheckboxListTile.splashRadius].
  final double? splashRadius;

  /// See [CheckboxListTile.materialTapTargetSize].
  final MaterialTapTargetSize? materialTapTargetSize;

  /// See [CheckboxListTile.visualDensity].
  final VisualDensity? visualDensity;

  /// See [CheckboxListTile.focusNode].
  final FocusNode? focusNode;

  /// See [CheckboxListTile.autofocus].
  final bool autofocus;

  /// See [CheckboxListTile.shape].
  final ShapeBorder? shape;

  /// See [CheckboxListTile.side].
  final BorderSide? side;

  /// See [CheckboxListTile.isError]. When null, true while an error is shown.
  final bool? isError;

  /// Set to `false` to disable the tile regardless of the bloc.
  final bool? enabled;

  /// See [CheckboxListTile.tileColor].
  final Color? tileColor;

  /// See [CheckboxListTile.isThreeLine].
  final bool? isThreeLine;

  /// See [CheckboxListTile.dense].
  final bool? dense;

  /// See [CheckboxListTile.selected].
  final bool selected;

  /// See [CheckboxListTile.controlAffinity]. Defaults to leading.
  final ListTileControlAffinity? controlAffinity;

  /// See [CheckboxListTile.contentPadding].
  final EdgeInsetsGeometry? contentPadding;

  /// See [CheckboxListTile.tristate]. When true a `null` value is shown as the
  /// indeterminate state instead of unchecked.
  final bool tristate;

  /// See [CheckboxListTile.checkboxShape].
  final OutlinedBorder? checkboxShape;

  /// See [CheckboxListTile.selectedTileColor].
  final Color? selectedTileColor;

  /// See [CheckboxListTile.onFocusChange].
  final ValueChanged<bool>? onFocusChange;

  /// See [CheckboxListTile.enableFeedback].
  final bool? enableFeedback;

  /// See [CheckboxListTile.horizontalTitleGap].
  final double? horizontalTitleGap;

  /// See [CheckboxListTile.minVerticalPadding].
  final double? minVerticalPadding;

  /// See [CheckboxListTile.minLeadingWidth].
  final double? minLeadingWidth;

  /// See [CheckboxListTile.minTileHeight].
  final double? minTileHeight;

  /// See [CheckboxListTile.checkboxSemanticLabel].
  final String? checkboxSemanticLabel;

  /// See [CheckboxListTile.checkboxScaleFactor].
  final double checkboxScaleFactor;

  /// See [CheckboxListTile.titleAlignment].
  final ListTileTitleAlignment? titleAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MkFieldBuilder<bool>(
      fieldBloc: fieldBloc,
      name: name,
      builder: (context, state, bloc) {
        final effectiveMode =
            autovalidateMode ??
            MkFormScope.maybeAutovalidateModeOf(context) ??
            AutovalidateMode.onUserInteraction;
        final isErrorVisible =
            state.shouldShowError(effectiveMode) && state.error != null;
        final isEnabled = state.isEnabled && (enabled ?? true);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              value: tristate ? state.value : (state.value ?? false),
              onChanged: isEnabled
                  ? (value) {
                      bloc.changeValue(value, markTouched: true);
                      onChanged?.call(value);
                    }
                  : null,
              title: title,
              subtitle: subtitle,
              secondary: secondary,
              mouseCursor: mouseCursor,
              activeColor: activeColor,
              fillColor: fillColor,
              checkColor: checkColor,
              hoverColor: hoverColor,
              overlayColor: overlayColor,
              splashRadius: splashRadius,
              materialTapTargetSize: materialTapTargetSize,
              visualDensity: visualDensity,
              focusNode: focusNode,
              autofocus: autofocus,
              shape: shape,
              side: side,
              isError: isError ?? isErrorVisible,
              enabled: isEnabled,
              tileColor: tileColor,
              isThreeLine: isThreeLine,
              dense: dense,
              selected: selected,
              controlAffinity: controlAffinity,
              contentPadding: contentPadding,
              tristate: tristate,
              checkboxShape: checkboxShape,
              selectedTileColor: selectedTileColor,
              onFocusChange: onFocusChange,
              enableFeedback: enableFeedback,
              horizontalTitleGap: horizontalTitleGap,
              minVerticalPadding: minVerticalPadding,
              minLeadingWidth: minLeadingWidth,
              minTileHeight: minTileHeight,
              checkboxSemanticLabel: checkboxSemanticLabel,
              checkboxScaleFactor: checkboxScaleFactor,
              titleAlignment: titleAlignment,
            ),
            if (isErrorVisible)
              Padding(
                padding: errorPadding,
                child: Text(
                  state.getLocalizedError(context) ?? state.error!,
                  style:
                      errorStyle ??
                      theme.textTheme.bodySmall?.copyWith(
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
