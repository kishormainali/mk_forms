import 'package:flutter/material.dart';
import '../../form_field.dart';
import 'mk_radio_option.dart';

export 'mk_radio_option.dart';

/// A reactive radio group bound to an [MkFieldBloc<T>].
///
/// The vertical layout renders [RadioListTile]s; the horizontal and wrap
/// layouts render a [Radio] next to the option label. The parameters below
/// mirror those widgets and are applied to every option:
/// - Shared by both: [mouseCursor], [toggleable], [activeColor], [fillColor],
///   [hoverColor], [overlayColor], [splashRadius], [materialTapTargetSize],
///   [visualDensity], [autofocus] (first option), [radioBackgroundColor],
///   [radioSide], [radioInnerRadius].
/// - [RadioListTile] only (vertical layout): [contentPadding], [dense],
///   [isThreeLine], [controlAffinity], [shape], [tileColor],
///   [selectedTileColor], [onFocusChange], [enableFeedback],
///   [horizontalTitleGap], [minVerticalPadding], [minLeadingWidth],
///   [minTileHeight], [radioScaleFactor], [titleAlignment].
/// - [Radio] only (horizontal/wrap layouts): [focusColor].
///
/// Options can also be fully custom via [itemBuilder].
class MkRadioGroup<T> extends MkFormField<T> {
  const MkRadioGroup({
    super.key,
    super.fieldBloc,
    super.name,
    required this.options,
    this.layout = MkRadioLayout.vertical,
    this.title,
    this.onChanged,
    super.enabled,
    this.mouseCursor,
    this.toggleable = false,
    this.activeColor,
    this.fillColor,
    this.focusColor,
    this.hoverColor,
    this.overlayColor,
    this.splashRadius,
    this.materialTapTargetSize,
    this.visualDensity,
    this.autofocus = false,
    this.radioBackgroundColor,
    this.radioSide,
    this.radioInnerRadius,
    this.contentPadding,
    this.dense = true,
    this.isThreeLine,
    this.controlAffinity,
    this.shape,
    this.tileColor,
    this.selectedTileColor,
    this.highlightSelected = false,
    this.onFocusChange,
    this.enableFeedback,
    this.horizontalTitleGap,
    this.minVerticalPadding,
    this.minLeadingWidth,
    this.minTileHeight,
    this.radioScaleFactor = 1.0,
    this.titleAlignment,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.errorStyle,
    this.errorPadding = const EdgeInsets.only(left: 16, top: 4),
    this.itemBuilder,
    super.autovalidateMode,
    super.onSaved,
    super.forceErrorText,
  });

  /// The selectable options.
  final List<MkRadioOption<T>> options;

  /// How the options are laid out.
  final MkRadioLayout layout;

  /// Optional widget shown above the options.
  final Widget? title;

  /// Called with the new value after the bloc has been updated.
  final ValueChanged<T?>? onChanged;

  /// See [RadioListTile.mouseCursor] / [Radio.mouseCursor].
  final MouseCursor? mouseCursor;

  /// See [Radio.toggleable]. When true, tapping the selected option clears the value.
  final bool toggleable;

  /// See [RadioListTile.activeColor] / [Radio.activeColor].
  final Color? activeColor;

  /// See [RadioListTile.fillColor] / [Radio.fillColor].
  final WidgetStateProperty<Color?>? fillColor;

  /// See [Radio.focusColor]. Horizontal and wrap layouts only.
  final Color? focusColor;

  /// See [RadioListTile.hoverColor] / [Radio.hoverColor].
  final Color? hoverColor;

  /// See [RadioListTile.overlayColor] / [Radio.overlayColor].
  final WidgetStateProperty<Color?>? overlayColor;

  /// See [RadioListTile.splashRadius] / [Radio.splashRadius].
  final double? splashRadius;

  /// See [RadioListTile.materialTapTargetSize] / [Radio.materialTapTargetSize].
  final MaterialTapTargetSize? materialTapTargetSize;

  /// See [RadioListTile.visualDensity] / [Radio.visualDensity].
  final VisualDensity? visualDensity;

  /// Autofocuses the first enabled option.
  final bool autofocus;

  /// See [RadioListTile.radioBackgroundColor] / [Radio.backgroundColor].
  final WidgetStateProperty<Color?>? radioBackgroundColor;

  /// See [RadioListTile.radioSide] / [Radio.side].
  final BorderSide? radioSide;

  /// See [RadioListTile.radioInnerRadius] / [Radio.innerRadius].
  final WidgetStateProperty<double?>? radioInnerRadius;

  /// See [RadioListTile.contentPadding]. Vertical layout only.
  final EdgeInsetsGeometry? contentPadding;

  /// See [RadioListTile.dense]. Defaults to true. Vertical layout only.
  final bool? dense;

  /// See [RadioListTile.isThreeLine]. Vertical layout only; only applied to
  /// options that have a subtitle.
  final bool? isThreeLine;

  /// See [RadioListTile.controlAffinity]. Vertical layout only.
  final ListTileControlAffinity? controlAffinity;

  /// See [RadioListTile.shape]. Vertical layout only.
  final ShapeBorder? shape;

  /// See [RadioListTile.tileColor]. Vertical layout only.
  final Color? tileColor;

  /// See [RadioListTile.selectedTileColor]. Vertical layout only.
  final Color? selectedTileColor;

  /// Whether the selected tile is drawn in its "selected" style
  /// ([RadioListTile.selected]; uses [selectedTileColor]). Vertical layout only.
  final bool highlightSelected;

  /// See [RadioListTile.onFocusChange]. Vertical layout only.
  final ValueChanged<bool>? onFocusChange;

  /// See [RadioListTile.enableFeedback]. Vertical layout only.
  final bool? enableFeedback;

  /// See [RadioListTile.horizontalTitleGap]. Vertical layout only.
  final double? horizontalTitleGap;

  /// See [RadioListTile.minVerticalPadding]. Vertical layout only.
  final double? minVerticalPadding;

  /// See [RadioListTile.minLeadingWidth]. Vertical layout only.
  final double? minLeadingWidth;

  /// See [RadioListTile.minTileHeight]. Vertical layout only.
  final double? minTileHeight;

  /// See [RadioListTile.radioScaleFactor]. Vertical layout only.
  final double radioScaleFactor;

  /// See [RadioListTile.titleAlignment]. Vertical layout only.
  final ListTileTitleAlignment? titleAlignment;

  /// Horizontal gap between options in the horizontal and wrap layouts.
  final double spacing;

  /// Vertical gap between rows in the wrap layout.
  final double runSpacing;

  /// Style of the validation error shown below the group.
  /// Defaults to `bodySmall` in the theme's error color.
  final TextStyle? errorStyle;

  /// Padding around the validation error shown below the group.
  final EdgeInsetsGeometry errorPadding;

  /// Optional custom builder for full design system flexibility
  /// (e.g. selectable card designs, pill buttons, etc.).
  final Widget Function(
    BuildContext context,
    MkRadioOption<T> option,
    bool isSelected,
    VoidCallback onSelect,
  )?
  itemBuilder;

  @override
  Widget buildContent(BuildContext context, MkFormFieldState<T> field) {
    final theme = Theme.of(context);
    final state = field.fieldState;
    final errorText = field.errorText;
    {
      {
        final isGroupEnabled = field.isFieldEnabled;

        void select(T? value) {
          if (!isGroupEnabled) return;
          field.userChange(value, markTouched: true);
          onChanged?.call(value);
        }

        Widget content;

        if (itemBuilder != null) {
          final items = options.map((option) {
            final isSelected = state.value == option.value;
            return itemBuilder!(context, option, isSelected, () {
              if (option.enabled) select(option.value);
            });
          }).toList();

          content = switch (layout) {
            MkRadioLayout.vertical => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: items,
            ),
            MkRadioLayout.horizontal => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(mainAxisSize: MainAxisSize.min, children: items),
            ),
            MkRadioLayout.wrap => Wrap(
              spacing: spacing,
              runSpacing: runSpacing,
              children: items,
            ),
          };
        } else {
          // Only the first enabled option may autofocus.
          final autofocusIndex = autofocus
              ? options.indexWhere((o) => o.enabled)
              : -1;

          Widget tile(int index, MkRadioOption<T> option) {
            return RadioListTile<T>(
              value: option.value,
              title: option.label,
              subtitle: option.subtitle,
              secondary: option.secondary,
              enabled: isGroupEnabled && option.enabled,
              selected: highlightSelected && state.value == option.value,
              mouseCursor: mouseCursor,
              toggleable: toggleable,
              activeColor: activeColor,
              fillColor: fillColor,
              hoverColor: hoverColor,
              overlayColor: overlayColor,
              splashRadius: splashRadius,
              materialTapTargetSize: materialTapTargetSize,
              visualDensity: visualDensity,
              autofocus: index == autofocusIndex,
              radioBackgroundColor: radioBackgroundColor,
              radioSide: radioSide,
              radioInnerRadius: radioInnerRadius,
              contentPadding: contentPadding,
              dense: dense,
              // Flutter asserts a subtitle exists for three-line tiles.
              isThreeLine: option.subtitle != null ? isThreeLine : null,
              controlAffinity: controlAffinity,
              shape: shape,
              tileColor: tileColor,
              selectedTileColor: selectedTileColor,
              onFocusChange: onFocusChange,
              enableFeedback: enableFeedback,
              horizontalTitleGap: horizontalTitleGap,
              minVerticalPadding: minVerticalPadding,
              minLeadingWidth: minLeadingWidth,
              minTileHeight: minTileHeight,
              radioScaleFactor: radioScaleFactor,
              titleAlignment: titleAlignment,
            );
          }

          Widget radioWithLabel(int index, MkRadioOption<T> option) {
            final optionEnabled = isGroupEnabled && option.enabled;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<T>(
                  value: option.value,
                  enabled: optionEnabled,
                  mouseCursor: mouseCursor,
                  toggleable: toggleable,
                  activeColor: activeColor,
                  fillColor: fillColor,
                  focusColor: focusColor,
                  hoverColor: hoverColor,
                  overlayColor: overlayColor,
                  splashRadius: splashRadius,
                  materialTapTargetSize: materialTapTargetSize,
                  visualDensity: visualDensity,
                  autofocus: index == autofocusIndex,
                  backgroundColor: radioBackgroundColor,
                  side: radioSide,
                  innerRadius: radioInnerRadius,
                ),
                InkWell(
                  onTap: optionEnabled ? () => select(option.value) : null,
                  child: option.label,
                ),
              ],
            );
          }

          final Widget inner;
          switch (layout) {
            case MkRadioLayout.vertical:
              inner = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < options.length; i++) tile(i, options[i]),
                ],
              );
            case MkRadioLayout.horizontal:
              inner = SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < options.length; i++)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                        child: radioWithLabel(i, options[i]),
                      ),
                  ],
                ),
              );
            case MkRadioLayout.wrap:
              inner = Wrap(
                spacing: spacing,
                runSpacing: runSpacing,
                children: [
                  for (var i = 0; i < options.length; i++)
                    radioWithLabel(i, options[i]),
                ],
              );
          }

          content = RadioGroup<T>(
            groupValue: state.value,
            onChanged: select,
            child: inner,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[title!, const SizedBox(height: 4)],
            content,
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
  }
}
