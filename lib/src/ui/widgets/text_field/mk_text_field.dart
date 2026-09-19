import 'package:flutter/material.dart';
import '../../../blocs/field_bloc.dart';
import '../../field_builder.dart';
import '../../form_scope.dart';

/// A Material [TextField] pre-configured for an [MkFieldBloc<String>].
///
/// Features:
/// - Bidirectional sync between [TextEditingController] and [MkFieldBloc].
/// - Automatic [FocusNode] blur tracking triggering [MkFieldBloc.touch].
/// - Visual error display governed by [MkFieldState.showError] (no premature errors on load).
/// - Optional async validation progress indicator in decoration.
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
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.showValidatingIndicator = true,
    this.autovalidateMode,
  }) : assert(
         fieldBloc != null || name != null,
         'Either fieldBloc or name must be provided',
       );

  final MkFieldBloc<String>? fieldBloc;
  final String? name;
  final AutovalidateMode? autovalidateMode;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool autofocus;
  final bool readOnly;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool showValidatingIndicator;

  @override
  State<MkTextField> createState() => _MkTextFieldState();
}

class _MkTextFieldState extends State<MkTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  MkFieldBloc<String>? _activeBloc;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _activeBloc?.touch();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MkFieldBuilder<String>(
      fieldBloc: widget.fieldBloc,
      name: widget.name,
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

        final effectiveDecoration = widget.decoration.copyWith(
          errorText: isErrorVisible ? state.getLocalizedError(context) : null,
          suffixIcon: suffixIcon,
          enabled: state.isEnabled && !widget.readOnly,
        );

        return TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: effectiveDecoration,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          style: widget.style,
          textAlign: widget.textAlign,
          autofocus: widget.autofocus,
          readOnly: widget.readOnly,
          obscureText: widget.obscureText,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          enabled: state.isEnabled,
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
