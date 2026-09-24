import 'error_codes.dart';

/// Contract defining form validation error messages with runtime resolution.
///
/// Apps can extend [MkDefaultEnglishMessages] to override specific strings,
/// or implement [MkFormMessages] entirely for custom languages.
abstract class MkFormMessages {
  const MkFormMessages();

  /// Message when a required field is empty or not provided.
  String required();

  /// Message when an email address format is invalid.
  String email();

  /// Message when string length is less than [min].
  String minLength(int min);

  /// Message when string length exceeds [max].
  String maxLength(int max);

  /// Message when a number is less than [min].
  String min(num min);

  /// Message when a number exceeds [max].
  String max(num max);

  /// Message when a field does not match a required pattern regex.
  String pattern();

  /// Message when two fields do not match (e.g. password confirmation).
  String match();

  /// Message when an async validator threw instead of returning a result
  /// (e.g. the network was down), so the value could not be verified.
  ///
  /// Not abstract so existing [MkFormMessages] implementations keep compiling.
  String asyncValidationFailed() =>
      'Could not verify this value. Please try again.';

  /// Resolves an error code and optional parameter map to a localized string.
  String? resolve(String errorCode, [Map<String, dynamic> params = const {}]) {
    switch (errorCode) {
      case MkErrorCodes.required:
        return required();
      case MkErrorCodes.email:
        return email();
      case MkErrorCodes.minLength:
        return minLength(params['min'] as int? ?? 0);
      case MkErrorCodes.maxLength:
        return maxLength(params['max'] as int? ?? 0);
      case MkErrorCodes.min:
        return min(params['min'] as num? ?? 0);
      case MkErrorCodes.max:
        return max(params['max'] as num? ?? 0);
      case MkErrorCodes.pattern:
        return pattern();
      case MkErrorCodes.match:
        return match();
      case MkErrorCodes.asyncValidationFailed:
        return asyncValidationFailed();
      default:
        return null;
    }
  }

  /// Message when a required field is empty, naming [field] (e.g.
  /// `"Email is required."`).
  ///
  /// Not abstract so existing [MkFormMessages] implementations keep
  /// compiling; override to customize or localize.
  String requiredField(String field) => '$field is required.';

  /// Message when [field]'s value is not a valid email address.
  String emailField(String field) => '$field must be a valid email address.';

  /// Message when [field]'s string length is less than [min].
  String minLengthField(String field, int min) =>
      '$field must be at least $min characters.';

  /// Message when [field]'s string length exceeds [max].
  String maxLengthField(String field, int max) =>
      '$field must be at most $max characters.';

  /// Message when [field]'s numeric value is less than [min].
  String minField(String field, num min) => '$field must be at least $min.';

  /// Message when [field]'s numeric value exceeds [max].
  String maxField(String field, num max) => '$field must be at most $max.';

  /// Message when [field] does not match a required pattern regex.
  String patternField(String field) => '$field has an invalid format.';

  /// Message when [field] does not match another field's value (e.g.
  /// password confirmation).
  String matchField(String field) => '$field does not match.';

  /// Resolves an error code and field label to a field-aware localized
  /// string (e.g. `"Email is required."` instead of `"This field is
  /// required"`).
  ///
  /// Returns `null` for codes with no field-aware template (currently
  /// [MkErrorCodes.asyncValidationFailed] and any unrecognized code) —
  /// callers should fall back to [resolve] in that case. Additive: does not
  /// replace or change [resolve].
  String? resolveField(
    String errorCode,
    String field, [
    Map<String, dynamic> params = const {},
  ]) {
    switch (errorCode) {
      case MkErrorCodes.required:
        return requiredField(field);
      case MkErrorCodes.email:
        return emailField(field);
      case MkErrorCodes.minLength:
        return minLengthField(field, params['min'] as int? ?? 0);
      case MkErrorCodes.maxLength:
        return maxLengthField(field, params['max'] as int? ?? 0);
      case MkErrorCodes.min:
        return minField(field, params['min'] as num? ?? 0);
      case MkErrorCodes.max:
        return maxField(field, params['max'] as num? ?? 0);
      case MkErrorCodes.pattern:
        return patternField(field);
      case MkErrorCodes.match:
        return matchField(field);
      default:
        return null;
    }
  }
}
