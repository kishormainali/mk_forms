import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

void main() {
  group('MkControlBloc state listeners', () {
    test('notify on change but not for an equal state', () {
      final field = MkFieldBloc<String>(initialValue: 'a');
      var calls = 0;
      field.addStateListener(() => calls++);

      field.changeValue('b');
      expect(calls, 1);

      field.changeValue('b');
      expect(calls, 1);
    });

    test(
      'are not notified when the first emission equals the initial state',
      () {
        final field = MkFieldBloc<String>(initialValue: 'a');
        var calls = 0;
        field.addStateListener(() => calls++);

        field.reset();
        expect(calls, 0);

        field.changeValue('b');
        expect(calls, 1);
      },
    );

    test(
      'a listener removed during notification does not break the others',
      () {
        final field = MkFieldBloc<String>(initialValue: '');
        final calls = <String>[];
        late void Function() first;
        first = () {
          calls.add('first');
          field.removeStateListener(first);
        };
        field.addStateListener(first);
        field.addStateListener(() => calls.add('second'));

        field.changeValue('x');
        expect(calls, ['first', 'second']);
        expect(field.stateListenerCount, 1);

        field.changeValue('y');
        expect(calls, ['first', 'second', 'second']);
      },
    );

    test('a listener added during notification runs from the next change', () {
      final field = MkFieldBloc<String>(initialValue: '');
      var late = 0;
      var added = false;
      field.addStateListener(() {
        if (added) return;
        added = true;
        field.addStateListener(() => late++);
      });

      field.changeValue('x');
      expect(late, 0);
      field.changeValue('y');
      expect(late, 1);
    });

    test('removing an unknown listener is a no-op', () {
      final field = MkFieldBloc<String>(initialValue: '');
      field.removeStateListener(() {});
      expect(field.stateListenerCount, 0);
    });
  });
}
