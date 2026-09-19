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
}
