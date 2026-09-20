import 'dart:async';
import '../blocs/control_bloc.dart';
import 'localization.dart';

/// Metadata associated with a validator for i18n resolution.
class MkValidatorMetadata {
  const MkValidatorMetadata({required this.errorCode, this.params = const {}});

  final String errorCode;
  final Map<String, dynamic> params;
}

/// Internal expando mapping validator functions to their i18n metadata.
final Expando<MkValidatorMetadata> _validatorMetadata =
    Expando<MkValidatorMetadata>('mk_validator_metadata');

/// Returns the i18n metadata associated with [validator], if any.
MkValidatorMetadata? getValidatorMetadata(dynamic validator) {
  if (validator is Object) {
    return _validatorMetadata[validator];
  }
  return null;
}

/// A synchronous validation function for a field of type [T].
/// Returns `null` if valid, or an error [String] if invalid.
typedef Validator<T> = String? Function(T? value);

/// An asynchronous validation function for a field of type [T].
/// Returns `null` if valid, or an error [String] if invalid.
typedef AsyncValidator<T> = Future<String?> Function(T? value);

/// Common built-in form validators with internationalization support.
class MkValidators {
  const MkValidators._();

  /// Email regex based on the WHATWG/HTML5 `type="email"` rule, additionally
  /// requiring a dotted domain (`user@localhost` is rejected).
  ///
  /// The whole string must match; each domain label is 1-63 characters of
  /// letters, digits or hyphens and cannot start or end with a hyphen.
  static final RegExp emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+"
    r'@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
    r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
  );

  /// Validates that the value is not null, not empty (for strings/iterables/maps),
  /// and not false (for booleans if required).
  static Validator<T> required<T>([String? message]) {
    String? validator(T? value) {
      if (value == null ||
          (value is String && value.trim().isEmpty) ||
          (value is Iterable && value.isEmpty) ||
          (value is Map && value.isEmpty) ||
          (value is bool && !value)) {
        return message ?? MkFormLocalizations.current.required();
      }
      return null;
    }

    if (message == null) {
      _validatorMetadata[validator] = const MkValidatorMetadata(
        errorCode: MkErrorCodes.required,
      );
    }
    return validator;
  }

  /// Validates that a string is a valid email address.
  /// If the value is null or empty, it returns null (use [required] together if mandatory).
  static Validator<String> email([String? message]) {
    String? validator(String? value) {
      if (value == null || value.trim().isEmpty) return null;
      if (!emailRegex.hasMatch(value.trim())) {
        return message ?? MkFormLocalizations.current.email();
      }
      return null;
    }

    if (message == null) {
      _validatorMetadata[validator] = const MkValidatorMetadata(
        errorCode: MkErrorCodes.email,
      );
    }
    return validator;
  }

  /// Validates that a string has at least [min] characters.
  static Validator<String> minLength(int min, [String? message]) {
    String? validator(String? value) {
      if (value == null || value.isEmpty) return null;
      if (value.length < min) {
        return message ?? MkFormLocalizations.current.minLength(min);
      }
      return null;
    }

    if (message == null) {
      _validatorMetadata[validator] = MkValidatorMetadata(
        errorCode: MkErrorCodes.minLength,
        params: {'min': min},
      );
    }
    return validator;
  }

  /// Validates that a string has at most [max] characters.
  static Validator<String> maxLength(int max, [String? message]) {
    String? validator(String? value) {
      if (value == null || value.isEmpty) return null;
      if (value.length > max) {
        return message ?? MkFormLocalizations.current.maxLength(max);
      }
      return null;
    }

    if (message == null) {
      _validatorMetadata[validator] = MkValidatorMetadata(
        errorCode: MkErrorCodes.maxLength,
        params: {'max': max},
      );
    }
    return validator;
  }

  /// Validates that a numeric value is at least [min].
  static Validator<num> min(num min, [String? message]) {
    String? validator(num? value) {
      if (value == null) return null;
      if (value < min) {
        return message ?? MkFormLocalizations.current.min(min);
      }
      return null;
    }

    if (message == null) {
      _validatorMetadata[validator] = MkValidatorMetadata(
        errorCode: MkErrorCodes.min,
        params: {'min': min},
      );
    }
    return validator;
  }

  /// Validates that a numeric value is at most [max].
  static Validator<num> max(num max, [String? message]) {
    String? validator(num? value) {
      if (value == null) return null;
      if (value > max) {
        return message ?? MkFormLocalizations.current.max(max);
      }
      return null;
    }

    if (message == null) {
      _validatorMetadata[validator] = MkValidatorMetadata(
        errorCode: MkErrorCodes.max,
        params: {'max': max},
      );
    }
    return validator;
  }

  /// Validates that a string matches a given [pattern].
  static Validator<String> pattern(Pattern pattern, [String? message]) {
    String? validator(String? value) {
      if (value == null || value.isEmpty) return null;
      final regex = pattern is RegExp ? pattern : RegExp(pattern.toString());
      if (!regex.hasMatch(value)) {
        return message ?? MkFormLocalizations.current.pattern();
      }
      return null;
    }

    if (message == null) {
      _validatorMetadata[validator] = const MkValidatorMetadata(
        errorCode: MkErrorCodes.pattern,
      );
    }
    return validator;
  }

  /// Validates that the field value matches the value returned by [otherValueGetter].
  /// Excellent for password confirmation or matching dynamic values.
  static Validator<T> match<T>(
    T? Function() otherValueGetter, [
    String? message,
  ]) {
    String? validator(T? value) {
      try {
        final other = otherValueGetter();
        if (value != other) {
          return message ?? MkFormLocalizations.current.match();
        }
      } catch (_) {
        return null;
      }
      return null;
    }

    if (message == null) {
      _validatorMetadata[validator] = const MkValidatorMetadata(
        errorCode: MkErrorCodes.match,
      );
    }
    return validator;
  }

  /// Validates that the field value matches another [MkControlBloc]'s value.
  static Validator<T> matchControl<T>(
    MkControlBloc<dynamic> otherControl, [
    String? message,
  ]) {
    String? validator(T? value) {
      final other = otherControl.value;
      if (value != other) {
        return message ?? MkFormLocalizations.current.match();
      }
      return null;
    }

    if (message == null) {
      _validatorMetadata[validator] = const MkValidatorMetadata(
        errorCode: MkErrorCodes.match,
      );
    }
    return validator;
  }

  /// Composes multiple validators into a single validator.
  /// Executes sequentially and returns the first error encountered.
  static Validator<T> compose<T>(List<Validator<T>> validators) {
    return (T? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Composes multiple async validators into a single async validator.
  static AsyncValidator<T> composeAsync<T>(List<AsyncValidator<T>> validators) {
    return (T? value) async {
      for (final validator in validators) {
        final error = await validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
