import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import '../../form_field.dart';
import 'mk_text_field.dart';

/// A specialized [MkTextField] pre-configured for passwords with visibility toggle.
///
/// Accepts the same parameters as [MkTextField] (which mirror [TextField]),
/// except `obscureText` (controlled by the visibility toggle; see
/// [initiallyObscured]) and `maxLines`, `minLines`, `expands`.
/// [keyboardType] defaults to [TextInputType.visiblePassword] and
/// [textInputAction] to [TextInputAction.done].
class MkPasswordField extends MkTextField {
  const MkPasswordField({
    super.key,
    super.fieldBloc,
    super.name,
    InputDecoration? decoration,
    super.keyboardType = TextInputType.visiblePassword,
    super.textInputAction = TextInputAction.done,
    super.textCapitalization = TextCapitalization.none,
    super.style,
    super.strutStyle,
    super.textAlign = TextAlign.start,
    super.textAlignVertical,
    super.textDirection,
    super.readOnly = false,
    super.showCursor,
    super.autofocus = false,
    super.statesController,
    super.obscuringCharacter = '•',
    super.autocorrect,
    super.smartDashesType,
    super.smartQuotesType,
    super.enableSuggestions = true,
    super.maxLength,
    super.maxLengthEnforcement,
    super.onChanged,
    super.onEditingComplete,
    super.onSubmitted,
    super.onAppPrivateCommand,
    super.inputFormatters,
    super.enabled,
    super.ignorePointers,
    super.cursorWidth = 2.0,
    super.cursorHeight,
    super.cursorRadius,
    super.cursorOpacityAnimates,
    super.cursorColor,
    super.cursorErrorColor,
    super.selectionHeightStyle,
    super.selectionWidthStyle,
    super.keyboardAppearance,
    super.scrollPadding = const EdgeInsets.all(20.0),
    super.enableInteractiveSelection,
    super.selectAllOnFocus,
    super.selectionControls,
    super.dragStartBehavior = DragStartBehavior.start,
    super.onTap,
    super.onTapAlwaysCalled = false,
    super.onTapOutside,
    super.onTapUpOutside,
    super.mouseCursor,
    super.buildCounter,
    super.scrollController,
    super.scrollPhysics,
    super.autofillHints = const <String>[],
    super.contentInsertionConfiguration,
    super.clipBehavior = Clip.hardEdge,
    super.restorationId,
    super.stylusHandwritingEnabled =
        EditableText.defaultStylusHandwritingEnabled,
    super.enableIMEPersonalizedLearning = true,
    super.contextMenuBuilder,
    super.canRequestFocus = true,
    super.undoController,
    super.spellCheckConfiguration,
    super.magnifierConfiguration,
    super.hintLocales,
    super.groupId = EditableText,
    super.focusNode,
    this.showPasswordIcon = const Icon(Icons.visibility_outlined),
    this.hidePasswordIcon = const Icon(Icons.visibility_off_outlined),
    this.initiallyObscured = true,
    super.autovalidateMode,
    super.showValidatingIndicator = true,
    super.onSaved,
    super.forceErrorText,
  }) : super(decoration: decoration ?? const InputDecoration());

  /// Icon shown while the password is hidden (tap to reveal).
  final Widget showPasswordIcon;

  /// Icon shown while the password is visible (tap to hide).
  final Widget hidePasswordIcon;

  /// Whether the password starts hidden.
  final bool initiallyObscured;

  @override
  MkFormFieldState<String> createState() => _MkPasswordFieldState();
}

class _MkPasswordFieldState extends MkTextFieldState {
  late bool _obscured = (widget as MkPasswordField).initiallyObscured;

  @override
  bool get obscureText => _obscured;

  @override
  InputDecoration baseDecoration(BuildContext context) {
    final field = widget as MkPasswordField;
    final decoration = field.decoration;
    return decoration.copyWith(
      labelText: decoration.labelText ?? 'Password',
      prefixIcon: decoration.prefixIcon ?? const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        icon: _obscured ? field.showPasswordIcon : field.hidePasswordIcon,
        onPressed: () => setState(() => _obscured = !_obscured),
      ),
    );
  }
}
