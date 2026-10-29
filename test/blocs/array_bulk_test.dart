import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

MkFieldBloc<String> _row(String v) => MkFieldBloc<String>(initialValue: v);

void main() {
  group('MkArrayBloc bulk operations', () {
    test('addAll adds every control with one state emission', () async {
      final array = MkArrayBloc<MkFieldBloc<String>>();
      final emitted = <MkArrayState<MkFieldBloc<String>>>[];
      final sub = array.stream.listen(emitted.add);

      array.addAll([_row('a'), _row('b'), _row('c')]);
      await Future<void>.delayed(Duration.zero);

      expect(array.length, 3);
      expect(array.value, ['a', 'b', 'c']);
      expect(emitted, hasLength(1));
      await sub.cancel();
      await array.close();
    });

    test('addAll rows stay wired to the array', () async {
      final array = MkArrayBloc<MkFieldBloc<String>>();
      array.addAll([_row('a'), _row('b')]);

      array[1].changeValue('z');
      expect(array.state.values, ['a', 'z']);
      expect(array.isDirty, isTrue);
      await array.close();
    });

    test('batch recomputes once for several structural changes', () async {
      final array = MkArrayBloc<MkFieldBloc<String>>([_row('a')]);
      final emitted = <Object>[];
      final sub = array.stream.listen(emitted.add);

      array.batch(() {
        array.add(_row('b'));
        array.insert(0, _row('c'));
        array.removeAt(2);
      });
      await Future<void>.delayed(Duration.zero);

      expect(array.value, ['c', 'a']);
      expect(emitted, hasLength(1));
      await sub.cancel();
      await array.close();
    });

    test('batch still flushes when the action throws', () async {
      final array = MkArrayBloc<MkFieldBloc<String>>();

      expect(
        () => array.batch(() {
          array.add(_row('a'));
          throw StateError('boom');
        }),
        throwsStateError,
      );

      expect(array.state.values, ['a']);
      expect(array.state.length, 1);
      await array.close();
    });

    test(
      'replaceAll swaps the rows, closes removed ones, keeps shared ones',
      () async {
        final a = _row('a');
        final b = _row('b');
        final c = _row('c');
        final array = MkArrayBloc<MkFieldBloc<String>>([a, b]);
        final emitted = <Object>[];
        final sub = array.stream.listen(emitted.add);

        final removed = array.replaceAll([b, c]);
        await Future<void>.delayed(Duration.zero);

        expect(removed, [a]);
        expect(a.isClosed, isTrue);
        expect(b.isClosed, isFalse);
        expect(array.controls, [b, c]);
        expect(array.value, ['b', 'c']);
        expect(emitted, hasLength(1));

        // Removed rows are detached, kept and new rows are wired exactly once.
        expect(a.stateListenerCount, 0);
        expect(b.stateListenerCount, 1);
        expect(c.stateListenerCount, 1);
        c.changeValue('x');
        expect(array.state.values, ['b', 'x']);
        await sub.cancel();
        await array.close();
      },
    );

    test('replaceAll with dispose: false leaves removed rows open', () async {
      final a = _row('a');
      final array = MkArrayBloc<MkFieldBloc<String>>([a]);

      array.replaceAll([_row('b')], dispose: false);

      expect(a.isClosed, isFalse);
      expect(a.stateListenerCount, 0);
      await a.close();
      await array.close();
    });
  });

  group('MkArrayBloc controls view', () {
    test('is the same instance across row edits', () async {
      final array = MkArrayBloc<MkFieldBloc<String>>([_row('a'), _row('b')]);
      final before = array.state.controls;

      array[0].changeValue('x');

      expect(identical(array.state.controls, before), isTrue);
      expect(identical(array.controls, before), isTrue);
      await array.close();
    });

    test('is rebuilt after a structural change and is unmodifiable', () async {
      final array = MkArrayBloc<MkFieldBloc<String>>([_row('a')]);
      final before = array.controls;

      array.add(_row('b'));

      expect(identical(array.controls, before), isFalse);
      expect(before, hasLength(1));
      expect(array.controls, hasLength(2));
      expect(identical(array.state.controls, array.controls), isTrue);
      expect(() => array.controls.add(_row('c')), throwsUnsupportedError);
      await array.close();
    });
  });
}
