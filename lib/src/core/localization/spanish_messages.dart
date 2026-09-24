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

  @override
  String requiredField(String field) => '$field es obligatorio.';

  @override
  String emailField(String field) =>
      '$field debe ser un correo electrónico válido.';

  @override
  String minLengthField(String field, int min) =>
      '$field debe tener al menos $min caracteres.';

  @override
  String maxLengthField(String field, int max) =>
      '$field debe tener como máximo $max caracteres.';

  @override
  String minField(String field, num min) => '$field debe ser al menos $min.';

  @override
  String maxField(String field, num max) => '$field debe ser como máximo $max.';

  @override
  String patternField(String field) => '$field tiene un formato no válido.';

  @override
  String matchField(String field) => '$field no coincide.';

  @override
  String asyncValidationFailed() =>
      'No se pudo verificar este valor. Inténtelo de nuevo.';
}
