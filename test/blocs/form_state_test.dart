import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

MkFormState<int> _state({
  int extra = 0,
  int Function()? extraReset,
  bool Function(int)? isExtraBusy,
}) {
  return MkFormState<int>(
    submissionStatus: const MkSubmissionStatus.idle(),
    isValid: true,
    isValidating: false,
    isDirty: false,
    isTouched: false,
    wasSubmitted: false,
    values: const {},
    extra: extra,
    extraReset: extraReset,
    isExtraBusy: isExtraBusy,
  );
}

void main() {
  group('MkFormState<T>', () {
    test('extra defaults to null for the untyped base case', () {
      const state = MkFormState<Object?>(
        submissionStatus: MkSubmissionStatus.idle(),
        isValid: true,
        isValidating: false,
        isDirty: false,
        isTouched: false,
        wasSubmitted: false,
        values: {},
        extra: null,
      );
      expect(state.extra, isNull);
    });

    test('copyWith without extra: keeps the same extra reference', () {
      final state = _state(extra: 1);
      final copy = state.copyWith(isDirty: true);
      expect(identical(copy.extra, state.extra), isTrue);
      expect(copy.isDirty, isTrue);
    });

    test('copyWith(extra:) replaces extra', () {
      final state = _state(extra: 1);
      final copy = state.copyWith(extra: () => 2);
      expect(copy.extra, 2);
    });

    test('copyWith(extra: () => null) explicitly clears a nullable extra', () {
      final state = MkFormState<int?>(
        submissionStatus: const MkSubmissionStatus.idle(),
        isValid: true,
        isValidating: false,
        isDirty: false,
        isTouched: false,
        wasSubmitted: false,
        values: const {},
        extra: 1,
      );

      final cleared = state.copyWith(extra: () => null);

      expect(cleared.extra, isNull);
    });

    test(
      'reset() clears extra to null when extraReset legitimately returns null',
      () {
        final state = MkFormState<int?>(
          submissionStatus: const MkSubmissionStatus.idle(),
          isValid: true,
          isValidating: false,
          isDirty: false,
          isTouched: false,
          wasSubmitted: false,
          values: const {},
          extra: 5,
          extraReset: () => null,
        );

        final reset = state.reset(
          isValid: true,
          isValidating: false,
          values: const {},
        );

        expect(reset.extra, isNull);
      },
    );

    test('updateExtra applies the function to the current extra', () {
      final state = _state(extra: 1);
      final updated = state.updateExtra((e) => e + 1);
      expect(updated.extra, 2);
    });

    test('reset() regenerates extra via extraReset when provided', () {
      final state = _state(
        extra: 5,
        extraReset: () => 0,
      ).copyWith(isDirty: true);

      final reset = state.reset(
        isValid: true,
        isValidating: false,
        values: const {},
      );

      expect(reset.extra, 0);
      expect(reset.isDirty, isFalse);
    });

    test('reset() leaves extra unchanged when extraReset is omitted', () {
      final state = _state(extra: 5);
      final reset = state.reset(
        isValid: true,
        isValidating: false,
        values: const {},
      );
      expect(reset.extra, 5);
    });

    test(
      'isBusy defaults to isSubmitting alone when isExtraBusy is omitted',
      () {
        final idle = _state(extra: 1);
        expect(idle.isBusy, isFalse);

        final submitting = MkFormState<int>(
          submissionStatus: const MkSubmissionStatus.submitting(),
          isValid: true,
          isValidating: false,
          isDirty: false,
          isTouched: false,
          wasSubmitted: false,
          values: const {},
          extra: 1,
        );
        expect(submitting.isBusy, isTrue);
      },
    );

    test('isBusy reflects isExtraBusy(extra) when provided', () {
      final busy = _state(extra: 1, isExtraBusy: (e) => e > 0);
      expect(busy.isBusy, isTrue);
      expect(busy.canSubmit, isFalse);

      final idle = _state(extra: 0, isExtraBusy: (e) => e > 0);
      expect(idle.isBusy, isFalse);
    });

    test(
      'props includes extra, so states with different extras are unequal',
      () {
        expect(_state(extra: 1), isNot(equals(_state(extra: 2))));
        expect(_state(extra: 1), equals(_state(extra: 1)));
      },
    );
  });
}
