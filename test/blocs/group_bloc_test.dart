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

      final group = MkGroupBloc({
        'firstName': firstName,
        'lastName': lastName,
      });

      expect(group.value, {'firstName': 'John', 'lastName': null});
      expect(group.isValid, isFalse); // lastName is required and null

      lastName.changeValue('Doe');

      expect(group.value, {'firstName': 'John', 'lastName': 'Doe'});
      expect(group.isValid, isTrue);
    });

    test('supports nested groups', () {
      final street = MkFieldBloc<String>(initialValue: '123 Main St');
      final city = MkFieldBloc<String>(initialValue: 'Springfield');

      final addressGroup = MkGroupBloc({
        'street': street,
        'city': city,
      });

      final userGroup = MkGroupBloc({
        'name': MkFieldBloc<String>(initialValue: 'Alice'),
        'address': addressGroup,
      });

      expect(userGroup.value, {
        'name': 'Alice',
        'address': {
          'street': '123 Main St',
          'city': 'Springfield',
        },
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
  });
}
