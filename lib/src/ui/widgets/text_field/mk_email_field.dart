import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import '../../form_field.dart';
import 'mk_text_field.dart';

/// A specialized [MkTextField] pre-configured for email inputs.
///
/// Accepts the same parameters as [MkTextField] (which mirror [TextField]),
/// except `maxLines`, `minLines` and `expands`, since an email is a single line.
/// The default label, hint and prefix icon are only used when [decoration]
/// leaves them unset. [keyboardType] defaults to [TextInputType.emailAddress]
/// and [textInputAction] to [TextInputAction.next].
class MkEmailField extends MkTextField {
  const MkEmailField({
    super.key,
    super.fieldBloc,
    super.name,
    InputDecoration? decoration,
    super.keyboardType = TextInputType.emailAddress,
    super.textInputAction = TextInputAction.next,
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
    super.obscureText = false,
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
    super.autovalidateMode,
    super.showValidatingIndicator = true,
    super.onSaved,
    super.forceErrorText,
  }) : super(decoration: decoration ?? const InputDecoration());

  @override
  MkFormFieldState<String> createState() => _MkEmailFieldState();
}

class _MkEmailFieldState extends MkTextFieldState {
  @override
  InputDecoration baseDecoration(BuildContext context) {
    final decoration = widget.decoration;
    return decoration.copyWith(
      labelText: decoration.labelText ?? 'Email',
      hintText: decoration.hintText ?? 'example@domain.com',
      prefixIcon: decoration.prefixIcon ?? const Icon(Icons.email_outlined),
    );
  }
}
