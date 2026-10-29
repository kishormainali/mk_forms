// Micro-benchmarks for the bloc layer. Not part of the regular test suite.
//
//   flutter test benchmark/form_benchmark_test.dart
//
// Each scenario is warmed up, then timed over several rounds; the median is
// reported. Numbers are only comparable between runs on the same machine in
// the same mode (JIT, debug), so compare before/after a change, not absolutes.
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

class _Form extends MkFormBloc {
  _Form(Map<String, MkControlBloc<dynamic>> controls)
    : super(controls: controls);

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async => null;
}

Map<String, MkControlBloc<dynamic>> _flat(int n) => {
  for (var i = 0; i < n; i++)
    'f$i': MkFieldBloc<String>(
      initialValue: '',
      validators: [MkValidators.required<String>()],
    ),
};

/// Runs [body] [iterations] times per round and returns the median µs/op.
double _measure(
  void Function(int i) body, {
  int iterations = 500,
  int rounds = 7,
}) {
  for (var i = 0; i < iterations; i++) {
    body(i);
  }
  final samples = <double>[];
  for (var r = 0; r < rounds; r++) {
    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      body(i);
    }
    sw.stop();
    samples.add(sw.elapsedMicroseconds / iterations);
  }
  samples.sort();
  return samples[samples.length ~/ 2];
}

Future<double> _measureAsync(
  Future<void> Function() body, {
  int iterations = 20,
  int rounds = 5,
}) async {
  for (var i = 0; i < 3; i++) {
    await body();
  }
  final samples = <double>[];
  for (var r = 0; r < rounds; r++) {
    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      await body();
    }
    sw.stop();
    samples.add(sw.elapsedMicroseconds / iterations);
  }
  samples.sort();
  return samples[samples.length ~/ 2];
}

void _report(String name, double micros) =>
    // ignore: avoid_print
    print(
      'BENCH ${name.padRight(46)} ${micros.toStringAsFixed(1).padLeft(10)} us',
    );

void main() {
  for (final n in [10, 100, 500, 2000]) {
    test('flat form, $n fields', () async {
      final fields = _flat(n);
      final form = _Form(fields);
      final f = fields['f0']! as MkFieldBloc<String>;

      _report(
        'keystroke (sync validator)      n=$n',
        _measure((i) => f.changeValue('v$i')),
      );
      _report(
        'submit()                        n=$n',
        await _measureAsync(form.submit),
      );
      _report(
        'reset()                         n=$n',
        _measure((_) {
          form.reset();
        }, iterations: 50),
      );
      final data = {for (var i = 0; i < n; i++) 'f$i': 'x$i'};
      _report(
        'populateValues()                n=$n',
        _measure((_) {
          form.populateValues(data);
        }, iterations: 50),
      );
      await form.close();
    });
  }

  test('field with async validator', () async {
    final f = MkFieldBloc<String>(
      initialValue: '',
      asyncValidators: [(v) async => null],
      debounceTime: const Duration(hours: 1),
    );
    _report(
      'keystroke (async validator, debounced)',
      _measure((i) => f.changeValue('v$i')),
    );
    await f.close();
  });

  test('nested groups, 20 x 20', () async {
    final groups = {
      for (var g = 0; g < 20; g++)
        'g$g': MkGroupBloc({
          for (var i = 0; i < 20; i++)
            'f$i': MkFieldBloc<String>(initialValue: ''),
        }),
    };
    final form = _Form(groups);
    final f = groups['g5']!.field<String>('f3')!;
    _report(
      'keystroke (nested, 400 fields)',
      _measure((i) => f.changeValue('v$i')),
    );
    await form.close();
  });

  for (final n in [100, 1000]) {
    test('array, $n rows', () async {
      final arr = MkArrayBloc<MkFieldBloc<String>>();
      final sw = Stopwatch()..start();
      for (var i = 0; i < n; i++) {
        arr.add(MkFieldBloc<String>(initialValue: 'a$i'));
      }
      sw.stop();
      _report('array add() x$n (total)', sw.elapsedMicroseconds.toDouble());
      final bulk = MkArrayBloc<MkFieldBloc<String>>();
      final rows = [
        for (var i = 0; i < n; i++) MkFieldBloc<String>(initialValue: 'a$i'),
      ];
      final sb = Stopwatch()..start();
      bulk.addAll(rows);
      sb.stop();
      _report('array addAll() x$n (total)', sb.elapsedMicroseconds.toDouble());
      await bulk.close();
      final row = arr[n ~/ 2];
      _report(
        'array row edit                  rows=$n',
        _measure((i) => row.changeValue('z$i')),
      );
      await arr.close();
    });
  }

  test('listeners: field with 5 dependents', () async {
    final source = MkFieldBloc<String>(initialValue: '');
    final dependents = [
      for (var i = 0; i < 5; i++)
        MkFieldBloc<String>(initialValue: '', dependsOn: [source]),
    ];
    _report(
      'keystroke with 5 dependents',
      _measure((i) => source.changeValue('v$i')),
    );
    for (final d in dependents) {
      await d.close();
    }
    await source.close();
  });
}
