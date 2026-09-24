import 'form_messages.dart';

/// Default English implementation of [MkFormMessages].
class MkDefaultEnglishMessages extends MkFormMessages {
  const MkDefaultEnglishMessages();

  @override
  String required() => 'This field is required';

  @override
  String email() => 'Please enter a valid email address';

  @override
  String minLength(int min) => 'Must be at least $min characters';

  @override
  String maxLength(int max) => 'Must be at most $max characters';

  @override
  String min(num min) => 'Must be at least $min';

  @override
  String max(num max) => 'Must be at most $max';

  @override
  String pattern() => 'Invalid format';

  @override
  String match() => 'Values do not match';

  @override
  String asyncValidationFailed() =>
      'Could not verify this value. Please try again.';

  @override
  String requiredField(String field) => '$field is required.';

  @override
  String emailField(String field) => '$field must be a valid email address.';

  @override
  String minLengthField(String field, int min) =>
      '$field must be at least $min characters.';

  @override
  String maxLengthField(String field, int max) =>
      '$field must be at most $max characters.';

  @override
  String minField(String field, num min) => '$field must be at least $min.';

  @override
  String maxField(String field, num max) => '$field must be at most $max.';

  @override
  String patternField(String field) => '$field has an invalid format.';

  @override
  String matchField(String field) => '$field does not match.';
}
