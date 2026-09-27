import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

class CustomFrenchMessages extends MkDefaultEnglishMessages {
  const CustomFrenchMessages();

  @override
  String required() => 'Ce champ est requis';

  @override
  String email() => 'Adresse e-mail invalide';
}

class FullyCustomMessages extends MkFormMessages {
  const FullyCustomMessages();

  @override
  String required() => 'CUSTOM: required';

  @override
  String email() => 'CUSTOM: email';

  @override
  String minLength(int min) => 'CUSTOM: minLength $min';

  @override
  String maxLength(int max) => 'CUSTOM: maxLength $max';

  @override
  String min(num min) => 'CUSTOM: min $min';

  @override
  String max(num max) => 'CUSTOM: max $max';

  @override
  String pattern() => 'CUSTOM: pattern';

  @override
  String match() => 'CUSTOM: match';
}

void main() {
  group('Internationalization & Localization', () {
    test('default English messages', () {
      final field = MkFieldBloc<String>(
        validators: [MkValidators.required(), MkValidators.email()],
      );

      expect(field.state.error, 'This field is required');
      expect(field.state.errorCode, MkErrorCodes.required);
      expect(field.state.getLocalizedError(), 'This field is required');
    });

    test('global per-app localization override', () {
      // Override globally for the whole app
      MkFormLocalizations.current = const MkSpanishMessages();

      final field = MkFieldBloc<String>(validators: [MkValidators.required()]);

      expect(field.state.error, 'Este campo es obligatorio');
      expect(field.state.getLocalizedError(), 'Este campo es obligatorio');

      // Reset back to English
      MkFormLocalizations.current = const MkDefaultEnglishMessages();
    });

    testWidgets(
      'scoped per-app localization override via MkLocalizationScope',
      (tester) async {
        final emailField = MkFieldBloc<String>(
          validators: [MkValidators.required()],
        );

        emailField.touch();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MkLocalizationScope(
                messages: const CustomFrenchMessages(),
                child: MkTextField(
                  fieldBloc: emailField,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              ),
            ),
          ),
        );

        // Scoped French message is rendered
        expect(find.text('Ce champ est requis'), findsOneWidget);
      },
    );

    testWidgets('dynamic language switching updates form errors at runtime', (
      tester,
    ) async {
      final field = MkFieldBloc<String>(validators: [MkValidators.required()]);
      field.touch();

      bool isSpanish = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: () => setState(() => isSpanish = !isSpanish),
                  child: const Icon(Icons.language),
                ),
                body: MkLocalizationScope(
                  messages: isSpanish
                      ? const MkSpanishMessages()
                      : const MkDefaultEnglishMessages(),
                  child: MkTextField(fieldBloc: field),
                ),
              ),
            );
          },
        ),
      );

      // English initially
      expect(find.text('This field is required'), findsOneWidget);
      expect(find.text('Este campo es obligatorio'), findsNothing);

      // Toggle to Spanish
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Instantly updates to Spanish without re-validating or clearing field
      expect(find.text('Este campo es obligatorio'), findsOneWidget);
      expect(find.text('This field is required'), findsNothing);
    });
  });

  group('Field-aware messages (MkFormMessages.resolveField)', () {
    const messages = MkDefaultEnglishMessages();

    test('required', () {
      expect(
        messages.resolveField(MkErrorCodes.required, 'Email'),
        'Email is required.',
      );
    });

    test('email', () {
      expect(
        messages.resolveField(MkErrorCodes.email, 'Email'),
        'Email must be a valid email address.',
      );
    });

    test('minLength', () {
      expect(
        messages.resolveField(MkErrorCodes.minLength, 'Password', {'min': 8}),
        'Password must be at least 8 characters.',
      );
    });

    test('maxLength', () {
      expect(
        messages.resolveField(MkErrorCodes.maxLength, 'Bio', {'max': 200}),
        'Bio must be at most 200 characters.',
      );
    });

    test('min', () {
      expect(
        messages.resolveField(MkErrorCodes.min, 'Age', {'min': 18}),
        'Age must be at least 18.',
      );
    });

    test('max', () {
      expect(
        messages.resolveField(MkErrorCodes.max, 'Quantity', {'max': 10}),
        'Quantity must be at most 10.',
      );
    });

    test('pattern', () {
      expect(
        messages.resolveField(MkErrorCodes.pattern, 'Zip code'),
        'Zip code has an invalid format.',
      );
    });

    test('match', () {
      expect(
        messages.resolveField(MkErrorCodes.match, 'Confirm password'),
        'Confirm password does not match.',
      );
    });

    test('unknown/unsupported error code returns null', () {
      expect(
        messages.resolveField(MkErrorCodes.asyncValidationFailed, 'Email'),
        isNull,
      );
      expect(messages.resolveField('someCustomCode', 'Email'), isNull);
    });
  });

  group('Field-aware messages (MkSpanishMessages)', () {
    const messages = MkSpanishMessages();

    test('required', () {
      expect(
        messages.resolveField(MkErrorCodes.required, 'Correo'),
        'Correo es obligatorio.',
      );
    });

    test('minLength', () {
      expect(
        messages.resolveField(MkErrorCodes.minLength, 'Contraseña', {'min': 8}),
        'Contraseña debe tener al menos 8 caracteres.',
      );
    });

    test('match', () {
      expect(
        messages.resolveField(MkErrorCodes.match, 'Confirmar contraseña'),
        'Confirmar contraseña no coincide.',
      );
    });
  });

  group('Field-aware resolution via MkFieldState.getLocalizedError', () {
    test('uses resolveField when a label is present', () {
      const state = MkFieldState<String>(
        value: null,
        initialValue: null,
        isDirty: false,
        isTouched: false,
        isValidating: false,
        isEnabled: true,
        isVisible: true,
        isReadOnly: false,
        wasFormSubmitted: false,
        error: 'This field is required',
        errorCode: MkErrorCodes.required,
        label: 'Email',
      );

      expect(state.getLocalizedError(), 'Email is required.');
    });

    test('falls back to resolve() when label is null', () {
      const state = MkFieldState<String>(
        value: null,
        initialValue: null,
        isDirty: false,
        isTouched: false,
        isValidating: false,
        isEnabled: true,
        isVisible: true,
        isReadOnly: false,
        wasFormSubmitted: false,
        error: 'This field is required',
        errorCode: MkErrorCodes.required,
      );

      expect(state.getLocalizedError(), 'This field is required');
    });

    test(
      'falls back to resolve() when errorCode has no field-aware template',
      () {
        const state = MkFieldState<String>(
          value: null,
          initialValue: null,
          isDirty: false,
          isTouched: false,
          isValidating: false,
          isEnabled: true,
          isVisible: true,
          isReadOnly: false,
          wasFormSubmitted: false,
          error: 'Could not verify this value. Please try again.',
          errorCode: MkErrorCodes.asyncValidationFailed,
          label: 'Email',
        );

        expect(
          state.getLocalizedError(),
          'Could not verify this value. Please try again.',
        );
      },
    );

    test('copyWith preserves label by default and can update it', () {
      const state = MkFieldState<String>(
        value: null,
        initialValue: null,
        isDirty: false,
        isTouched: false,
        isValidating: false,
        isEnabled: true,
        isVisible: true,
        isReadOnly: false,
        wasFormSubmitted: false,
        label: 'Email',
      );

      expect(state.copyWith(isTouched: true).label, 'Email');
      expect(state.copyWith(label: 'Work email').label, 'Work email');
    });
  });

  group(
    'Custom MkFormMessages implementations are never bypassed by field-aware resolution',
    () {
      test(
        'a fully custom MkFormMessages subclass keeps its own text even when the field has a label',
        () {
          MkFormLocalizations.current = const FullyCustomMessages();

          final field = MkFieldBloc<String>(
            label: 'Email',
            validators: [MkValidators.required()],
          );
          field.touch();

          expect(field.state.getLocalizedError(), 'CUSTOM: required');

          MkFormLocalizations.current = const MkDefaultEnglishMessages();
        },
      );

      test(
        'MkDefaultEnglishMessages still produces field-aware text by default',
        () {
          final field = MkFieldBloc<String>(
            label: 'Email',
            validators: [MkValidators.required()],
          );
          field.touch();

          expect(field.state.getLocalizedError(), 'Email is required.');
        },
      );
    },
  );
}
