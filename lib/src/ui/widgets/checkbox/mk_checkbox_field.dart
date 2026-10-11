import 'package:flutter/material.dart';
import '../../form_field.dart';

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
class MkCheckboxField extends MkFormField<bool> {
  const MkCheckboxField({
    super.key,
    super.fieldBloc,
    super.name,
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
    super.enabled,
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
    super.autovalidateMode,
    super.onSaved,
    super.forceErrorText,
  });

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
  Widget buildContent(BuildContext context, MkFormFieldState<bool> field) {
    final theme = Theme.of(context);
    final state = field.fieldState;
    final errorText = field.errorText;
    final isEnabled = field.isFieldEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckboxListTile(
          value: tristate ? state.value : (state.value ?? false),
          onChanged: isEnabled
              ? (value) {
                  field.userChange(value, markTouched: true);
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
          isError: isError ?? (errorText != null),
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
        if (errorText != null)
          Padding(
            padding: errorPadding,
            child: Text(
              errorText,
              style:
                  errorStyle ??
                  theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
            ),
          ),
      ],
    );
  }
}
