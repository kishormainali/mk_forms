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
