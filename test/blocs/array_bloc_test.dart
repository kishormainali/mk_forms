import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

void main() {
  group('MkArrayBloc', () {
    test('manages dynamic list of fields and aggregates values', () {
      final item1 = MkFieldBloc<String>(
        initialValue: 'Item 1',
        validators: [MkValidators.required()],
      );
      final item2 = MkFieldBloc<String>(
        initialValue: 'Item 2',
        validators: [MkValidators.required()],
      );

      final array = MkArrayBloc<MkFieldBloc<String>>([item1, item2]);

      expect(array.length, 2);
      expect(array.value, ['Item 1', 'Item 2']);
      expect(array.isValid, isTrue);

      final item3 = MkFieldBloc<String>(
        initialValue: '',
        validators: [MkValidators.required()],
      );

      array.add(item3);
      expect(array.length, 3);
      expect(array.value, ['Item 1', 'Item 2', '']);
      expect(array.isValid, isFalse); // item3 is empty and required

      array.removeAt(2);
      expect(array.length, 2);
      expect(array.isValid, isTrue);
    });

    test('supports array of groups for complex dynamic forms', () {
      MkGroupBloc createLineItem(String desc, int qty) {
        return MkGroupBloc({
          'description': MkFieldBloc<String>(initialValue: desc),
          'quantity': MkFieldBloc<int>(initialValue: qty),
        });
      }

      final array = MkArrayBloc<MkGroupBloc>([
        createLineItem('Widget A', 2),
        createLineItem('Widget B', 5),
      ]);

      expect(array.value, [
        {'description': 'Widget A', 'quantity': 2},
        {'description': 'Widget B', 'quantity': 5},
      ]);

      array.move(0, 1);
      expect(array.value, [
        {'description': 'Widget B', 'quantity': 5},
        {'description': 'Widget A', 'quantity': 2},
      ]);
    });
  });
}
