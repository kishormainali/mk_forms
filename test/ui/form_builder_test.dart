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
        var builds = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: MkFormScope.value(
              value: bloc,
              child: MkFormStateBuilder<ProfileState>(
                buildWhen: (previous, current) =>
                    previous.avatarStatus != current.avatarStatus,
                builder: (context, state, formBloc) {
                  builds++;
                  return Text(
                    state.avatarStatus.isSubmitting ? 'uploading' : 'idle',
                  );
                },
              ),
            ),
          ),
        );
        expect(find.text('idle'), findsOneWidget);
        final buildsAfterFirstFrame = builds;

        // Not part of buildWhen: must not rebuild.
        bloc.field<String>('name')!.changeValue('Ada');
        await tester.pump();
        expect(builds, buildsAfterFirstFrame);

        unawaited(bloc.uploadAvatar());
        await tester.pump();
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
              child: MkFormStateBuilder<ProfileState>(
                builder: (context, state, formBloc) => const SizedBox(),
              ),
            ),
          ),
        );

        final error = tester.takeException();
        expect(error, isA<StateError>());
        expect(error.toString(), contains('ProfileState'));
      },
    );
  });
}
