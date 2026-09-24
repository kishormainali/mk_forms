import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

class _TestFormBloc extends MkFormBloc {
  _TestFormBloc(Map<String, MkControlBloc<dynamic>> controls)
    : super(controls: controls);

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async => null;
}

void main() {
  group('Field-aware localization end-to-end', () {
    test(
      'a field registered directly in MkFormBloc.controls is auto-labeled',
      () async {
        final form = _TestFormBloc({
          'confirmPassword': MkFieldBloc<String>(
            validators: [MkValidators.required()],
          ),
        });

        final field = form.root.field<String>('confirmPassword')!;
        field.touch();

        expect(
          field.state.getLocalizedError(),
          'Confirm password is required.',
        );

        await form.close();
      },
    );

    test('an explicit label overrides auto-derivation inside a form', () async {
      final form = _TestFormBloc({
        'email': MkFieldBloc<String>(
          label: 'Work email address',
          validators: [MkValidators.required()],
        ),
      });

      final field = form.root.field<String>('email')!;
      field.touch();

      expect(
        field.state.getLocalizedError(),
        'Work email address is required.',
      );

      await form.close();
    });

    test(
      'a field never added to any group produces the pre-feature generic message',
      () async {
        // Regression pin: this is the exact assertion style already used by
        // test/core/localization_test.dart's "default English messages" case.
        final field = MkFieldBloc<String>(
          validators: [MkValidators.required(), MkValidators.email()],
        );

        expect(field.state.error, 'This field is required');
        expect(field.state.getLocalizedError(), 'This field is required');

        await field.close();
      },
    );

    test(
      'MkArrayBloc items are not auto-labeled (no per-item name to derive from)',
      () async {
        final array = MkArrayBloc<MkFieldBloc<String>>([
          MkFieldBloc<String>(validators: [MkValidators.required()]),
        ]);

        expect(array.controls.first.label, isNull);

        await array.close();
      },
    );

    test(
      'nested subform fields are labeled from their own group key, unprefixed',
      () async {
        final form = _TestFormBloc({
          'shipping': MkGroupBloc({
            'street': MkFieldBloc<String>(
              validators: [MkValidators.required()],
            ),
          }),
        });

        final shipping = form.root.group('shipping')!;
        final street = shipping.field<String>('street')!;
        street.touch();

        expect(street.state.getLocalizedError(), 'Street is required.');

        await form.close();
      },
    );
  });
}
