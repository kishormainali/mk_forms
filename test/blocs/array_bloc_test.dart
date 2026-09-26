import 'dart:async';

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

    test('removeAt closes the removed control by default', () {
      final item = MkFieldBloc<String>(initialValue: 'a');
      final array = MkArrayBloc<MkFieldBloc<String>>([item]);

      final removed = array.removeAt(0);

      expect(removed, same(item));
      expect(item.isClosed, isTrue);
    });

    test('removeAt(dispose: false) detaches without closing', () {
      final item = MkFieldBloc<String>(initialValue: 'a');
      final array = MkArrayBloc<MkFieldBloc<String>>([item]);

      final removed = array.removeAt(0, dispose: false);

      expect(removed, same(item));
      expect(item.isClosed, isFalse);
      unawaited(item.close());
    });

    test('remove closes the removed control by default', () {
      final item = MkFieldBloc<String>(initialValue: 'a');
      final array = MkArrayBloc<MkFieldBloc<String>>([item]);

      final removedOk = array.remove(item);

      expect(removedOk, isTrue);
      expect(item.isClosed, isTrue);
    });

    test('remove(dispose: false) detaches without closing', () {
      final item = MkFieldBloc<String>(initialValue: 'a');
      final array = MkArrayBloc<MkFieldBloc<String>>([item]);

      array.remove(item, dispose: false);

      expect(item.isClosed, isFalse);
      unawaited(item.close());
    });

    test(
      'clear closes every control by default and returns the removed list',
      () {
        final item1 = MkFieldBloc<String>(initialValue: 'a');
        final item2 = MkFieldBloc<String>(initialValue: 'b');
        final array = MkArrayBloc<MkFieldBloc<String>>([item1, item2]);

        final removed = array.clear();

        expect(removed, [item1, item2]);
        expect(item1.isClosed, isTrue);
        expect(item2.isClosed, isTrue);
        expect(array.length, 0);
      },
    );

    test('clear(dispose: false) returns the removed list without closing', () {
      final item1 = MkFieldBloc<String>(initialValue: 'a');
      final item2 = MkFieldBloc<String>(initialValue: 'b');
      final array = MkArrayBloc<MkFieldBloc<String>>([item1, item2]);

      final removed = array.clear(dispose: false);

      expect(removed, [item1, item2]);
      expect(item1.isClosed, isFalse);
      expect(item2.isClosed, isFalse);

      unawaited(item1.close());
      unawaited(item2.close());
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
