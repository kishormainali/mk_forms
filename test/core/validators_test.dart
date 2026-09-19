import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

void main() {
  group('MkValidators', () {
    group('required', () {
      final validator = MkValidators.required<dynamic>();

      test('returns error for null', () {
        expect(validator(null), 'This field is required');
      });

      test('returns error for empty or whitespace string', () {
        expect(validator(''), 'This field is required');
        expect(validator('   '), 'This field is required');
      });

      test('returns null for non-empty string', () {
        expect(validator('hello'), isNull);
      });

      test('returns error for false boolean', () {
        expect(validator(false), 'This field is required');
      });

      test('returns null for true boolean', () {
        expect(validator(true), isNull);
      });

      test('returns error for empty iterable or map', () {
        expect(validator(<dynamic>[]), 'This field is required');
        expect(validator(<dynamic, dynamic>{}), 'This field is required');
      });

      test('returns null for non-empty iterable or map', () {
        expect(validator([1]), isNull);
        expect(validator({'key': 'val'}), isNull);
      });

      test('uses custom error message', () {
        final custom = MkValidators.required<String>('Required field!');
        expect(custom(''), 'Required field!');
      });
    });

    group('email', () {
      final validator = MkValidators.email();

      test('returns null for null or empty (optional by default)', () {
        expect(validator(null), isNull);
        expect(validator(''), isNull);
      });

      test('returns error for invalid email addresses', () {
        expect(validator('invalid'), 'Please enter a valid email address');
        expect(validator('user@'), 'Please enter a valid email address');
        expect(validator('user@domain'), 'Please enter a valid email address');
      });

      test('returns null for valid email addresses', () {
        expect(validator('user@example.com'), isNull);
        expect(validator('test.user+tag@domain.co'), isNull);
      });
    });

    group('minLength & maxLength', () {
      test('minLength validates string length', () {
        final validator = MkValidators.minLength(5);
        expect(validator(null), isNull);
        expect(validator('1234'), 'Must be at least 5 characters');
        expect(validator('12345'), isNull);
        expect(validator('123456'), isNull);
      });

      test('maxLength validates string length', () {
        final validator = MkValidators.maxLength(5);
        expect(validator(null), isNull);
        expect(validator('1234'), isNull);
        expect(validator('12345'), isNull);
        expect(validator('123456'), 'Must be at most 5 characters');
      });
    });

    group('min & max numbers', () {
      test('min validates numeric lower bound', () {
        final validator = MkValidators.min(10);
        expect(validator(null), isNull);
        expect(validator(9), 'Must be at least 10');
        expect(validator(10), isNull);
        expect(validator(11), isNull);
      });

      test('max validates numeric upper bound', () {
        final validator = MkValidators.max(10);
        expect(validator(null), isNull);
        expect(validator(11), 'Must be at most 10');
        expect(validator(10), isNull);
        expect(validator(9), isNull);
      });
    });

    group('pattern', () {
      final validator = MkValidators.pattern(RegExp(r'^[0-9]+$'));

      test('validates pattern regex', () {
        expect(validator(null), isNull);
        expect(validator('abc'), 'Invalid format');
        expect(validator('123'), isNull);
      });
    });

    group('match & matchControl', () {
      test('match compares against getter value', () {
        String? target = 'secret123';
        final validator = MkValidators.match<String>(() => target);

        expect(validator('wrong'), 'Values do not match');
        expect(validator('secret123'), isNull);

        target = 'newSecret';
        expect(validator('secret123'), 'Values do not match');
        expect(validator('newSecret'), isNull);
      });

      test('matchControl compares against control value', () {
        final targetField = MkFieldBloc<String>(initialValue: 'password123');
        final validator = MkValidators.matchControl<String>(targetField);

        expect(validator('mismatch'), 'Values do not match');
        expect(validator('password123'), isNull);
      });
    });

    group('compose & composeAsync', () {
      test('compose evaluates in order and halts on first error', () {
        final validator = MkValidators.compose<String>([
          MkValidators.required(),
          MkValidators.email(),
          MkValidators.minLength(10),
        ]);

        expect(validator(''), 'This field is required');
        expect(validator('notanemail'), 'Please enter a valid email address');
        expect(validator('a@b.co'), 'Must be at least 10 characters');
        expect(validator('valid.user@example.com'), isNull);
      });

      test('composeAsync evaluates async validators in order', () async {
        final validator = MkValidators.composeAsync<String>([
          (val) async => val == 'taken' ? 'Username is taken' : null,
          (val) async => val == 'reserved' ? 'Username is reserved' : null,
        ]);

        expect(await validator('taken'), 'Username is taken');
        expect(await validator('reserved'), 'Username is reserved');
        expect(await validator('available'), isNull);
      });
    });
  });
}
