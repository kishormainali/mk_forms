import 'package:flutter/material.dart';
import '../../../blocs/field_bloc.dart';
import 'mk_text_field.dart';

/// A specialized [MkTextField] pre-configured for passwords with visibility toggle.
class MkPasswordField extends StatefulWidget {
  const MkPasswordField({
    super.key,
    this.fieldBloc,
    this.name,
    this.decoration,
    this.textInputAction = TextInputAction.done,
    this.style,
    this.autofocus = false,
    this.readOnly = false,
    this.showPasswordIcon = const Icon(Icons.visibility_outlined),
    this.hidePasswordIcon = const Icon(Icons.visibility_off_outlined),
    this.onChanged,
    this.onSubmitted,
    this.autovalidateMode,
  }) : assert(
          fieldBloc != null || name != null,
          'Either fieldBloc or name must be provided',
        );

  final MkFieldBloc<String>? fieldBloc;
  final String? name;
  final AutovalidateMode? autovalidateMode;
  final InputDecoration? decoration;
  final TextInputAction textInputAction;
  final TextStyle? style;
  final bool autofocus;
  final bool readOnly;
  final Widget showPasswordIcon;
  final Widget hidePasswordIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<MkPasswordField> createState() => _MkPasswordFieldState();
}

class _MkPasswordFieldState extends State<MkPasswordField> {
  bool _obscureText = true;

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
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      style: widget.style,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      obscureText: _obscureText,
      autovalidateMode: widget.autovalidateMode,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}
