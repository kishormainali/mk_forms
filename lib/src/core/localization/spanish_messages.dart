import 'form_messages.dart';

/// Spanish implementation of [MkFormMessages].
class MkSpanishMessages extends MkFormMessages {
  const MkSpanishMessages();

  @override
  String required() => 'Este campo es obligatorio';

  @override
  String email() => 'Por favor ingrese un correo electrónico válido';

  @override
  String minLength(int min) => 'Debe tener al menos $min caracteres';

  @override
  String maxLength(int max) => 'Debe tener como máximo $max caracteres';

  @override
  String min(num min) => 'Debe ser al menos $min';

  @override
  String max(num max) => 'Debe ser como máximo $max';

  @override
  String pattern() => 'Formato no válido';

  @override
  String match() => 'Los valores no coinciden';
}
