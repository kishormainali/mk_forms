import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

void main() {
  group('MkGroupBloc', () {
    test('aggregates values and validation status of children', () {
      final firstName = MkFieldBloc<String>(
        initialValue: 'John',
        validators: [MkValidators.required()],
      );
      final lastName = MkFieldBloc<String>(
        validators: [MkValidators.required()],
      );

      final group = MkGroupBloc({'firstName': firstName, 'lastName': lastName});

      expect(group.value, {'firstName': 'John', 'lastName': null});
      expect(group.isValid, isFalse); // lastName is required and null

      lastName.changeValue('Doe');

      expect(group.value, {'firstName': 'John', 'lastName': 'Doe'});
      expect(group.isValid, isTrue);
    });

    test('supports nested groups', () {
      final street = MkFieldBloc<String>(initialValue: '123 Main St');
      final city = MkFieldBloc<String>(initialValue: 'Springfield');

      final addressGroup = MkGroupBloc({'street': street, 'city': city});

      final userGroup = MkGroupBloc({
        'name': MkFieldBloc<String>(initialValue: 'Alice'),
        'address': addressGroup,
      });

      expect(userGroup.value, {
        'name': 'Alice',
        'address': {'street': '123 Main St', 'city': 'Springfield'},
      });
      expect(userGroup.isValid, isTrue);
    });

    test('touch and reset propagate to all children', () {
      final fieldA = MkFieldBloc<String>(initialValue: 'A');
      final fieldB = MkFieldBloc<String>(initialValue: 'B');

      final group = MkGroupBloc({'a': fieldA, 'b': fieldB});

      fieldA.changeValue('A modified');
      group.touch();

      expect(fieldA.isTouched, isTrue);
      expect(fieldB.isTouched, isTrue);
      expect(group.isDirty, isTrue);

      group.reset();

      expect(fieldA.isTouched, isFalse);
      expect(fieldB.isTouched, isFalse);
      expect(fieldA.isDirty, isFalse);
      expect(group.isDirty, isFalse);
    });

    test('dynamically adds and removes controls', () {
      final group = MkGroupBloc({});
      expect(group.controls.isEmpty, isTrue);

      final dynamicField = MkFieldBloc<String>(
        initialValue: 'Dynamic',
        validators: [MkValidators.required()],
      );

      group.addControl('dynamic', dynamicField);
      expect(group.controls.length, 1);
      expect(group.value, {'dynamic': 'Dynamic'});
      expect(group.isValid, isTrue);

      group.removeControl('dynamic');
      expect(group.controls.isEmpty, isTrue);
      expect(group.value.isEmpty, isTrue);
    });

    test('removeControl closes the removed control by default', () {
      final email = MkFieldBloc<String>(initialValue: 'a@b.com');
      final group = MkGroupBloc({'email': email});

      final removed = group.removeControl('email');

      expect(removed, same(email));
      expect(email.isClosed, isTrue);
    });

    test('removeControl(dispose: false) detaches without closing', () {
      final email = MkFieldBloc<String>(initialValue: 'a@b.com');
      final group = MkGroupBloc({'email': email});

      final detached = group.removeControl('email', dispose: false);

      expect(detached, same(email));
      expect(email.isClosed, isFalse);
      expect(group.value, isEmpty);

      unawaited(email.close());
    });

    test(
      'addControl replacing an existing key closes the displaced control',
      () {
        final oldField = MkFieldBloc<String>(initialValue: 'old');
        final group = MkGroupBloc({'name': oldField});

        group.addControl('name', MkFieldBloc<String>(initialValue: 'new'));

        expect(oldField.isClosed, isTrue);
        expect(group.value, {'name': 'new'});
      },
    );

    test(
      'addControl(disposeReplaced: false) leaves the displaced control open',
      () {
        final oldField = MkFieldBloc<String>(initialValue: 'old');
        final group = MkGroupBloc({'name': oldField});

        group.addControl(
          'name',
          MkFieldBloc<String>(initialValue: 'new'),
          disposeReplaced: false,
        );

        expect(oldField.isClosed, isFalse);
        unawaited(oldField.close());
      },
    );

    test('addControl re-registering the same instance under its own key does '
        'not close it', () {
      final field = MkFieldBloc<String>(initialValue: 'a');
      final group = MkGroupBloc({'name': field});

      group.addControl('name', field);

      expect(field.isClosed, isFalse);
      field.changeValue('b');
      expect(group.value, {'name': 'b'});
    });

    test(
      'removing a field with an active dependency stops it being revalidated '
      'and releases it from the control it depended on',
      () {
        final password = MkFieldBloc<String>(initialValue: 'secret1');
        final listenerCountBeforeDependency = password.stateListenerCount;
        final confirmPassword = MkFieldBloc<String>(initialValue: 'secret1')
          ..addDependency(password);
        expect(password.stateListenerCount, listenerCountBeforeDependency + 1);

        final group = MkGroupBloc({'confirmPassword': confirmPassword});

        group.removeControl('confirmPassword');
        expect(confirmPassword.isClosed, isTrue);

        // Closing confirmPassword must remove its dependency callback from
        // `password` — otherwise `password` keeps confirmPassword reachable
        // forever and keeps re-invoking a dead field's revalidation.
        expect(password.stateListenerCount, listenerCountBeforeDependency);

        // Before the fix, confirmPassword's dependency callback stayed
        // registered on `password` forever, so this next line would keep
        // confirmPassword reachable and would keep re-running its (now
        // pointless) revalidation on every change to `password`. It must be
        // a silent no-op now that confirmPassword is closed and detached.
        password.changeValue('secret2');

        expect(confirmPassword.isClosed, isTrue);
        expect(confirmPassword.value, 'secret1');
      },
    );

    group('field label auto-derivation', () {
      test(
        'fields are auto-labeled from their controls-map key at construction',
        () {
          final group = MkGroupBloc({
            'email': MkFieldBloc<String>(),
            'confirmPassword': MkFieldBloc<String>(),
          });

          expect(group.field<String>('email')!.label, 'Email');
          expect(
            group.field<String>('confirmPassword')!.label,
            'Confirm password',
          );
        },
      );

      test('an explicit label on the field is never overwritten', () {
        final group = MkGroupBloc({
          'email': MkFieldBloc<String>(label: 'Work email'),
        });

        expect(group.field<String>('email')!.label, 'Work email');
      });

      test('addControl auto-labels a dynamically added field', () {
        final group = MkGroupBloc({});
        group.addControl('phoneNumber', MkFieldBloc<String>());

        expect(group.field<String>('phoneNumber')!.label, 'Phone number');
      });

      test('nested groups auto-label their own fields independently', () {
        final group = MkGroupBloc({
          'shipping': MkGroupBloc({'streetName': MkFieldBloc<String>()}),
        });

        final shipping = group.group('shipping')!;
        expect(shipping.field<String>('streetName')!.label, 'Street name');
      });

      test('non-MkFieldBloc children (nested groups) are left alone', () {
        // Constructing this at all (no type error, no crash) is the assertion:
        // MkGroupBloc must not assume every child is a field.
        final group = MkGroupBloc({
          'address': MkGroupBloc({'city': MkFieldBloc<String>()}),
        });
        expect(group.group('address'), isNotNull);
      });
    });
  });
}
