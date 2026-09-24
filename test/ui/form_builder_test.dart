import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';
import '../support/profile_form.dart';

void main() {
  group('MkFormStateBuilder<S> / MkFormBuilder', () {
    testWidgets(
      'MkFormStateBuilder delivers the custom state type and honours buildWhen',
      (tester) async {
        final upload = Completer<void>();
        final bloc = ProfileBloc(avatarUpload: upload);
        addTearDown(bloc.close);
        var filteredBuilds = 0;
        var unfilteredBuilds = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: MkFormScope.value(
              value: bloc,
              child: Column(
                children: [
                  // Filtered builder: only rebuilds when avatarStatus changes.
                  MkFormStateBuilder<MkFormState<ProfileExtra>>(
                    buildWhen: (previous, current) =>
                        previous.extra.avatarStatus !=
                        current.extra.avatarStatus,
                    builder: (context, state, formBloc) {
                      filteredBuilds++;
                      return Text(
                        state.extra.avatarStatus.isSubmitting
                            ? 'uploading'
                            : 'idle',
                      );
                    },
                  ),
                  // Unfiltered builder: rebuilds on any state change (positive control).
                  MkFormStateBuilder<MkFormState<ProfileExtra>>(
                    builder: (context, state, formBloc) {
                      unfilteredBuilds++;
                      return Text('unfiltered: $unfilteredBuilds');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        expect(find.text('idle'), findsOneWidget);
        final filteredAfterFirstFrame = filteredBuilds;
        final unfilteredAfterFirstFrame = unfilteredBuilds;

        // Not part of buildWhen: name change should deliver state but not
        // rebuild the filtered builder (avatarStatus unchanged).
        bloc.field<String>('name')!.changeValue('Ada');
        // Bloc stream delivery takes a microtask hop.
        await tester.pump();
        // Allow state emission to propagate to widgets.
        await tester.pump();
        // Prove the state actually changed.
        expect(bloc.state.values['name'], 'Ada');
        // Unfiltered builder should have rebuilt (any state change).
        expect(unfilteredBuilds, greaterThan(unfilteredAfterFirstFrame));
        // Filtered builder should NOT have rebuilt (avatarStatus unchanged).
        expect(filteredBuilds, filteredAfterFirstFrame);

        unawaited(bloc.uploadAvatar());
        // Bloc stream delivery takes a microtask hop.
        await tester.pump();
        // Allow state emission to propagate to widgets.
        await tester.pump();
        expect(find.text('uploading'), findsOneWidget);
      },
    );

    testWidgets('MkFormBuilder untyped usage still receives MkFormState', (
      tester,
    ) async {
      final bloc = MkSimpleFormBloc(
        controls: {'name': MkFieldBloc<String>(initialValue: 'x')},
        onSubmit: (values) async => null,
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: MkFormScope.value(
            value: bloc,
            child: MkFormBuilder(
              buildWhen: (p, c) => p.isValid != c.isValid,
              builder: (context, state, formBloc) =>
                  Text('valid: ${state.isValid}'),
            ),
          ),
        ),
      );

      expect(find.text('valid: true'), findsOneWidget);
    });

    testWidgets(
      'MkFormStateBuilder throws a StateError when the state is not an S',
      (tester) async {
        final bloc = MkSimpleFormBloc(
          controls: {'name': MkFieldBloc<String>(initialValue: 'x')},
          onSubmit: (values) async => null,
        );
        addTearDown(bloc.close);

        await tester.pumpWidget(
          MaterialApp(
            home: MkFormScope.value(
              value: bloc,
              child: MkFormStateBuilder<MkFormState<ProfileExtra>>(
                builder: (context, state, formBloc) => const SizedBox(),
              ),
            ),
          ),
        );

        final error = tester.takeException();
        expect(error, isA<StateError>());
        expect(error.toString(), contains('MkFormState<ProfileExtra>'));
      },
    );
  });
}
