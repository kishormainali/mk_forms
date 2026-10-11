import 'package:flutter/material.dart';
import '../../form_field.dart';
import '../hint_visibility.dart';

/// A Material dropdown ([DropdownButton] in an [InputDecorator], the same
/// structure as [DropdownButtonFormField]) bound to an [MkFieldBloc<T>].
///
/// Every [DropdownButtonFormField] parameter is available here and forwarded
/// as-is, except the [FormField] ones (`validator`, `onSaved`, `errorBuilder`,
/// `forceErrorText`), which are replaced by the bloc's own validation, and:
/// - `initialValue`: the current value always comes from the bloc.
/// - `onChanged`: called *after* the bloc has been updated.
/// - `decoration`: the error text is added to it.
class MkDropdownField<T> extends MkFormField<T> {
  const MkDropdownField({
    super.key,
    super.fieldBloc,
    super.name,
    required this.items,
    this.selectedItemBuilder,
    this.decoration = const InputDecoration(),
    this.hint,
    this.disabledHint,
    this.onChanged,
    this.onTap,
    this.elevation = 8,
    this.style,
    this.icon,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.iconSize = 24.0,
    this.isDense = true,
    this.isExpanded = false,
    this.itemHeight,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
    this.dropdownColor,
    this.menuMaxHeight,
    this.enableFeedback,
    this.alignment = AlignmentDirectional.centerStart,
    this.borderRadius,
    this.padding,
    this.barrierDismissible = true,
    this.mouseCursor,
    this.dropdownMenuItemMouseCursor,
    super.enabled,
    super.autovalidateMode,
    super.onSaved,
    super.forceErrorText,
  });

  /// See [DropdownButtonFormField.items].
  final List<DropdownMenuItem<T>> items;

  /// See [DropdownButtonFormField.selectedItemBuilder].
  final DropdownButtonBuilder? selectedItemBuilder;

  /// See [DropdownButtonFormField.decoration]. `errorText` is filled in from the bloc.
  final InputDecoration decoration;

  /// See [DropdownButtonFormField.hint].
  final Widget? hint;

  /// See [DropdownButtonFormField.disabledHint].
  final Widget? disabledHint;

  /// Called with the new value after the bloc has been updated.
  final ValueChanged<T?>? onChanged;

  /// See [DropdownButtonFormField.onTap].
  final VoidCallback? onTap;

  /// See [DropdownButtonFormField.elevation].
  final int elevation;

  /// See [DropdownButtonFormField.style].
  final TextStyle? style;

  /// See [DropdownButtonFormField.icon].
  final Widget? icon;

  /// See [DropdownButtonFormField.iconDisabledColor].
  final Color? iconDisabledColor;

  /// See [DropdownButtonFormField.iconEnabledColor].
  final Color? iconEnabledColor;

  /// See [DropdownButtonFormField.iconSize].
  final double iconSize;

  /// See [DropdownButtonFormField.isDense].
  final bool isDense;

  /// See [DropdownButtonFormField.isExpanded].
  final bool isExpanded;

  /// See [DropdownButtonFormField.itemHeight].
  final double? itemHeight;

  /// See [DropdownButtonFormField.focusColor].
  final Color? focusColor;

  /// See [DropdownButtonFormField.focusNode].
  final FocusNode? focusNode;

  /// See [DropdownButtonFormField.autofocus].
  final bool autofocus;

  /// See [DropdownButtonFormField.dropdownColor].
  final Color? dropdownColor;

  /// See [DropdownButtonFormField.menuMaxHeight].
  final double? menuMaxHeight;

  /// See [DropdownButtonFormField.enableFeedback].
  final bool? enableFeedback;

  /// See [DropdownButtonFormField.alignment].
  final AlignmentGeometry alignment;

  /// See [DropdownButtonFormField.borderRadius].
  final BorderRadius? borderRadius;

  /// See [DropdownButtonFormField.padding].
  final EdgeInsetsGeometry? padding;

  /// See [DropdownButtonFormField.barrierDismissible].
  final bool barrierDismissible;

  /// See [DropdownButtonFormField.mouseCursor].
  final MouseCursor? mouseCursor;

  /// See [DropdownButtonFormField.dropdownMenuItemMouseCursor].
  final MouseCursor? dropdownMenuItemMouseCursor;

  @override
  Widget buildContent(BuildContext context, MkFormFieldState<T> field) {
    final state = field.fieldState;
    final isEnabled = field.isFieldEnabled;
    final effectiveDecoration = decoration.copyWith(
      errorText: field.errorText,
      enabled: isEnabled,
    );

    // Same structure as DropdownButtonFormField, built directly so the only
    // FormField in the tree is this one.
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          // Like a TextField, keep the hint hidden while the label sits in
          // the field (otherwise the two overlap).
          final showHint = mkShouldShowHint(
            effectiveDecoration,
            isFocused: isFocused,
          );
          return InputDecorator(
            decoration: effectiveDecoration,
            isEmpty: state.value == null,
            isFocused: isFocused,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: state.value,
                items: items,
                selectedItemBuilder: selectedItemBuilder,
                // Like a TextField, keep the hint hidden while the label sits in
                // the field (otherwise the two overlap).
                hint: hint == null || showHint
                    ? hint
                    : mkHintSlot(visible: false, child: hint!),
                disabledHint: disabledHint,
                onChanged: isEnabled
                    ? (value) {
                        field.userChange(value, markTouched: true);
                        onChanged?.call(value);
                      }
                    : null,
                onTap: onTap,
                elevation: elevation,
                style: style,
                icon: icon,
                iconDisabledColor: iconDisabledColor,
                iconEnabledColor: iconEnabledColor,
                iconSize: iconSize,
                isDense: isDense,
                isExpanded: isExpanded,
                itemHeight: itemHeight,
                focusColor: focusColor,
                focusNode: focusNode,
                autofocus: autofocus,
                dropdownColor: dropdownColor,
                menuMaxHeight: menuMaxHeight,
                enableFeedback: enableFeedback,
                alignment: alignment,
                borderRadius: borderRadius,
                padding: padding,
                barrierDismissible: barrierDismissible,
                mouseCursor: mouseCursor,
                dropdownMenuItemMouseCursor: dropdownMenuItemMouseCursor,
              ),
            ),
          );
        },
      ),
    );
  }
}
