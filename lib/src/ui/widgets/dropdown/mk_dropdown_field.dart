import 'package:flutter/material.dart';
import '../../../blocs/field_bloc.dart';
import '../../field_builder.dart';
import '../../form_scope.dart';

/// A Material [DropdownButtonFormField] wrapper for [MkFieldBloc<T>].
///
/// Every [DropdownButtonFormField] parameter is available here and forwarded
/// as-is, except the [FormField] ones (`validator`, `onSaved`, `errorBuilder`,
/// `forceErrorText`), which are replaced by the bloc's own validation, and:
/// - `initialValue`: the current value always comes from the bloc.
/// - `onChanged`: called *after* the bloc has been updated.
/// - `decoration`: the error text is added to it.
class MkDropdownField<T> extends StatelessWidget {
  const MkDropdownField({
    super.key,
    this.fieldBloc,
    this.name,
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
    this.enabled,
    this.autovalidateMode,
  }) : assert(
          fieldBloc != null || name != null,
          'Either fieldBloc or name must be provided',
        );

  /// The field bloc to bind to. If null, [name] is looked up in the nearest [MkFormScope].
  final MkFieldBloc<T>? fieldBloc;

  /// Name of the field in the nearest [MkFormScope], used when [fieldBloc] is null.
  final String? name;

  /// Overrides the [AutovalidateMode] of the enclosing [MkFormScope].
  final AutovalidateMode? autovalidateMode;

  /// Set to `false` to disable the dropdown regardless of the bloc.
  final bool? enabled;

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
  Widget build(BuildContext context) {
    return MkFieldBuilder<T>(
      fieldBloc: fieldBloc,
      name: name,
      builder: (context, state, bloc) {
        final effectiveMode = autovalidateMode ??
            MkFormScope.maybeAutovalidateModeOf(context) ??
            AutovalidateMode.onUserInteraction;
        final isErrorVisible = state.shouldShowError(effectiveMode);
        final isEnabled = state.isEnabled && (enabled ?? true);

        final effectiveDecoration = decoration.copyWith(
          errorText: isErrorVisible ? state.getLocalizedError(context) : null,
          enabled: isEnabled,
        );

        return DropdownButtonFormField<T>(
          initialValue: state.value,
          items: items,
          selectedItemBuilder: selectedItemBuilder,
          decoration: effectiveDecoration,
          hint: hint,
          disabledHint: disabledHint,
          onChanged: isEnabled
              ? (value) {
                  bloc.changeValue(value, markTouched: true);
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
        );
      },
    );
  }
}
