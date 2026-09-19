import 'package:flutter/material.dart';
import '../../../blocs/field_bloc.dart';
import 'mk_text_field.dart';

/// A specialized [MkTextField] pre-configured for email inputs.
class MkEmailField extends StatelessWidget {
  const MkEmailField({
    super.key,
    this.fieldBloc,
    this.name,
    this.decoration,
    this.textInputAction = TextInputAction.next,
    this.style,
    this.autofocus = false,
    this.readOnly = false,
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
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final effectiveDecoration = (decoration ?? const InputDecoration()).copyWith(
      labelText: decoration?.labelText ?? 'Email',
      hintText: decoration?.hintText ?? 'example@domain.com',
      prefixIcon: decoration?.prefixIcon ?? const Icon(Icons.email_outlined),
    );

    return MkTextField(
      fieldBloc: fieldBloc,
      name: name,
      decoration: effectiveDecoration,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction,
      style: style,
      autofocus: autofocus,
      readOnly: readOnly,
      autovalidateMode: autovalidateMode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
