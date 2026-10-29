import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

Widget _modal({
  required List<String> items,
  List<String> selection = const [],
  required bool Function(String, String) predicate,
  required List<List<String>> reported,
}) {
  return MaterialApp(
    home: Scaffold(
      body: MkMultiSelectModalContent<String>(
        items: items,
        currentSelection: selection,
        itemToString: (s) => s,
        searchHint: 'Search',
        modalTitle: 'Pick',
        searchPredicate: predicate,
        onSelectionChanged: reported.add,
        selectAllLabel: 'All',
        clearAllLabel: 'None',
      ),
    ),
  );
}

void main() {
  testWidgets('search filters items and tapping reports the selection', (
    tester,
  ) async {
    final reported = <List<String>>[];
    await tester.pumpWidget(
      _modal(
        items: ['apple', 'banana', 'cherry'],
        predicate: (item, q) => item.contains(q),
        reported: reported,
      ),
    );

    await tester.enterText(find.byType(TextField), 'an');
    await tester.pump();
    expect(find.text('banana'), findsOneWidget);
    expect(find.text('apple'), findsNothing);

    await tester.tap(find.text('banana'));
    await tester.pump();
    expect(reported.last, ['banana']);
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );

    await tester.tap(find.text('banana'));
    await tester.pump();
    expect(reported.last, isEmpty);
  });

  testWidgets('does not re-run the search predicate when only selection '
      'changes', (tester) async {
    var predicateCalls = 0;
    await tester.pumpWidget(
      _modal(
        items: ['apple', 'banana', 'cherry'],
        predicate: (item, q) {
          predicateCalls++;
          return item.contains(q);
        },
        reported: [],
      ),
    );
    final afterOpen = predicateCalls;
    expect(afterOpen, 3);

    await tester.tap(find.text('apple'));
    await tester.pump();
    await tester.tap(find.text('cherry'));
    await tester.pump();

    expect(predicateCalls, afterOpen);
  });

  testWidgets('select all and clear all keep row state in sync', (
    tester,
  ) async {
    final reported = <List<String>>[];
    await tester.pumpWidget(
      _modal(
        items: ['a', 'b'],
        selection: ['a'],
        predicate: (item, q) => item.contains(q),
        reported: reported,
      ),
    );
    List<bool?> checks() => tester
        .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
        .map((t) => t.value)
        .toList();

    expect(checks(), [true, false]);
    await tester.tap(find.text('All'));
    await tester.pump();
    expect(checks(), [true, true]);
    expect(reported.last, ['a', 'b']);

    await tester.tap(find.text('None'));
    await tester.pump();
    expect(checks(), [false, false]);
    expect(reported.last, isEmpty);

    await tester.tap(find.text('b'));
    await tester.pump();
    expect(checks(), [false, true]);
  });
}
