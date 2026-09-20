import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../blocs/field_bloc.dart';
import 'mk_text_field.dart';

/// A specialized [MkTextField] pre-configured for email inputs.
///
/// Accepts the same parameters as [MkTextField] (which mirror [TextField]),
/// except `maxLines`, `minLines` and `expands`, since an email is a single line.
/// The default label, hint and prefix icon are only used when [decoration]
/// leaves them unset. [keyboardType] defaults to [TextInputType.emailAddress]
/// and [textInputAction] to [TextInputAction.next].
class MkEmailField extends StatelessWidget {
  const MkEmailField({
    super.key,
    this.fieldBloc,
    this.name,
    this.decoration,
    this.keyboardType = TextInputType.emailAddress,
    this.textInputAction = TextInputAction.next,
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
    this.obscureText = false,
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

  /// Base decoration. Unset label, hint and prefix icon fall back to email defaults.
  final InputDecoration? decoration;

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

  /// See [TextField.obscureText].
  final bool obscureText;

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
  Widget build(BuildContext context) {
    final effectiveDecoration = (decoration ?? const InputDecoration())
        .copyWith(
          labelText: decoration?.labelText ?? 'Email',
          hintText: decoration?.hintText ?? 'example@domain.com',
          prefixIcon:
              decoration?.prefixIcon ?? const Icon(Icons.email_outlined),
        );

    return MkTextField(
      fieldBloc: fieldBloc,
      name: name,
      decoration: effectiveDecoration,
      autovalidateMode: autovalidateMode,
      showValidatingIndicator: showValidatingIndicator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      textDirection: textDirection,
      readOnly: readOnly,
      showCursor: showCursor,
      autofocus: autofocus,
      statesController: statesController,
      obscuringCharacter: obscuringCharacter,
      obscureText: obscureText,
      autocorrect: autocorrect,
      smartDashesType: smartDashesType,
      smartQuotesType: smartQuotesType,
      enableSuggestions: enableSuggestions,
      maxLength: maxLength,
      maxLengthEnforcement: maxLengthEnforcement,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      onAppPrivateCommand: onAppPrivateCommand,
      inputFormatters: inputFormatters,
      enabled: enabled,
      ignorePointers: ignorePointers,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorOpacityAnimates: cursorOpacityAnimates,
      cursorColor: cursorColor,
      cursorErrorColor: cursorErrorColor,
      selectionHeightStyle: selectionHeightStyle,
      selectionWidthStyle: selectionWidthStyle,
      keyboardAppearance: keyboardAppearance,
      scrollPadding: scrollPadding,
      enableInteractiveSelection: enableInteractiveSelection,
      selectAllOnFocus: selectAllOnFocus,
      selectionControls: selectionControls,
      dragStartBehavior: dragStartBehavior,
      onTap: onTap,
      onTapAlwaysCalled: onTapAlwaysCalled,
      onTapOutside: onTapOutside,
      onTapUpOutside: onTapUpOutside,
      mouseCursor: mouseCursor,
      buildCounter: buildCounter,
      scrollController: scrollController,
      scrollPhysics: scrollPhysics,
      autofillHints: autofillHints,
      contentInsertionConfiguration: contentInsertionConfiguration,
      clipBehavior: clipBehavior,
      restorationId: restorationId,
      stylusHandwritingEnabled: stylusHandwritingEnabled,
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
      contextMenuBuilder: contextMenuBuilder,
      canRequestFocus: canRequestFocus,
      undoController: undoController,
      spellCheckConfiguration: spellCheckConfiguration,
      magnifierConfiguration: magnifierConfiguration,
      hintLocales: hintLocales,
      groupId: groupId,
      focusNode: focusNode,
    );
  }
}
