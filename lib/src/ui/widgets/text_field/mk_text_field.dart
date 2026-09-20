import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../blocs/field_bloc.dart';
import '../../../core/deep_equals.dart';
import '../../field_builder.dart';
import '../../form_scope.dart';

/// A Material [TextField] pre-configured for an [MkFieldBloc<String>].
///
/// Features:
/// - Bidirectional sync between an internal [TextEditingController] and [MkFieldBloc].
/// - Automatic [FocusNode] blur tracking triggering [MkFieldBloc.touch].
/// - Visual error display governed by [MkFieldState.showError] (no premature errors on load).
/// - Optional async validation progress indicator in decoration.
/// - Rebuilds only when something visible changes (not on every keystroke).
///
/// Every [TextField] parameter is available here and forwarded as-is, except:
/// - `controller`: owned by this widget to keep the text in sync with the bloc.
/// - `enabled`: combined with the bloc's enabled state (both must allow input).
/// - `decoration`: the error text and the validating indicator are added to it.
/// - `onChanged`: called *after* the bloc has been updated.
class MkTextField extends StatefulWidget {
  const MkTextField({
    super.key,
    this.fieldBloc,
    this.name,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.textInputAction,
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
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
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
    this.showValidatingIndicator = true,
    this.autovalidateMode,
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

  /// The decoration of the field. `errorText` is filled in from the bloc.
  final InputDecoration decoration;

  /// Whether to replace the suffix icon with a spinner while validating asynchronously.
  final bool showValidatingIndicator;

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

  /// See [TextField.maxLines].
  final int? maxLines;

  /// See [TextField.minLines].
  final int? minLines;

  /// See [TextField.expands].
  final bool expands;

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
  State<MkTextField> createState() => _MkTextFieldState();
}

Widget _defaultContextMenuBuilder(
  BuildContext context,
  EditableTextState editableTextState,
) {
  return AdaptiveTextSelectionToolbar.editableText(
    editableTextState: editableTextState,
  );
}

class _MkTextFieldState extends State<MkTextField> {
  final TextEditingController _controller = TextEditingController();
  FocusNode? _ownFocusNode;
  MkFieldBloc<String>? _activeBloc;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(MkTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)
          ?.removeListener(_handleFocusChange);
      if (widget.focusNode != null) {
        _ownFocusNode?.dispose();
        _ownFocusNode = null;
      }
      _focusNode.addListener(_handleFocusChange);
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _activeBloc?.touch();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _ownFocusNode?.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Whether moving from [previous] to [current] changes anything on screen.
  ///
  /// While typing, the [TextField] already shows the new text, so a value-only
  /// change (the common case: every keystroke of a valid field) needs no
  /// rebuild. Programmatic changes (reset, populate) still rebuild because the
  /// incoming value then differs from what the controller holds.
  bool _affectsDisplay(
    MkFieldState<String> previous,
    MkFieldState<String> current,
  ) {
    return (current.value ?? '') != _controller.text ||
        previous.error != current.error ||
        previous.errorCode != current.errorCode ||
        !mkDeepEquals(previous.errorParams, current.errorParams) ||
        previous.isValidating != current.isValidating ||
        previous.isEnabled != current.isEnabled ||
        previous.isVisible != current.isVisible ||
        previous.isTouched != current.isTouched ||
        previous.wasFormSubmitted != current.wasFormSubmitted;
  }

  @override
  Widget build(BuildContext context) {
    return MkFieldBuilder<String>(
      fieldBloc: widget.fieldBloc,
      name: widget.name,
      buildWhen: _affectsDisplay,
      builder: (context, state, bloc) {
        _activeBloc = bloc;

        // Sync controller value if state changed externally (e.g. reset or programmatic update)
        final incomingText = state.value ?? '';
        if (_controller.text != incomingText) {
          _controller.value = TextEditingValue(
            text: incomingText,
            selection: TextSelection.collapsed(offset: incomingText.length),
          );
        }

        Widget? suffixIcon = widget.decoration.suffixIcon;
        if (widget.showValidatingIndicator && state.isValidating) {
          suffixIcon = const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final effectiveAutovalidateMode = widget.autovalidateMode ??
            MkFormScope.maybeAutovalidateModeOf(context) ??
            AutovalidateMode.onUserInteraction;

        final isErrorVisible = state.shouldShowError(effectiveAutovalidateMode);
        final isEnabled = state.isEnabled && (widget.enabled ?? true);

        final effectiveDecoration = widget.decoration.copyWith(
          errorText: isErrorVisible ? state.getLocalizedError(context) : null,
          suffixIcon: suffixIcon,
          enabled: isEnabled && !widget.readOnly,
        );

        return TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: effectiveDecoration,
          enabled: isEnabled,
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
          obscureText: widget.obscureText,
          autocorrect: widget.autocorrect,
          smartDashesType: widget.smartDashesType,
          smartQuotesType: widget.smartQuotesType,
          enableSuggestions: widget.enableSuggestions,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          expands: widget.expands,
          maxLength: widget.maxLength,
          maxLengthEnforcement: widget.maxLengthEnforcement,
          onEditingComplete: widget.onEditingComplete,
          onAppPrivateCommand: widget.onAppPrivateCommand,
          inputFormatters: widget.inputFormatters,
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
          canRequestFocus: widget.canRequestFocus,
          undoController: widget.undoController,
          spellCheckConfiguration: widget.spellCheckConfiguration,
          magnifierConfiguration: widget.magnifierConfiguration,
          hintLocales: widget.hintLocales,
          groupId: widget.groupId,
          contextMenuBuilder:
              widget.contextMenuBuilder ?? _defaultContextMenuBuilder,
          onChanged: (text) {
            bloc.changeValue(text);
            widget.onChanged?.call(text);
          },
          onSubmitted: (text) {
            widget.onSubmitted?.call(text);
          },
        );
      },
    );
  }
}
