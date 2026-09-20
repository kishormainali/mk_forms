import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../blocs/field_bloc.dart';
import 'mk_text_field.dart';

/// A specialized [MkTextField] pre-configured for passwords with visibility toggle.
///
/// Accepts the same parameters as [MkTextField] (which mirror [TextField]),
/// except `obscureText` (controlled by the visibility toggle; see
/// [initiallyObscured]) and `maxLines`, `minLines`, `expands`.
/// [keyboardType] defaults to [TextInputType.visiblePassword] and
/// [textInputAction] to [TextInputAction.done].
class MkPasswordField extends StatefulWidget {
  const MkPasswordField({
    super.key,
    this.fieldBloc,
    this.name,
    this.decoration,
    this.keyboardType = TextInputType.visiblePassword,
    this.textInputAction = TextInputAction.done,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.textDirection,
    this.readOnly = false,
    this.showCursor,
    this.autofocus = false,
    this.statesController,
    this.obscuringCharacter = '•',
    this.autocorrect,
    this.smartDashesType,
    this.smartQuotesType,
    this.enableSuggestions = true,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onAppPrivateCommand,
    this.inputFormatters,
    this.enabled,
    this.ignorePointers,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorOpacityAnimates,
    this.cursorColor,
    this.cursorErrorColor,
    this.selectionHeightStyle,
    this.selectionWidthStyle,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enableInteractiveSelection,
    this.selectAllOnFocus,
    this.selectionControls,
    this.dragStartBehavior = DragStartBehavior.start,
    this.onTap,
    this.onTapAlwaysCalled = false,
    this.onTapOutside,
    this.onTapUpOutside,
    this.mouseCursor,
    this.buildCounter,
    this.scrollController,
    this.scrollPhysics,
    this.autofillHints = const <String>[],
    this.contentInsertionConfiguration,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.stylusHandwritingEnabled =
        EditableText.defaultStylusHandwritingEnabled,
    this.enableIMEPersonalizedLearning = true,
    this.contextMenuBuilder,
    this.canRequestFocus = true,
    this.undoController,
    this.spellCheckConfiguration,
    this.magnifierConfiguration,
    this.hintLocales,
    this.groupId = EditableText,
    this.focusNode,
    this.showPasswordIcon = const Icon(Icons.visibility_outlined),
    this.hidePasswordIcon = const Icon(Icons.visibility_off_outlined),
    this.initiallyObscured = true,
    this.autovalidateMode,
    this.showValidatingIndicator = true,
  }) : assert(
          fieldBloc != null || name != null,
          'Either fieldBloc or name must be provided',
        );

  /// The field bloc to bind to. If null, [name] is looked up in the nearest [MkFormScope].
  final MkFieldBloc<String>? fieldBloc;

  /// Name of the field in the nearest [MkFormScope], used when [fieldBloc] is null.
  final String? name;

  /// Overrides the [AutovalidateMode] of the enclosing [MkFormScope].
  final AutovalidateMode? autovalidateMode;

  /// Whether to replace the suffix icon with a spinner while validating asynchronously.
  final bool showValidatingIndicator;

  /// Base decoration. Unset label and prefix icon fall back to password defaults;
  /// the visibility toggle is always the suffix icon.
  final InputDecoration? decoration;

  /// Icon shown while the password is hidden (tap to reveal).
  final Widget showPasswordIcon;

  /// Icon shown while the password is visible (tap to hide).
  final Widget hidePasswordIcon;

  /// Whether the password starts hidden.
  final bool initiallyObscured;

  /// See [TextField.keyboardType].
  final TextInputType? keyboardType;

  /// See [TextField.textInputAction].
  final TextInputAction? textInputAction;

  /// See [TextField.textCapitalization].
  final TextCapitalization textCapitalization;

  /// See [TextField.style].
  final TextStyle? style;

  /// See [TextField.strutStyle].
  final StrutStyle? strutStyle;

  /// See [TextField.textAlign].
  final TextAlign textAlign;

  /// See [TextField.textAlignVertical].
  final TextAlignVertical? textAlignVertical;

  /// See [TextField.textDirection].
  final TextDirection? textDirection;

  /// See [TextField.readOnly].
  final bool readOnly;

  /// See [TextField.showCursor].
  final bool? showCursor;

  /// See [TextField.autofocus].
  final bool autofocus;

  /// See [TextField.statesController].
  final WidgetStatesController? statesController;

  /// See [TextField.obscuringCharacter].
  final String obscuringCharacter;

  /// See [TextField.autocorrect].
  final bool? autocorrect;

  /// See [TextField.smartDashesType].
  final SmartDashesType? smartDashesType;

  /// See [TextField.smartQuotesType].
  final SmartQuotesType? smartQuotesType;

  /// See [TextField.enableSuggestions].
  final bool enableSuggestions;

  /// See [TextField.maxLength].
  final int? maxLength;

  /// See [TextField.maxLengthEnforcement].
  final MaxLengthEnforcement? maxLengthEnforcement;

  /// Called with the new text after the field bloc has been updated.
  final ValueChanged<String>? onChanged;

  /// See [TextField.onEditingComplete].
  final VoidCallback? onEditingComplete;

  /// Called when the user submits the field.
  final ValueChanged<String>? onSubmitted;

  /// See [TextField.onAppPrivateCommand].
  final AppPrivateCommandCallback? onAppPrivateCommand;

  /// See [TextField.inputFormatters].
  final List<TextInputFormatter>? inputFormatters;

  /// Set to `false` to disable the field regardless of the bloc. The
  /// field is also disabled when the bloc is disabled ([MkFieldBloc.setEnabled]).
  final bool? enabled;

  /// See [TextField.ignorePointers].
  final bool? ignorePointers;

  /// See [TextField.cursorWidth].
  final double cursorWidth;

  /// See [TextField.cursorHeight].
  final double? cursorHeight;

  /// See [TextField.cursorRadius].
  final Radius? cursorRadius;

  /// See [TextField.cursorOpacityAnimates].
  final bool? cursorOpacityAnimates;

  /// See [TextField.cursorColor].
  final Color? cursorColor;

  /// See [TextField.cursorErrorColor].
  final Color? cursorErrorColor;

  /// See [TextField.selectionHeightStyle].
  final ui.BoxHeightStyle? selectionHeightStyle;

  /// See [TextField.selectionWidthStyle].
  final ui.BoxWidthStyle? selectionWidthStyle;

  /// See [TextField.keyboardAppearance].
  final Brightness? keyboardAppearance;

  /// See [TextField.scrollPadding].
  final EdgeInsets scrollPadding;

  /// See [TextField.enableInteractiveSelection].
  final bool? enableInteractiveSelection;

  /// See [TextField.selectAllOnFocus].
  final bool? selectAllOnFocus;

  /// See [TextField.selectionControls].
  final TextSelectionControls? selectionControls;

  /// See [TextField.dragStartBehavior].
  final DragStartBehavior dragStartBehavior;

  /// See [TextField.onTap].
  final GestureTapCallback? onTap;

  /// See [TextField.onTapAlwaysCalled].
  final bool onTapAlwaysCalled;

  /// See [TextField.onTapOutside].
  final TapRegionCallback? onTapOutside;

  /// See [TextField.onTapUpOutside].
  final TapRegionUpCallback? onTapUpOutside;

  /// See [TextField.mouseCursor].
  final MouseCursor? mouseCursor;

  /// See [TextField.buildCounter].
  final InputCounterWidgetBuilder? buildCounter;

  /// See [TextField.scrollController].
  final ScrollController? scrollController;

  /// See [TextField.scrollPhysics].
  final ScrollPhysics? scrollPhysics;

  /// See [TextField.autofillHints].
  final Iterable<String>? autofillHints;

  /// See [TextField.contentInsertionConfiguration].
  final ContentInsertionConfiguration? contentInsertionConfiguration;

  /// See [TextField.clipBehavior].
  final Clip clipBehavior;

  /// See [TextField.restorationId].
  final String? restorationId;

  /// See [TextField.stylusHandwritingEnabled].
  final bool stylusHandwritingEnabled;

  /// See [TextField.enableIMEPersonalizedLearning].
  final bool enableIMEPersonalizedLearning;

  /// When null, the standard adaptive text-selection toolbar is used (same as
  /// [TextField]). Pass a builder returning `SizedBox.shrink()` to disable it.
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// See [TextField.canRequestFocus].
  final bool canRequestFocus;

  /// See [TextField.undoController].
  final UndoHistoryController? undoController;

  /// See [TextField.spellCheckConfiguration].
  final SpellCheckConfiguration? spellCheckConfiguration;

  /// See [TextField.magnifierConfiguration].
  final TextMagnifierConfiguration? magnifierConfiguration;

  /// See [TextField.hintLocales].
  final List<Locale>? hintLocales;

  /// See [TextField.groupId].
  final Object groupId;

  /// Optional focus node. When omitted the widget manages its own. Blur
  /// always marks the field as touched. A supplied node is never disposed here.
  final FocusNode? focusNode;

  @override
  State<MkPasswordField> createState() => _MkPasswordFieldState();
}

class _MkPasswordFieldState extends State<MkPasswordField> {
  late bool _obscureText = widget.initiallyObscured;

  @override
  Widget build(BuildContext context) {
    final effectiveDecoration =
        (widget.decoration ?? const InputDecoration()).copyWith(
      labelText: widget.decoration?.labelText ?? 'Password',
      prefixIcon:
          widget.decoration?.prefixIcon ?? const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        icon: _obscureText ? widget.showPasswordIcon : widget.hidePasswordIcon,
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );

    return MkTextField(
      fieldBloc: widget.fieldBloc,
      name: widget.name,
      decoration: effectiveDecoration,
      obscureText: _obscureText,
      autovalidateMode: widget.autovalidateMode,
      showValidatingIndicator: widget.showValidatingIndicator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      style: widget.style,
      strutStyle: widget.strutStyle,
      textAlign: widget.textAlign,
      textAlignVertical: widget.textAlignVertical,
      textDirection: widget.textDirection,
      readOnly: widget.readOnly,
      showCursor: widget.showCursor,
      autofocus: widget.autofocus,
      statesController: widget.statesController,
      obscuringCharacter: widget.obscuringCharacter,
      autocorrect: widget.autocorrect,
      smartDashesType: widget.smartDashesType,
      smartQuotesType: widget.smartQuotesType,
      enableSuggestions: widget.enableSuggestions,
      maxLength: widget.maxLength,
      maxLengthEnforcement: widget.maxLengthEnforcement,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      onAppPrivateCommand: widget.onAppPrivateCommand,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      ignorePointers: widget.ignorePointers,
      cursorWidth: widget.cursorWidth,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      cursorOpacityAnimates: widget.cursorOpacityAnimates,
      cursorColor: widget.cursorColor,
      cursorErrorColor: widget.cursorErrorColor,
      selectionHeightStyle: widget.selectionHeightStyle,
      selectionWidthStyle: widget.selectionWidthStyle,
      keyboardAppearance: widget.keyboardAppearance,
      scrollPadding: widget.scrollPadding,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      selectAllOnFocus: widget.selectAllOnFocus,
      selectionControls: widget.selectionControls,
      dragStartBehavior: widget.dragStartBehavior,
      onTap: widget.onTap,
      onTapAlwaysCalled: widget.onTapAlwaysCalled,
      onTapOutside: widget.onTapOutside,
      onTapUpOutside: widget.onTapUpOutside,
      mouseCursor: widget.mouseCursor,
      buildCounter: widget.buildCounter,
      scrollController: widget.scrollController,
      scrollPhysics: widget.scrollPhysics,
      autofillHints: widget.autofillHints,
      contentInsertionConfiguration: widget.contentInsertionConfiguration,
      clipBehavior: widget.clipBehavior,
      restorationId: widget.restorationId,
      stylusHandwritingEnabled: widget.stylusHandwritingEnabled,
      enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
      contextMenuBuilder: widget.contextMenuBuilder,
      canRequestFocus: widget.canRequestFocus,
      undoController: widget.undoController,
      spellCheckConfiguration: widget.spellCheckConfiguration,
      magnifierConfiguration: widget.magnifierConfiguration,
      hintLocales: widget.hintLocales,
      groupId: widget.groupId,
      focusNode: widget.focusNode,
    );
  }
}
