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
}
